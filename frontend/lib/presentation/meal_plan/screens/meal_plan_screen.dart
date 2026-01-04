import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/meal_provider.dart';
import '../../family_group/providers/group_provider.dart';
import '../../recipe/providers/recipe_provider.dart';
import '../../food/providers/food_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/fade_in_slide.dart';
import '../../../../core/components/primary_button.dart';
import '../../../../core/components/custom_text_field.dart';
import '../../../../data/models/meal_plan_model.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenStateV2();
}

class _MealPlanScreenStateV2 extends State<MealPlanScreen> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _dateScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMeals();
    // Auto-scroll to center today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToDate(7); // Index 7 is today (since we start 7 days ago)
    });
  }

  void _scrollToDate(int index) {
    if (!_dateScrollController.hasClients) return;
    
    // Each date item is 65 or 80 wide + 16 total margin (8 each side)
    // We'll use a simplified middle approach
    const double itemWidth = 81.0; // 65 + 16
    final double screenWidth = MediaQuery.of(context).size.width;
    final double targetOffset = (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    
    _dateScrollController.animateTo(
      targetOffset.clamp(0.0, _dateScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  void _fetchMeals() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProv = Provider.of<GroupProvider>(context, listen: false);
      final groupId = groupProv.homeGroup?['id'];
      if (groupId != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
        Provider.of<MealProvider>(context, listen: false).fetchMealPlan(
          groupId: groupId,
          startDate: dateStr,
          endDate: dateStr,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: Consumer2<MealProvider, GroupProvider>(
        builder: (context, provider, groupProv, child) {
          final groupedPlans = {
            'sang': provider.plans.where((p) => p.mealType == 'sang').toList(),
            'trua': provider.plans.where((p) => p.mealType == 'trua').toList(),
            'toi': provider.plans.where((p) => p.mealType == 'toi').toList(),
          };

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(groupProv, provider),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: _buildDateSelector(),
                ),
              ),

              if (provider.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (provider.error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(provider.error!, style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildMealSection('Bữa Sáng ☀️', 'sang', groupedPlans['sang']!),
                      _buildMealSection('Bữa Trưa 🌤️', 'trua', groupedPlans['trua']!),
                      _buildMealSection('Bữa Tối 🌙', 'toi', groupedPlans['toi']!),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildSliverAppBar(GroupProvider groupProv, MealProvider mealProv) {
    final totalMeals = mealProv.plans.length;
    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
          onPressed: () => _showDatePicker(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: LayoutBuilder(
          builder: (context, constraints) {
            final double percentage = (constraints.maxHeight - kToolbarHeight) / (220.0 - kToolbarHeight);
            return Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    ),
                  ),
                ),
                // Positioned.fill(
                //   top: -40 * (1 - percentage),
                //   child: Image.network(
                //     'https://images.unsplash.com/photo-1498837167922-ddd27525d352?q=80&w=1200&auto=format&fit=crop',
                //     fit: BoxFit.cover,
                //     frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                //       if (wasSynchronouslyLoaded) return child;
                //       return AnimatedOpacity(
                //         opacity: frame == null ? 0 : 1,
                //         duration: const Duration(milliseconds: 800),
                //         curve: Curves.easeOut,
                //         child: child,
                //       );
                //     },
                //     errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                //   ),
                // ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                        Colors.white.withOpacity(0.95),
                        Colors.white,
                      ],
                      stops: const [0.0, 0.3, 0.8, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  bottom: 50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'THỰC ĐƠN',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 34,
                          letterSpacing: -1.5,
                          height: 1.1,
                          shadows: [
                            Shadow(color: Colors.white, blurRadius: 15),
                            Shadow(color: Colors.white.withOpacity(0.8), blurRadius: 30),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ColorFilter.mode(Colors.white.withOpacity(0.4), BlendMode.srcOver),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.2),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                            ),
                            child: Row(
                              children: [
                                _buildHeaderStat('${totalMeals}', 'Món ăn', Colors.green.shade700),
                                Container(width: 1, height: 16, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.symmetric(horizontal: 12)),
                                _buildHeaderStat(DateFormat('dd/MM').format(_selectedDate), 'Ngày', AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 24,
                  bottom: 128,
                  child: _buildGroupChip(groupProv),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String count, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(count, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16, height: 1)),
        Text(label.toUpperCase(), style: TextStyle(color: AppColors.textPrimary.withOpacity(0.6), fontWeight: FontWeight.w800, fontSize: 8, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildGroupChip(GroupProvider provider) {
    final groupName = provider.homeGroup?['name'] ?? 'Chọn nhóm';
    return GestureDetector(
      onTap: () => _showGroupPicker(context, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              groupName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _addMealDialog(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Thêm thực đơn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: 30, // Show 30 days
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(const Duration(days: 7)).add(Duration(days: index));
          final isToday = DateFormat('yyyy/MM/dd').format(date) == DateFormat('yyyy/MM/dd').format(DateTime.now());
          final isSelected = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(_selectedDate);
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _fetchMeals();
              _scrollToDate(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: isSelected ? 80 : 68,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade100,
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isToday && !isSelected)
                    Positioned(
                      top: 8,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(date).toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d').format(date),
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontSize: isSelected ? 24 : 19,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealSection(String title, String type, List<MealPlan> plans) {
    return FadeInSlide(
      delay: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 24, 4, 16),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (plans.isEmpty)
            _buildEmptyState()
          else
            ...plans.map((plan) => _buildMealCard(plan)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu_rounded, color: Colors.grey.shade200, size: 40),
          const SizedBox(height: 12),
          Text(
            'Chưa có món nào được lên kế hoạch',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(MealPlan plan) {
    final title = plan.recipe?.name ?? plan.food?['name'] ?? 'Món ăn không tên';
    final sub = plan.recipe != null ? 'Công thức nấu ăn' : 'Thực phẩm thông thường';
    
    final String? imageUrl = plan.recipe?.imageUrl ?? 
                             plan.food?['image_url'] ?? 
                             plan.food?['imageUrl'] ??
                             plan.food?['image'];

    Color accentColor;
    switch (plan.mealType) {
      case 'sang': accentColor = const Color(0xFFFFB800); break;
      case 'trua': accentColor = const Color(0xFFFF6B00); break;
      case 'toi': accentColor = const Color(0xFF6366F1); break;
      default: accentColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: accentColor.withOpacity(0.12),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accentColor, accentColor.withOpacity(0.5)],
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Maybe show details
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: imageUrl != null
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                    if (wasSynchronouslyLoaded) return child;
                                    return AnimatedOpacity(
                                      opacity: frame == null ? 0 : 1,
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.easeOut,
                                      child: child,
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    plan.recipe != null ? Icons.restaurant_rounded : Icons.fastfood_rounded,
                                    color: accentColor.withOpacity(0.35),
                                    size: 28,
                                  ),
                                )
                              : Icon(
                                  plan.recipe != null ? Icons.restaurant_rounded : Icons.fastfood_rounded,
                                  color: accentColor.withOpacity(0.35),
                                  size: 28,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                color: Color(0xFF1A1D1E),
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  plan.recipe != null ? Icons.menu_book_rounded : Icons.shopping_basket_rounded,
                                  size: 14,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    sub,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 22),
                        onPressed: () => _confirmDelete(plan),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, onSurface: AppColors.textPrimary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchMeals();
    }
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
              final isSelected = group['id'].toString() == provider.homeGroup?['id']?.toString();
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
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () {
                  Navigator.pop(context);
                  provider.selectHomeGroup(group['id']);
                  _fetchMeals(); // Refresh data for the selected group
                },
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(MealPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const Text('Xóa món ăn?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
        content: Text(
          'Anh/chị chắc chắn muốn bỏ món "${plan.recipe?.name ?? plan.food?['name']}" khỏi kế hoạch chứ?',
          style: TextStyle(color: Colors.grey.shade600, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (plan.id != null) {
                final success = await Provider.of<MealProvider>(context, listen: false).deleteMealPlan(plan.id!);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('✅ Đã xóa món ăn khỏi thực đơn'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Xóa món', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _addMealDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMealSheet(
        selectedDate: _selectedDate,
        onAdded: _fetchMeals,
      ),
    );
  }
}

class _AddMealSheet extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onAdded;

  const _AddMealSheet({required this.selectedDate, required this.onAdded});

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  String _mealType = 'sang';
  dynamic _selectedItem; // Recipe or Food
  bool _isRecipe = true;
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProv = Provider.of<GroupProvider>(context, listen: false);
      final groupId = groupProv.homeGroup?['id'];
      if (groupId != null) {
        Provider.of<RecipeProvider>(context, listen: false).fetchRecipes(groupId: groupId);
        Provider.of<FoodProvider>(context, listen: false).fetchFoodsInGroup(groupId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FadeInSlide(
                    delay: 0.4,
                    child: Text(
                      'Thêm vào kế hoạch',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const FadeInSlide(
                    delay: 0.5,
                    child: Text(
                      'BỮA ĂN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInSlide(
                    delay: 0.6,
                    child: _buildTypeSelector(),
                  ),
                  
                  const SizedBox(height: 32),
                  FadeInSlide(
                    delay: 0.7,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          _buildChoiceTab('Công thức', _isRecipe, () => setState(() { _isRecipe = true; _selectedItem = null; })),
                          _buildChoiceTab('Thực phẩm', !_isRecipe, () => setState(() { _isRecipe = false; _selectedItem = null; })),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  FadeInSlide(
                    delay: 0.8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => _onSearch(val),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: _isRecipe ? 'Tìm kiếm công thức nấu ăn...' : 'Tìm kiếm thực phẩm...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: FadeInSlide(
                      delay: 0.9,
                      child: _buildSearchableList(),
                    ),
                  ),
                  
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 100), // Spacing for fab/button
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: (_selectedItem == null || _isSubmitting)
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                boxShadow: (_selectedItem == null || _isSubmitting)
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: (_selectedItem == null || _isSubmitting) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_selectedItem == null || _isSubmitting) ? Colors.grey.shade200 : Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.grey.shade200,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: Text(
                  _isSubmitting ? 'ĐANG LƯU...' : 'LƯU VÀO KẾ HOẠCH',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceTab(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
            ] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.textPrimary : Colors.grey.shade500,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        _buildTypeItem('Sáng', 'sang', Icons.wb_sunny_rounded, const Color(0xFFFFB800)),
        const SizedBox(width: 12),
        _buildTypeItem('Trưa', 'trua', Icons.light_mode_rounded, const Color(0xFFFF6B00)),
        const SizedBox(width: 12),
        _buildTypeItem('Tối', 'toi', Icons.nightlight_round, const Color(0xFF6366F1)),
      ],
    );
  }

  Widget _buildTypeItem(String label, String type, IconData icon, Color color) {
    final isSelected = _mealType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mealType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade100,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey.shade400, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade500,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchableList() {
    if (_isRecipe) {
      return Consumer<RecipeProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator());
          if (prov.recipes.isEmpty) return _buildEmptyResults('Không tìm thấy công thức nào');
          
          return ListView.builder(
            itemCount: prov.recipes.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final r = prov.recipes[index];
              final isSelected = _selectedItem == r;
              return _buildItemCard(
                title: r.name,
                subtitle: r.description ?? 'Công thức nấu ăn',
                imageUrl: r.imageUrl,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedItem = r),
              );
            },
          );
        },
      );
    } else {
      return Consumer<FoodProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator());
          if (prov.foods.isEmpty) return _buildEmptyResults('Không tìm thấy thực phẩm nào');
          
          return ListView.builder(
            itemCount: prov.foods.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final f = prov.foods[index];
              final isSelected = _selectedItem == f;
              return _buildItemCard(
                title: f['name'],
                subtitle: f['Category']?['name'] ?? 'Nguyên liệu',
                imageUrl: f['image_url'] ?? f['imageUrl'],
                isSelected: isSelected,
                onTap: () => setState(() => _selectedItem = f),
              );
            },
          );
        },
      );
    }
  }

  Widget _buildEmptyResults(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildItemCard({
    required String title,
    required String subtitle,
    String? imageUrl,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            image: imageUrl != null 
              ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
              : null,
          ),
          child: imageUrl == null 
            ? Icon(Icons.fastfood_rounded, color: Colors.grey.shade400, size: 24)
            : null,
        ),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.w800, 
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        trailing: isSelected 
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
            )
          : null,
      ),
    );
  }

  void _onSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _selectedItem = null;
      });
      final groupProv = Provider.of<GroupProvider>(context, listen: false);
      final groupId = groupProv.homeGroup?['id'];
      if (groupId == null) return;
      
      if (_isRecipe) {
        Provider.of<RecipeProvider>(context, listen: false).fetchRecipes(groupId: groupId, name: query);
      } else {
        Provider.of<FoodProvider>(context, listen: false).fetchFoodsInGroup(groupId, name: query);
      }
    });
  }

  void _submit() async {
    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });
    
    final groupProv = Provider.of<GroupProvider>(context, listen: false);
    final mealProv = Provider.of<MealProvider>(context, listen: false);
    final groupId = groupProv.homeGroup?['id'];
    
    if (groupId == null) {
      setState(() {
        _errorMessage = 'Không tìm thấy nhóm gia đình';
        _isSubmitting = false;
      });
      return;
    }

    final data = {
      'meal_type': _mealType,
      'date': DateFormat('yyyy-MM-dd').format(widget.selectedDate),
      'group_id': groupId,
    };

    if (_isRecipe) {
      data['recipe_id'] = _selectedItem.id;
    } else {
      data['food_id'] = _selectedItem['id'];
    }

    final success = await mealProv.createMealPlan(data);
    
    if (!mounted) return;
    
    setState(() => _isSubmitting = false);
    
    if (success) {
      widget.onAdded();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã thêm vào kế hoạch'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          margin: EdgeInsets.all(20),
        ),
      );
    } else {
      setState(() {
        _errorMessage = mealProv.createError ?? 'Không thể tạo kế hoạch. Vui lòng thử lại.';
      });
    }
  }
}
