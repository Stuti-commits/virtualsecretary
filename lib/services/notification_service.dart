import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _currentRoleTopic;
  String? _currentUserTopic;

  Future<void> initialize() async {
    if (kIsWeb) {
      await _messaging.requestPermission();
      return;
    }

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<void> syncSubscriptions(AppUser user) async {
    final nextRoleTopic = 'role_${user.role!.value}';
    final nextUserTopic = 'user_${user.uid}';

    if (_currentRoleTopic != null && _currentRoleTopic != nextRoleTopic) {
      await _messaging.unsubscribeFromTopic(_currentRoleTopic!);
    }
    if (_currentUserTopic != null && _currentUserTopic != nextUserTopic) {
      await _messaging.unsubscribeFromTopic(_currentUserTopic!);
    }

    await _messaging.subscribeToTopic(nextRoleTopic);
    await _messaging.subscribeToTopic(nextUserTopic);

    _currentRoleTopic = nextRoleTopic;
    _currentUserTopic = nextUserTopic;
  }

  Future<void> clearSubscriptions() async {
    if (_currentRoleTopic != null) {
      await _messaging.unsubscribeFromTopic(_currentRoleTopic!);
    }
    if (_currentUserTopic != null) {
      await _messaging.unsubscribeFromTopic(_currentUserTopic!);
    }
    _currentRoleTopic = null;
    _currentUserTopic = null;
  }
}
