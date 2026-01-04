import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../family_group/providers/group_provider.dart';
import '../../food/screens/food_manager_screen.dart';

class HomeMenuGrid extends StatelessWidget {
  const HomeMenuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.kitchen_rounded, 'label': 'Tủ lạnh', 'route': '/fridge', 'color': const Color(0xFF4FC3F7)},
      {'icon': Icons.shopping_cart_rounded, 'label': 'Đi chợ', 'route': '/shopping', 'color': const Color(0xFF66BB6A)},
      {'icon': Icons.restaurant_menu_rounded, 'label': 'Thực đơn', 'route': '/meal-plan', 'color': const Color(0xFFFFB74D)},
      {'icon': Icons.menu_book_rounded, 'label': 'Công thức', 'route': '/recipe', 'color': const Color(0xFFEF5350)},
      {'icon': Icons.people_alt_rounded, 'label': 'Gia đình', 'route': '/group', 'color': const Color(0xFFAB47BC)},
      {'icon': Icons.bar_chart_rounded, 'label': 'Thống kê', 'route': '/consumption', 'color': const Color(0xFF26A69A)},
      {'icon': Icons.fastfood_rounded, 'label': 'Thực phẩm', 'color': const Color(0xFFFFA726), 'isFood': true},
    ];


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.9,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return _MenuItemCard(
            icon: item['icon'] as IconData,
            label: item['label'] as String,
            route: item['route'] as String?,
            color: item['color'] as Color,
            isFood: item['isFood'] == true,
          );
        },
      ),
    );
  }
}

class _MenuItemCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? route;
  final Color color;
  final bool isFood;

  const _MenuItemCard({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
    this.isFood = false,
  });

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.isFood) {
      final groupProv = Provider.of<GroupProvider>(context, listen: false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoodManagerScreen(
            groupId: groupProv.homeGroup?['id'],
            groupName: groupProv.homeGroup?['name'],
            autoRefresh: true,
          ),
        ),
      );
    } else if (widget.route != null) {
      Navigator.pushNamed(context, widget.route!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              // Light shadow for depth
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              // Colored shadow for vibrancy
              BoxShadow(
                color: widget.color.withOpacity(0.12),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with gradient background
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      widget.color.withOpacity(0.15),
                      widget.color.withOpacity(0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: widget.color, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
