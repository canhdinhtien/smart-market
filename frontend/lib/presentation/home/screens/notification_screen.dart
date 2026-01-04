import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/fade_in_slide.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.notifications.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => provider.markAllAsRead(),
                child: const Text('Đọc tất cả', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            physics: const BouncingScrollPhysics(),
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return FadeInSlide(
                delay: 0.1 + (index * 0.05),
                child: _buildNotificationCard(context, notification, provider),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notification, NotificationProvider provider) {
    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          provider.markAsRead(notification.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: notification.isRead 
              ? Border.all(color: Colors.grey.shade100)
              : Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: notification.isRead 
                  ? Colors.black.withOpacity(0.02)
                  : AppColors.primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: notification.isRead 
                    ? Colors.grey.shade50 
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForType(notification.type),
                color: notification.isRead ? Colors.grey : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead ? FontWeight.w700 : FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('HH:mm - dd/MM/yyyy').format(notification.timestamp),
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(Icons.notifications_off_rounded, size: 80, color: Colors.grey.shade200),
          ),
          const SizedBox(height: 24),
          const Text(
            'Không có thông báo mới',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn sẽ thấy thông báo ở đây khi có cập nhật.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'fridge':
        return Icons.kitchen_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'group':
        return Icons.groups_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }
}
