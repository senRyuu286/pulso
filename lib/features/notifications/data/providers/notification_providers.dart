import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/providers/auth_providers.dart';
import '../../domain/repositories/notification_repository.dart';
import '../repositories/notification_repository_impl.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(supabaseClientProvider));
});
