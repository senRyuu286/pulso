import 'dart:typed_data';

import '../models/profile.dart';

abstract class ProfileRepository {
  Future<Profile> fetchProfile(String userId);

  Future<Profile> updateProfile({
    required String userId,
    String? username,
    String? bio,
  });

  Future<String> uploadAvatar({
    required String userId,
    required Uint8List imageBytes,
    required String fileExtension,
  });

  Stream<Profile> watchProfile(String userId);
}
