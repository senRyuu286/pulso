import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/providers/profile_providers.dart';
import '../../domain/models/profile.dart';
import '../widgets/profile_avatar.dart';

class ViewUserProfileScreen extends ConsumerWidget {
  const ViewUserProfileScreen({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryD : AppColors.textPrimaryL;
    final textSecondary =
        isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL;
    final primary = isDark ? AppColors.primaryD : AppColors.primaryL;
    final surfaceInset =
        isDark ? AppColors.surfaceInsetD : AppColors.surfaceInsetL;
    final surfaceRaised =
        isDark ? AppColors.surfaceRaisedD : AppColors.surfaceRaisedL;
    final shadowLight = isDark ? AppColors.shadowLightD : AppColors.shadowLightL;
    final shadowDark = isDark ? AppColors.shadowDarkD : AppColors.shadowDarkL;

    final profileAsync = ref.watch(fetchProfileProvider(userId));

    return Scaffold(
      body: SafeArea(
        child: profileAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: primary),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Unable to load profile.',
                  style: AppTextStyles.body.copyWith(color: primary),
                ),
                TextButton(
                  onPressed: () => ref.refresh(fetchProfileProvider(userId)),
                  child: Text(
                    'Retry',
                    style: AppTextStyles.label.copyWith(color: primary),
                  ),
                ),
              ],
            ),
          ),
          data: (profile) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        profile.username,
                        style: AppTextStyles.title.copyWith(color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ProfileAvatar(
                      avatarUrl: profile.avatarUrl,
                      size: 120,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.username,
                    style: AppTextStyles.headline.copyWith(color: textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  if (profile.bio != null)
                    Text(
                      profile.bio!,
                      style: AppTextStyles.body.copyWith(color: textSecondary),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                    ),
                  const SizedBox(height: 24),
                  _StatsRow(
                    profile: profile,
                    surfaceInset: surfaceInset,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    shadowLight: shadowLight,
                    shadowDark: shadowDark,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: surfaceRaised,
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
                    child: Text(
                      'Follow',
                      style: AppTextStyles.title.copyWith(color: primary),
                    ),
                  ),
                  // TODO: Implement follow/unfollow.
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.profile,
    required this.surfaceInset,
    required this.textPrimary,
    required this.textSecondary,
    required this.shadowLight,
    required this.shadowDark,
  });

  final Profile profile;
  final Color surfaceInset;
  final Color textPrimary;
  final Color textSecondary;
  final Color shadowLight;
  final Color shadowDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Posts',
            value: profile.postCount,
            surfaceInset: surfaceInset,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            shadowLight: shadowLight,
            shadowDark: shadowDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Followers',
            value: profile.followerCount,
            surfaceInset: surfaceInset,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            shadowLight: shadowLight,
            shadowDark: shadowDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Following',
            value: profile.followingCount,
            surfaceInset: surfaceInset,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            shadowLight: shadowLight,
            shadowDark: shadowDark,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.surfaceInset,
    required this.textPrimary,
    required this.textSecondary,
    required this.shadowLight,
    required this.shadowDark,
  });

  final String label;
  final int value;
  final Color surfaceInset;
  final Color textPrimary;
  final Color textSecondary;
  final Color shadowLight;
  final Color shadowDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceInset,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowDark,
            blurRadius: 10,
            offset: const Offset(6, 6),
          ),
          BoxShadow(
            color: shadowLight,
            blurRadius: 10,
            offset: const Offset(-6, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: AppTextStyles.title.copyWith(color: textPrimary),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }
}
