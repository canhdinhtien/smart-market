import 'package:flutter/material.dart';
import '../../fridge/providers/fridge_provider.dart';
import '../../family_group/providers/group_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';

class ExpiringItemsList extends StatelessWidget {
  const ExpiringItemsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FridgeProvider, GroupProvider>(
      builder: (context, fridgeProv, groupProv, _) {
        if (fridgeProv.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final items = fridgeProv.items.where((i) {
          try {
            final updatedAt = DateTime.parse(i['updated_at'].toString());
            final days = int.tryParse(i['use_within_days'].toString()) ?? 0;
            if (days == 0) return false;
            final expiry = updatedAt.add(Duration(days: days));
            return expiry.difference(DateTime.now()).inDays <= 3;
          } catch (_) {
            return false;
          }
        }).toList();

        if (items.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Cần dùng ngay ⏰',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
            ),
            _buildList(context, items),
          ],
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<dynamic> items) {
    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final food = item['Food'];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: food?['image_url'] != null
                      ? Image.network(
                          food['image_url'],
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(Icons.restaurant, size: 30, color: Colors.grey),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food?['name'] ?? 'Không tên',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cần dùng sớm',
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.green.shade50.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade100.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade600, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tất cả đều tươi ngon!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hiện tại không có thực phẩm nào sắp hết hạn trong 3 ngày tới.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
