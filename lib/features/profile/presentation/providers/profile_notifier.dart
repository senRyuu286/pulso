import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers/profile_providers.dart';
import '../../domain/models/profile.dart';
import '../../data/repositories/profile_repository_impl.dart';

part 'profile_notifier.g.dart';

sealed class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile);

  final Profile profile;
}

class ProfileUpdating extends ProfileState {
  const ProfileUpdating(this.profile);

  final Profile profile;
}

class ProfileError extends ProfileState {
  const ProfileError(this.message, this.lastKnownProfile);

  final String message;
  final Profile? lastKnownProfile;
}

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  ProfileState build() {
    return const ProfileInitial();
  }

  Future<void> loadProfile(String userId) async {
    state = const ProfileLoading();
    try {
      final profile = await ref.read(profileRepositoryProvider).fetchProfile(userId);
      state = ProfileLoaded(profile);
    } catch (error) {
      state = ProfileError(_messageFromError(error), _currentProfile());
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? bio,
  }) async {
    final currentProfile = _currentProfile();
    if (currentProfile != null) {
      state = ProfileUpdating(currentProfile);
    } else {
      state = const ProfileLoading();
    }
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(userId: userId, displayName: displayName, bio: bio);
      final refreshed =
          await ref.read(profileRepositoryProvider).fetchProfile(userId);
      state = ProfileLoaded(refreshed);
    } catch (error) {
      state = ProfileError(_messageFromError(error), currentProfile);
    }
  }

  Future<void> uploadAvatar({
    required String userId,
    required Uint8List imageBytes,
    required String fileExtension,
  }) async {
    final currentProfile = _currentProfile();
    if (currentProfile != null) {
      state = ProfileUpdating(currentProfile);
    } else {
      state = const ProfileLoading();
    }
    try {
      await ref.read(profileRepositoryProvider).uploadAvatar(
            userId: userId,
            imageBytes: imageBytes,
            fileExtension: fileExtension,
          );
      final refreshed =
          await ref.read(profileRepositoryProvider).fetchProfile(userId);
      state = ProfileLoaded(refreshed);
    } catch (error) {
      state = ProfileError(_messageFromError(error), currentProfile);
    }
  }

  Profile? _currentProfile() {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      return currentState.profile;
    }
    if (currentState is ProfileUpdating) {
      return currentState.profile;
    }
    if (currentState is ProfileError) {
      return currentState.lastKnownProfile;
    }
    return null;
  }

  String _messageFromError(Object error) {
    if (error is ProfileException) {
      if (error is ProfileNotFoundException) {
        return 'Profile not found.';
      }
      if (error is NetworkException) {
        return 'Network error. Please try again.';
      }
      if (error is ProfileUpdateException) {
        return error.message;
      }
      if (error is AvatarUploadException) {
        return error.message;
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
