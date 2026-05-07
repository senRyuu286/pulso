import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
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
  String? _localError;
  bool _didListen = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty || !email.contains('@')) {
      setState(() {
        _localError = 'Please enter a valid email and password.';
      });
      return;
    }
    setState(() {
      _localError = null;
    });
    ref.read(authNotifierProvider.notifier).signIn(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryD : AppColors.primaryL;

    if (!_didListen) {
      _didListen = true;
      ref.listen<AuthState>(authNotifierProvider, (previous, next) {
        if (next is AuthSuccess && mounted) {
          context.go(AppRoutes.feed);
        }
      });
    }

    final errorText = state is AuthError
        ? state.exception.message
        : _localError;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              Column(
                children: [
                  Icon(
                    Icons.monitor_heart_outlined,
                    size: 48,
                    color: primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pulso',
                    style: AppTextStyles.display.copyWith(
                      fontStyle: FontStyle.italic,
                      color: primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              AuthTextField(
                controller: emailController,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 8),
              if (errorText != null)
                Text(
                  errorText,
                  style: AppTextStyles.caption.copyWith(color: primary),
                )
              else
                const SizedBox.shrink(),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Sign In',
                onPressed: state is AuthLoading ? null : _signIn,
                isLoading: state is AuthLoading,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.go(AppRoutes.register);
                },
                child: Text(
                  'Don\'t have an account? Register',
                  style: AppTextStyles.label.copyWith(color: primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
