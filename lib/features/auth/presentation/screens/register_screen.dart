import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/auth_notifier.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String? usernameError;
  String? displayNameError;
  String? emailError;
  String? passwordError;
  String? confirmError;

  bool get _isFormValid {
    return usernameController.text.trim().length >= 3 &&
      displayNameController.text.trim().isNotEmpty &&
      _isValidEmail(emailController.text) &&
        passwordController.text.length >= 6 &&
        confirmPasswordController.text == passwordController.text;
  }

  bool get _isUsernameValid {
    return usernameController.text.trim().length >= 3;
  }

  bool get _isDisplayNameValid {
    return displayNameController.text.trim().isNotEmpty;
  }

  bool get _isEmailValid {
    return _isValidEmail(emailController.text);
  }

  bool get _isPasswordValid {
    return passwordController.text.length >= 6;
  }

  bool get _isConfirmValid {
    return confirmPasswordController.text == passwordController.text &&
        confirmPasswordController.text.isNotEmpty;
  }

  bool _isValidEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) {
      return false;
    }
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  @override
  void initState() {
    super.initState();
    usernameController.addListener(() {
      setState(() {
        usernameError = null;
      });
    });
    displayNameController.addListener(() {
      setState(() {
        displayNameError = null;
      });
    });
    emailController.addListener(() {
      setState(() {
        emailError = null;
      });
    });
    passwordController.addListener(() {
      setState(() {
        passwordError = null;
        if (confirmPasswordController.text.isNotEmpty) {
          confirmError =
              confirmPasswordController.text != passwordController.text
                  ? 'Passwords do not match'
                  : null;
        }
      });
    });
    confirmPasswordController.addListener(() {
      setState(() {
        confirmError =
            confirmPasswordController.text != passwordController.text
                ? 'Passwords do not match'
                : null;
      });
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    displayNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateAndShowErrors() {
    setState(() {
      if (usernameController.text.trim().isEmpty) {
        usernameError = 'Username is required';
      } else if (usernameController.text.trim().length < 3) {
        usernameError = 'Username must be at least 3 characters';
      } else {
        usernameError = null;
      }

      if (displayNameController.text.trim().isEmpty) {
        displayNameError = 'Display name is required';
      } else {
        displayNameError = null;
      }

      if (emailController.text.trim().isEmpty) {
        emailError = 'Email address is required';
      } else if (!_isValidEmail(emailController.text)) {
        emailError = 'Enter a valid email address';
      } else {
        emailError = null;
      }

      if (passwordController.text.isEmpty) {
        passwordError = 'Password is required';
      } else if (passwordController.text.length < 6) {
        passwordError = 'Password must be at least 6 characters';
      } else {
        passwordError = null;
      }

      if (confirmPasswordController.text.isEmpty) {
        confirmError = 'Please confirm your password';
      } else if (confirmPasswordController.text != passwordController.text) {
        confirmError = 'Passwords do not match';
      } else {
        confirmError = null;
      }
    });
  }

  void _handleSignUp() {
    final isUsernameValid = _isUsernameValid;
    final isDisplayNameValid = _isDisplayNameValid;
    final isEmailValid = _isEmailValid;
    final isPasswordValid = _isPasswordValid;
    final isConfirmValid = _isConfirmValid;

    if (!isUsernameValid ||
      !isDisplayNameValid ||
        !isEmailValid ||
        !isPasswordValid ||
        !isConfirmValid) {
      setState(() {
        usernameError =
            isUsernameValid ? null : 'Username must be at least 3 characters.';
      displayNameError =
        isDisplayNameValid ? null : 'Display name is required.';
        emailError = isEmailValid ? null : 'Enter a valid email address.';
        passwordError =
            isPasswordValid ? null : 'Password must be at least 6 characters.';
        confirmError = isConfirmValid ? null : 'Passwords do not match';
      });
      return;
    }

    ref.read(authNotifierProvider.notifier).signUp(
          emailController.text.trim(),
          passwordController.text,
          usernameController.text.trim(),
          displayNameController.text.trim(),
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
    final logo = isDark
        ? Image.asset('assets/logo/logo-dark.png', width: 100)
        : Image.asset('assets/logo/logo-light.png', width: 100);

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
                  Center(child: logo),
                  const SizedBox(height: 10),
                  Text(
                    'Join Pulso',
                    style: AppTextStyles.headline.copyWith(
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create your account to get started',
                    style: AppTextStyles.body.copyWith(
                      color: textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Username',
                    style: AppTextStyles.label.copyWith(
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AuthTextField(
                    controller: usernameController,
                    hintText: '@username',
                    errorText: null,
                  ),
                  _buildFieldError(usernameError, primary),
                  const SizedBox(height: 14),
                  Text(
                    'Display name',
                    style: AppTextStyles.label.copyWith(
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AuthTextField(
                    controller: displayNameController,
                    hintText: 'Your name',
                    errorText: null,
                  ),
                  _buildFieldError(displayNameError, primary),
                  const SizedBox(height: 14),
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
                    'Choose a password',
                    style: AppTextStyles.label.copyWith(
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AuthTextField(
                    controller: passwordController,
                    hintText: 'min. 6 characters',
                    obscureText: true,
                    errorText: null,
                  ),
                  _buildFieldError(passwordError, primary),
                  const SizedBox(height: 14),
                  Text(
                    'Confirm password',
                    style: AppTextStyles.label.copyWith(
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AuthTextField(
                    controller: confirmPasswordController,
                    hintText: 'Re-enter your password',
                    obscureText: true,
                    errorText: null,
                  ),
                  _buildFieldError(confirmError, primary),
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
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: _isFormValid
                        ? null
                        : (_) => _validateAndShowErrors(),
                    onTap: _isFormValid ? null : _validateAndShowErrors,
                    child: IgnorePointer(
                      ignoring: !_isFormValid,
                      child: PrimaryButton(
                        label: 'Create Account ›',
                        onPressed: _isFormValid ? _handleSignUp : null,
                        isLoading: state is AuthLoading,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          'Already have an account?',
                          style: AppTextStyles.label.copyWith(color: primary),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          'Sign In',
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
