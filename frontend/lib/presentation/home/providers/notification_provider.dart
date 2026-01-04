import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/services/notification_service.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;
  final String? type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.type,
  });
}

class NotificationProvider with ChangeNotifier {
  final ApiClient _apiClient;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  NotificationProvider(this._apiClient) {
    // Add some initial dummy notifications to show the user it works
    _notifications = [
      NotificationModel(
        id: '1',
        title: 'Chào mừng bạn!',
        body: 'Cảm ơn bạn đã tham gia Smart Market. Hãy bắt đầu quản lý tủ lạnh của mình nhé!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      NotificationModel(
        id: '2',
        title: 'Mẹo nhỏ',
        body: 'Bạn có thể nhấn vào biểu tượng Tủ lạnh trong thanh điều hướng để xem thực phẩm sắp hết hạn.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    // Listen to real-time notifications
    NotificationService().onMessage.listen((message) {
      if (message.notification != null) {
        addNotification(
          message.notification!.title ?? 'Thông báo mới',
          message.notification!.body ?? '',
          type: message.data['type']?.toString(),
        );
      }
    });
  }

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    // For now, we stay with dummy data since the backend doesn't have an endpoint yet
    // In the future, this will call ApiConstants.notifications
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void addNotification(String title, String body, {String? type}) {
    _notifications.insert(
      0,
      NotificationModel(
        id: DateTime.now().toString(),
        title: title,
        body: body,
        timestamp: DateTime.now(),
        type: type,
      ),
    );
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  void clearState() {
    _notifications.clear();
    _isLoading = false;
    notifyListeners();
  }
}
