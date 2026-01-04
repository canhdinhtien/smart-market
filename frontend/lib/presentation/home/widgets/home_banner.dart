
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../recipe/providers/recipe_provider.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Consumer<RecipeProvider>(
        builder: (context, recipeProvider, _) {
          if (recipeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = recipeProvider.recipes;

          if (recipes.isEmpty) {
            return PageView(
              controller: _pageController,
              padEnds: false,
              children: [
                _buildBannerItem(
                  context,
                  color: const Color(0xFFE3F2FD),
                  title: 'Chào mừng!',
                  subtitle: 'Khám phá các tính năng của ứng dụng ngay',
                  imageIcon: Icons.celebration,
                ),
                _buildBannerItem(
                  context,
                  color: const Color(0xFFFFF7E3),
                  title: 'Gợi ý',
                  subtitle: 'Hãy thêm công thức nấu ăn đầu tiên của bạn',
                  imageIcon: Icons.add_reaction_rounded,
                ),
              ],
            );
          }

          final displayItems = recipes.take(5).toList();

          return PageView.builder(
            controller: _pageController,
            padEnds: false,
            itemCount: displayItems.length,
            itemBuilder: (context, index) {
              final recipe = displayItems[index];
              
              final List<Color> bgColors = [
                const Color(0xFFFFF7E3), 
                const Color(0xFFE3F2FD), 
                const Color(0xFFE8F5E9)
              ];

              return _buildBannerItem(
                context,
                color: bgColors[index % bgColors.length],
                title: 'Gợi ý món ngon',
                subtitle: recipe.name,
                imageIcon: Icons.restaurant,
                imageUrl: null, 
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBannerItem(BuildContext context, {
    required Color color,
    required String title,
    required String subtitle,
    required IconData imageIcon,
    String? imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'HÔM NAY',
                          style: TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.w900, 
                            color: Colors.black.withOpacity(0.6),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, '/recipe'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.textPrimary,
                                AppColors.textPrimary.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.textPrimary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Nấu ngay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: imageUrl != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            imageIcon,
                            size: 70,
                            color: AppColors.textPrimary.withOpacity(0.6),
                          ),
                        ),
                      )
                    : Icon(
                        imageIcon,
                        size: 90,
                        color: AppColors.textPrimary.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
