import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/data/providers/auth_providers.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../domain/models/profile.dart';
import '../providers/profile_notifier.dart';
import '../widgets/avatar_crop_preview.dart';
import '../widgets/profile_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    ref.listen<AsyncValue<AuthUser?>>(authStateChangesProvider,
        (previous, next) {
      final user = next.asData?.value;
      if (user != null) {
        ref.read(profileProvider.notifier).loadProfile(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    final profileState = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceRaised =
        isDark ? AppColors.surfaceRaisedD : AppColors.surfaceRaisedL;
    final surfaceInset =
        isDark ? AppColors.surfaceInsetD : AppColors.surfaceInsetL;
    final textPrimary =
        isDark ? AppColors.textPrimaryD : AppColors.textPrimaryL;
    final textSecondary =
        isDark ? AppColors.textSecondaryD : AppColors.textSecondaryL;
    final primary = isDark ? AppColors.primaryD : AppColors.primaryL;
    final shadowLight = isDark ? AppColors.shadowLightD : AppColors.shadowLightL;
    final shadowDark = isDark ? AppColors.shadowDarkD : AppColors.shadowDarkL;

    final currentUserId = authState.asData?.value?.id;

    Widget body;
    if (profileState is ProfileLoading) {
      body = Center(
        child: CircularProgressIndicator(color: primary),
      );
    } else if (profileState is ProfileError) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              profileState.message,
              style: AppTextStyles.body.copyWith(color: primary),
            ),
            TextButton(
              onPressed: currentUserId == null
                  ? null
                  : () {
                        ref
                          .read(profileProvider.notifier)
                          .loadProfile(currentUserId);
                    },
              child: Text(
                'Retry',
                style: AppTextStyles.label.copyWith(color: primary),
              ),
            ),
          ],
        ),
      );
    } else if (profileState is ProfileLoaded ||
        profileState is ProfileUpdating) {
      final profile = profileState is ProfileLoaded
          ? profileState.profile
          : (profileState as ProfileUpdating).profile;

      body = _ProfileBody(
        profile: profile,
        isDark: isDark,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        surfaceInset: surfaceInset,
        surfaceRaised: surfaceRaised,
        shadowLight: shadowLight,
        shadowDark: shadowDark,
        primary: primary,
        onEditAvatar: currentUserId == null
            ? null
            : () => _pickAndUploadAvatar(context, currentUserId),
      );
    } else {
      body = const SizedBox.shrink();
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.9,
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context, String userId) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xFile == null) {
      return;
    }
    final bytes = await xFile.readAsBytes();
    if (!mounted) {
      return;
    }

    final sheetBg = (Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceD
            : AppColors.surfaceL)
        .withOpacity(0);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      builder: (context) {
        return AvatarCropPreview(
          imageBytes: bytes,
          onConfirm: () {
            Navigator.of(context).pop();
            final extension = xFile.name.split('.').last;
            ref.read(profileProvider.notifier).uploadAvatar(
                  userId: userId,
                  imageBytes: bytes,
                  fileExtension: extension,
                );
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.surfaceInset,
    required this.surfaceRaised,
    required this.shadowLight,
    required this.shadowDark,
    required this.primary,
    required this.onEditAvatar,
  });

  final Profile profile;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color surfaceInset;
  final Color surfaceRaised;
  final Color shadowLight;
  final Color shadowDark;
  final Color primary;
  final VoidCallback? onEditAvatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Center(
            child: GestureDetector(
              onTap: onEditAvatar,
              child: ProfileAvatar(
                avatarUrl: profile.avatarUrl,
                size: 120,
                showEditButton: onEditAvatar != null,
                onEditTap: onEditAvatar,
              ),
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
          GestureDetector(
            onTap: () => context.push('/profile/edit', extra: profile),
            child: Container(
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
                'Edit Profile',
                style: AppTextStyles.title.copyWith(color: primary),
              ),
            ),
          ),
        ],
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
