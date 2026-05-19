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
      final data = await _client
          .from('profiles')
          .select(
              '*, posts(count), follows!follows_following_id_fkey(count), follows!follows_follower_id_fkey(count)')
          .eq('id', userId)
          .single();

      final postCount = _extractCount(data['posts']);
      final followerCount = _extractCount(_pickCountSource(data, [
        'follows!follows_following_id_fkey',
        'follows_following_id_fkey',
        'follows',
      ]));
      final followingCount = _extractCount(_pickCountSource(data, [
        'follows!follows_follower_id_fkey',
        'follows_follower_id_fkey',
        'follows',
      ]));

      return Profile.fromJson({
        ...data,
        'post_count': postCount,
        'follower_count': followerCount,
        'following_count': followingCount,
      });
    } on PostgrestException catch (error) {
      if (_isNotFound(error)) {
        throw const ProfileNotFoundException();
      }
      if (_isRelationshipError(error)) {
        final data = await _client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        if (data == null) {
          throw const ProfileNotFoundException();
        }
        return Profile.fromJson({
          ...data,
          'post_count': 0,
          'follower_count': 0,
          'following_count': 0,
        });
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
    String? username,
    String? bio,
  }) async {
    try {
      final data = await _client
          .from('profiles')
          .update({
            'username': username,
            'bio': bio,
            'updated_at': DateTime.now().toIso8601String(),
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

  int _extractCount(dynamic value) {
    if (value is List && value.isNotEmpty) {
      final first = value.first as Map<String, dynamic>;
      final count = first['count'];
      if (count is int) {
        return count;
      }
    }
    return 0;
  }

  dynamic _pickCountSource(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }
    return null;
  }

  bool _isNotFound(PostgrestException error) {
    return error.code == 'PGRST116';
  }

  bool _isRelationshipError(PostgrestException error) {
    final message = error.message.toLowerCase();
    return message.contains('relationship') || message.contains('foreign key');
  }
}
