import 'dart:io';
import 'dart:math';
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
      final filePath = '$userId/${_generateUuidV4()}.jpg';

      await _client.storage.from('avatars').uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      // Public bucket: URLs are publicly readable.
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

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

}
