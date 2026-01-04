import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../family_group/providers/group_provider.dart';
import '../../fridge/providers/fridge_provider.dart';
import '../../recipe/providers/recipe_provider.dart';
import '../providers/notification_provider.dart';

class HomeAppBar extends StatefulWidget {
  const HomeAppBar({super.key});

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Group Selector
              Expanded(
                child: Consumer<GroupProvider>(
                  builder: (context, groupProvider, _) {
                    if (groupProvider.isLoading && groupProvider.groups.isEmpty) {
                      return const SizedBox(
                        height: 48,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Đang tải...', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      );
                    }

                    final currentGroupName = groupProvider.homeGroup != null 
                        ? groupProvider.homeGroup!['name'] 
                        : 'Chọn nhóm';

                    return GestureDetector(
                      onTap: () => _showGroupPicker(context, groupProvider),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.08),
                              AppColors.primary.withOpacity(0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Gia đình của',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          currentGroupName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textPrimary,
                                            letterSpacing: -0.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.primary),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Notifications
              Consumer<NotificationProvider>(
                builder: (context, provider, _) {
                  final unreadCount = provider.unreadCount;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildIconButton(
                        context,
                        icon: Icons.notifications_none_rounded,
                        onTap: () => Navigator.pushNamed(context, '/notification'),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
              // Shopping
              _buildIconButton(
                context,
                icon: Icons.shopping_bag_outlined,
                onTap: () => Navigator.pushNamed(context, '/shopping'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Enhanced Search Bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isSearchFocused 
                    ? AppColors.primary.withOpacity(0.5)
                    : Colors.grey.shade100,
                width: _isSearchFocused ? 2 : 1,
              ),
              boxShadow: _isSearchFocused
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm món ăn, rau củ...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _isSearchFocused ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupPicker(BuildContext context, GroupProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Chọn gia đình', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...provider.groups.map((group) {
              final isSelected = group['id'].toString() == provider.homeGroup?['id'].toString();
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.groups_rounded, 
                    color: isSelected ? Colors.white : Colors.grey,
                    size: 20,
                  ),
                ),
                title: Text(
                  group['name'].toString(),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                trailing: isSelected 
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) 
                    : null,
                onTap: () {
                  // Đóng bottom sheet ngay lập tức
                  Navigator.pop(context);
                  
                  // Sau đó cập nhật dữ liệu
                  provider.selectHomeGroup(group['id']);
                  
                  // Tải lại dữ liệu cho nhóm mới
                  try {
                    Provider.of<FridgeProvider>(context, listen: false).fetchItems(group['id']);
                    Provider.of<RecipeProvider>(context, listen: false).fetchRecommendations(group['id']);
                  } catch (e) {
                  }
                },
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.textPrimary, size: 24),
        onPressed: onTap,
        splashRadius: 24,
      ),
    );
  }
}
