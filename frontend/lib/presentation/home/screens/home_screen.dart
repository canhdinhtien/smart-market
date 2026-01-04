import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/fade_in_slide.dart';
import '../../family_group/providers/group_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../fridge/providers/fridge_provider.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_banner.dart';
import '../widgets/home_menu_grid.dart';
import '../widgets/home_section_header.dart';
import '../widgets/expiring_items_list.dart';
import '../widgets/recipe_suggestions.dart';
import '../widgets/floating_glass_nav_bar.dart';
import '../../profile/providers/profile_provider.dart';
import '../../recipe/providers/recipe_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
    
    // Listen for home group changes to refresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProv = Provider.of<GroupProvider>(context, listen: false);
      groupProv.addListener(_onGroupChanged);
    });
  }

  void _onGroupChanged() {
    if (!mounted) return;
    _fetchFridgeItems();
  }

  @override
  void dispose() {
    try {
      Provider.of<GroupProvider>(context, listen: false).removeListener(_onGroupChanged);
    } catch (_) {}
    super.dispose();
  }

  void _initializeData() {
    Future.microtask(() {
      if (!mounted) return;
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      
      // Always fetch fresh data to avoid stale information from previous sessions or role changes
      profileProvider.fetchProfile();
      groupProvider.fetchGroups().then((_) {
        if (mounted) {
          _fetchFridgeItems();
        }
      });
    });
  }

  void _fetchFridgeItems() {
    if (!mounted) return;
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    if (groupProvider.homeGroup != null && mounted) {
      final groupId = groupProvider.homeGroup!['id'];
      Provider.of<FridgeProvider>(context, listen: false).fetchItems(groupId);
      Provider.of<RecipeProvider>(context, listen: false).fetchRecommendations(groupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      extendBody: true,
      body: Stack(
        children: [
          // 1. Background Decor
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.2,
            child: _buildBlurCircle(AppColors.primary.withOpacity(0.08), size.width * 0.8),
          ),
          Positioned(
            top: size.height * 0.3,
            left: -size.width * 0.3,
            child: _buildBlurCircle(AppColors.secondary.withOpacity(0.05), size.width * 0.7),
          ),
          Positioned(
            bottom: size.height * 0.1,
            right: -size.width * 0.2,
            child: _buildBlurCircle(AppColors.primary.withOpacity(0.04), size.width * 0.6),
          ),

          // 2. Nội dung chính
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async => _initializeData(),
              color: AppColors.primary,
              edgeOffset: 100,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AppBar
                    const FadeInSlide(delay: 0.1, child: HomeAppBar()),
                    
                    const SizedBox(height: 24),

                    // Banner
                    const FadeInSlide(delay: 0.2, child: HomeBanner()),
                    
                    const SizedBox(height: 32),

                    // Grid Menu
                    const FadeInSlide(delay: 0.3, child: HomeMenuGrid()),
                    
                    const SizedBox(height: 40),

                    // Section: Expiring
                    _buildSection(
                      title: 'Cần dùng ngay',
                      onSeeAll: () => Navigator.pushNamed(context, '/fridge'),
                      child: const ExpiringItemsList(),
                      delay: 0.4,
                    ),

                    const SizedBox(height: 40),

                    // Section: Recipes
                    _buildSection(
                      title: 'Gợi ý hôm nay',
                      onSeeAll: () => Navigator.pushNamed(context, '/recipe'),
                      child: const RecipeSuggestions(),
                      delay: 0.5,
                    ),

                    // Bottom Padding
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
          ),
          
          // 3. Floating Navigation Bar (Lơ lửng phía trên Stack)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeInSlide(
              delay: 0.6,
              direction: FadeInDirection.ttb, // Trượt từ dưới lên
              child: FloatingGlassNavBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() => _selectedIndex = index);
                  _handleNavigation(index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hỗ trợ build Section để code gọn hơn
  Widget _buildSection({
    required String title,
    required VoidCallback onSeeAll,
    required Widget child,
    required double delay,
  }) {
    return FadeInSlide(
      delay: delay,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: HomeSectionHeader(
              title: title,
              onSeeAll: onSeeAll,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  void _handleNavigation(int index) {
    // Không cần setState ở đây vì đã gọi ở onTap
    switch (index) {
      case 0:
        // Đang ở Home, có thể cuộn lên đầu trang
        break;
      case 1:
        Navigator.pushNamed(context, '/fridge');
        break;
      case 2:
        Navigator.pushNamed(context, '/shopping');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }
}