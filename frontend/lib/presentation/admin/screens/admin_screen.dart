import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/fade_in_slide.dart';
import '../../auth/providers/auth_provider.dart';
import '../../food/screens/food_manager_screen.dart';
import '../../food/screens/category_manager_screen.dart';
import '../../food/screens/unit_manager_screen.dart';
import 'user_manager_screen.dart';
import 'log_manager_screen.dart';

import '../providers/admin_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AdminProvider>().initializeDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final adminProvider = context.watch<AdminProvider>();
    
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Truy cập bị từ chối')),
        body: const Center(
          child: Text('Bạn không có quyền truy cập vào khu vực này.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: () => adminProvider.initializeDashboard(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Premium Gradient Header
            SliverToBoxAdapter(
              child: _buildHeader(context, auth),
            ),
            
            // System Overview Stats
            SliverToBoxAdapter(
              child: _buildSystemOverview(adminProvider),
            ),

            // Management Tools Title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  'Công cụ quản trị',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
              ),
            ),

            // 2x2 Grid of Management Modules
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildListDelegate([
                  _buildAdminCard(
                    context,
                    title: 'Danh mục',
                    subtitle: 'Phân loại thực phẩm',
                    icon: Icons.category_rounded,
                    color: Colors.blue,
                    delay: 0.5,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CategoryManagerScreen(groupName: 'Hệ thống')),
                    ),
                  ),
                  _buildAdminCard(
                    context,
                    title: 'Đơn vị tính',
                    subtitle: 'QL Đơn vị đo lường',
                    icon: Icons.straighten_rounded,
                    color: Colors.green,
                    delay: 0.6,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UnitManagerScreen(groupName: 'Hệ thống')),
                    ),
                  ),
                  _buildAdminCard(
                    context,
                    title: 'Người dùng',
                    subtitle: 'QL Tài khoản & Quyền',
                    icon: Icons.people_rounded,
                    color: Colors.purple,
                    delay: 0.7,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserManagerScreen()),
                    ),
                  ),
                  _buildAdminCard(
                    context,
                    title: 'Lịch sử',
                    subtitle: 'Nhật ký hoạt động',
                    icon: Icons.history_rounded,
                    color: Colors.orange,
                    delay: 0.8,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LogManagerScreen()),
                    ),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 30, left: 24, right: 24),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Color(0x33FFAB00), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'SYSTEM ADMIN',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () => auth.logout(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Hệ Thống Quản Trị',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          Text(
            'Smart Market Ecosystem',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemOverview(AdminProvider admin) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan hệ thống',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          // 4 stats in a 2x2 grid to avoid overflow and horizontal scrolling
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.15,
            children: [
              _buildStatItem('Người dùng', (admin.usersCount > 0 ? admin.usersCount - 1 : 0).toString(), Icons.person_rounded, Colors.blue),
              _buildStatItem('Danh mục', admin.categoriesCount.toString(), Icons.grid_view_rounded, Colors.green),
              _buildStatItem('Đơn vị', admin.unitsCount.toString(), Icons.scale_rounded, Colors.purple),
              _buildStatItem('Hoạt động', admin.logsCount.toString(), Icons.history_rounded, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value, 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label, 
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double delay,
    required VoidCallback onTap,
  }) {
    return FadeInSlide(
      delay: delay,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title, 
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle, 
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
