import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/profile.dart';
import '../../domain/repositories/profile_repository.dart';

sealed class ProfileException implements Exception {
  const ProfileException();
}

class ProfileNotFoundException extends ProfileException {
  const ProfileNotFoundException();
}

class ProfileUpdateException extends ProfileException {
  const ProfileUpdateException(this.message);

  final String message;
}

class AvatarUploadException extends ProfileException {
  const AvatarUploadException(this.message);

  final String message;
}

class NetworkException extends ProfileException {
  const NetworkException();
}

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Profile> fetchProfile(String userId) async {
    try {
      final profileData = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profileData == null) {
        throw const ProfileNotFoundException();
      }

      final posts = await _client
          .from('posts')
          .select('id')
          .eq('user_id', userId);
      final followers = await _client
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId);
      final following = await _client
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);

      final postCount = (posts as List).length;
      final followerCount = (followers as List).length;
      final followingCount = (following as List).length;

      return Profile.fromJson({
        ...profileData,
        'post_count': postCount,
        'follower_count': followerCount,
        'following_count': followingCount,
      });
    } on PostgrestException catch (error) {
      if (_isNotFound(error)) {
        throw const ProfileNotFoundException();
      }
      throw ProfileUpdateException(error.message);
    } on SocketException {
      throw const NetworkException();
    } on ProfileException {
      rethrow;
    } catch (_) {
      throw const ProfileNotFoundException();
    }
  }

  @override
  Future<Profile> updateProfile({
    required String userId,
    String? displayName,
    String? bio,
  }) async {
    try {
      final data = await _client
          .from('profiles')
          .update({
            'display_name': displayName,
            'bio': bio,
          })
          .eq('id', userId)
          .select()
          .single();

      return Profile.fromJson(data);
    } on SocketException {
      throw const NetworkException();
    } on ProfileException {
      rethrow;
    } catch (error) {
      throw ProfileUpdateException(error.toString());
    }
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List imageBytes,
    required String fileExtension,
  }) async {
    try {
      final filePath =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await _client.storage.from('avatars').uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$fileExtension',
            ),
          );

      final publicUrl = _client.storage.from('avatars').getPublicUrl(filePath);

      await _client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);

      return publicUrl;
    } on SocketException {
      throw const NetworkException();
    } on ProfileException {
      rethrow;
    } catch (error) {
      throw AvatarUploadException(error.toString());
    }
  }

  @override
  Stream<Profile> watchProfile(String userId) {
    try {
      return _client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', userId)
          .map((rows) {
        if (rows.isEmpty) {
          throw const ProfileNotFoundException();
        }
        return Profile.fromJson(rows.first);
      });
    } on ProfileException {
      rethrow;
    } catch (_) {
      throw const NetworkException();
    }
  }


  bool _isNotFound(PostgrestException error) {
    return error.code == 'PGRST116';
  }

}
