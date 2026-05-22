import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/auth_notifier.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? emailError;
  String? passwordError;

  bool get _isFormValid {
    return emailController.text.trim().isNotEmpty &&
        emailController.text.contains('@') &&
        passwordController.text.length >= 6;
  }

  bool get _isEmailValid {
    return emailController.text.trim().isNotEmpty &&
        emailController.text.contains('@');
  }

  bool get _isPasswordValid {
    return passwordController.text.length >= 6;
  }

  @override
  void initState() {
    super.initState();
    emailController.addListener(_handleInputChanged);
    passwordController.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    setState(() {
      if (_isEmailValid) {
        emailError = null;
      }
      if (_isPasswordValid) {
        passwordError = null;
      }
    });
  }

  void _handleSignIn() {
    final isEmailValid = _isEmailValid;
    final isPasswordValid = _isPasswordValid;

    if (!isEmailValid || !isPasswordValid) {
      setState(() {
        emailError = isEmailValid ? null : 'Enter a valid email address.';
        passwordError =
            isPasswordValid ? null : 'Password must be at least 6 characters.';
      });
      return;
    }

    ref.read(authNotifierProvider.notifier).signIn(
          emailController.text.trim(),
          passwordController.text,
        );
  }

  Widget _buildFieldError(String? text, Color color) {
    return Visibility(
      visible: text != null,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          text ?? '',
          style: AppTextStyles.caption.copyWith(color: color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceD : AppColors.surfaceL;
    final textPrimary =
        isDark ? AppColors.textPrimaryD : AppColors.textPrimaryL;
    final textSecondary =
        isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL;
    final primary = isDark ? AppColors.primaryD : AppColors.primaryL;
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthSuccess) {
        context.go('/feed');
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/welcome');
        }
      },
      child: Scaffold(
        backgroundColor: surface,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Pulso',
                      style: AppTextStyles.headline.copyWith(color: primary, fontSize: 42),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Welcome back',
                    style: AppTextStyles.headline.copyWith(
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to your account',
                    style: AppTextStyles.body.copyWith(
                      color: textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your email address',
                    style: AppTextStyles.label.copyWith(
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AuthTextField(
                    controller: emailController,
                    hintText: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    errorText: null,
                  ),
                  _buildFieldError(emailError, primary),
                  const SizedBox(height: 14),
                  Text(
                    'Password',
                    style: AppTextStyles.label.copyWith(
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AuthTextField(
                    controller: passwordController,
                    hintText: 'Enter your password',
                    obscureText: true,
                    errorText: null,
                  ),
                  _buildFieldError(passwordError, primary),
                  const SizedBox(height: 6),
                  if (state is AuthError)
                    Text(
                      state.exception.message,
                      style: AppTextStyles.caption.copyWith(
                        color: primary,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Continue ›',
                    onPressed: _isFormValid ? _handleSignIn : null,
                    isLoading: state is AuthLoading,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(
                          'Don\'t have an account?',
                          style: AppTextStyles.label.copyWith(color: primary),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(
                          'Register',
                          style: AppTextStyles.label.copyWith(color: primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
