import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/data/providers/auth_providers.dart';
import '../../domain/models/profile.dart';
import '../providers/profile_notifier.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.initialProfile,
  });

  final Profile initialProfile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController usernameController;
  late final TextEditingController displayNameController;
  late final TextEditingController bioController;

  @override
  void initState() {
    super.initState();
    usernameController =
      TextEditingController(text: '@${widget.initialProfile.username}');
    displayNameController =
      TextEditingController(text: widget.initialProfile.displayName ?? '');
    bioController = TextEditingController(text: widget.initialProfile.bio ?? '');
    bioController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    displayNameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryD : AppColors.textPrimaryL;
    final textSecondary =
        isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL;
    final textPlaceholder =
        isDark ? AppColors.textPlaceholderD : AppColors.textPlaceholderL;
    final primary = isDark ? AppColors.primaryD : AppColors.primaryL;
    final shadowLight = isDark ? AppColors.shadowLightD : AppColors.shadowLightL;
    final shadowDark = isDark ? AppColors.shadowDarkD : AppColors.shadowDarkL;

    ref.listen<ProfileState>(profileProvider, (previous, next) {
      if (next is ProfileLoaded) {
        context.pop();
      } else if (next is ProfileError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
          ),
        );
      }
    });

    final isUpdating = ref.watch(profileProvider) is ProfileUpdating;
    final isSaveEnabled = _isSaveEnabled();
    final authUser = ref.watch(authStateChangesProvider).asData?.value;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Profile',
                    style: AppTextStyles.headline.copyWith(color: textPrimary),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.label.copyWith(color: primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Username',
                style: AppTextStyles.label.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 8),
              _ProfileTextField(
                controller: usernameController,
                hintText: '@username',
                textColor: textPrimary,
                placeholderColor: textPlaceholder,
                shadowLight: shadowLight,
                shadowDark: shadowDark,
                isDark: isDark,
                readOnly: true,
              ),
              const SizedBox(height: 20),
              Text(
                'Display Name',
                style: AppTextStyles.label.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 8),
              _ProfileTextField(
                controller: displayNameController,
                hintText: 'Your name',
                textColor: textPrimary,
                placeholderColor: textPlaceholder,
                shadowLight: shadowLight,
                shadowDark: shadowDark,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              Text(
                'Bio',
                style: AppTextStyles.label.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 8),
              _ProfileTextField(
                controller: bioController,
                hintText: 'Tell the community about yourself...',
                textColor: textPrimary,
                placeholderColor: textPlaceholder,
                shadowLight: shadowLight,
                shadowDark: shadowDark,
                isDark: isDark,
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${bioController.text.length}/150',
                  style:
                      AppTextStyles.timestamp.copyWith(color: textPlaceholder),
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: !isSaveEnabled || authUser == null
                    ? null
                    : () => _handleSave(authUser.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: isSaveEnabled ? 1 : 0.6),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: shadowLight,
                        blurRadius: 14,
                        offset: const Offset(-6, -6),
                      ),
                      BoxShadow(
                        color: shadowDark,
                        blurRadius: 14,
                        offset: const Offset(6, 6),
                      ),
                    ],
                  ),
                  child: isUpdating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark
                                ? AppColors.onSecondaryD
                                : AppColors.onSecondaryL,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: AppTextStyles.label.copyWith(
                            color: isDark
                                ? AppColors.onSecondaryD
                                : AppColors.onSecondaryL,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSaveEnabled() {
    final trimmedDisplayName = displayNameController.text.trim();
    final trimmedBio = bioController.text.trim();
    final initialDisplayName = widget.initialProfile.displayName ?? '';
    final initialBio = widget.initialProfile.bio ?? '';
    return trimmedDisplayName != initialDisplayName || trimmedBio != initialBio;
  }

  void _handleSave(String userId) {
    final displayName = displayNameController.text.trim();
    ref.read(profileProvider.notifier).updateProfile(
          userId: userId,
          displayName: displayName.isEmpty ? null : displayName,
          bio: bioController.text.trim(),
        );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.hintText,
    required this.textColor,
    required this.placeholderColor,
    required this.shadowLight,
    required this.shadowDark,
    required this.isDark,
    this.readOnly = false,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final Color textColor;
  final Color placeholderColor;
  final Color shadowLight;
  final Color shadowDark;
  final bool isDark;
  final bool readOnly;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final insetColor = isDark ? AppColors.surfaceInsetD : AppColors.surfaceInsetL;
    return Container(
      decoration: BoxDecoration(
        color: insetColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowDark,
            blurRadius: 12,
            offset: const Offset(6, 6),
          ),
          BoxShadow(
            color: shadowLight,
            blurRadius: 12,
            offset: const Offset(-6, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        style: AppTextStyles.body.copyWith(color: textColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.body.copyWith(color: placeholderColor),
          border: InputBorder.none,
          isCollapsed: true,
        ),
      ),
    );
  }
}
