import 'dart:io' show Platform, File; // Only if needed, otherwise remove or limit scope
import 'package:flutter/foundation.dart' show kIsWeb; // For platform checks if needed
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/components/fade_in_slide.dart';
import '../providers/food_provider.dart';
import '../../admin/providers/admin_provider.dart';
import '../../family_group/providers/group_provider.dart';
import '../../fridge/widgets/add_fridge_item_dialog.dart';

class FoodManagerScreen extends StatefulWidget {
  final dynamic groupId;
  final String? groupName;
  final bool autoRefresh; // Whether to subscribe to group changes

  const FoodManagerScreen({
    super.key,
    this.groupId,
    this.groupName,
    this.autoRefresh = false,
  });

  @override
  State<FoodManagerScreen> createState() => _FoodManagerScreenState();
}

class _FoodManagerScreenState extends State<FoodManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  dynamic _selectedCategoryId;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Initialize management group for local context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      
      // If a specific groupId was passed, use it, otherwise default to homeGroup
      final initialId = widget.groupId ?? groupProvider.homeGroup?['id'];
      if (initialId != null) {
        groupProvider.selectManagementGroup(initialId);
      }
      
      _loadData();
      
      // Listen for local group selection changes
      groupProvider.addListener(_groupListener);
    });
  }

  void _groupListener() {
    if (!mounted) return;
    
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final currentMgmtGroupId = groupProvider.managementGroup?['id'];
    
    // Check if the management group actually changed relative to what we might need to load
    // We can simply reload if notifyListeners was called and managementGroup is different from last fetch
    // But for simplicity, we trigger reload on managementGroup changes
    if (currentMgmtGroupId != null) {
      // Small optimization: only reload if it's actually different from what's in provider or we want to be reactive
      _loadData();
    }
  }

  @override
  void dispose() {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      groupProvider.removeListener(_groupListener);
    } catch (_) {}
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  dynamic _getEffectiveGroupId() {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    return groupProvider.managementGroup?['id'] ?? widget.groupId ?? groupProvider.homeGroup?['id'];
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<FoodProvider>(context, listen: false);
      final groupId = _getEffectiveGroupId();
      if (groupId == null) return;
      
      if (!provider.isLoading && provider.currentPage < provider.totalPages) {
        provider.fetchFoodsInGroup(
          groupId,
          page: provider.currentPage + 1,
          name: _searchController.text,
          categoryId: _selectedCategoryId,
        );
      }
    }
  }

  void _loadData() {
    Future.microtask(() {
      if (!mounted) return;
      
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      
      final effectiveGroupId = _getEffectiveGroupId();
      if (effectiveGroupId == null) return;

      foodProvider.fetchFoodsInGroup(effectiveGroupId);
      foodProvider.fetchCategories();
      foodProvider.fetchUnits();
      
      // Also fetch via admin provider for extra safety/redundancy
      adminProvider.fetchCategories();
      adminProvider.fetchUnits();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<FoodProvider>(
        builder: (context, provider, child) {
          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              
              // Search and Category Filters
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildSearchBar(provider),
                    _buildCategoryFilters(),
                  ],
                ),
              ),

              if (provider.isLoading && provider.foods.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (provider.foods.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return FadeInSlide(
                          delay: 0.1,
                          child: _buildFoodCard(provider.foods[index], provider),
                        );
                      },
                      childCount: provider.foods.length,
                    ),
                  ),
                ),
              
              if (provider.isLoading && provider.foods.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddEditDialog(context),
          borderRadius: BorderRadius.circular(20),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildSearchBar(FoodProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4)),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            final groupId = _getEffectiveGroupId();
            if (groupId != null) {
              provider.fetchFoodsInGroup(groupId, name: val, categoryId: _selectedCategoryId);
            }
          },
          decoration: InputDecoration(
            hintText: 'Tìm kiếm thực phẩm...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Consumer<FoodProvider>(
      builder: (context, foodProvider, child) {
        if (foodProvider.categories.isEmpty) return const SizedBox();
        
        return Container(
          height: 50,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: foodProvider.categories.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final category = isAll ? null : foodProvider.categories[index - 1];
              final categoryId = isAll ? null : category!['id'];
              final isSelected = _selectedCategoryId == categoryId;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(isAll ? 'Tất cả' : category!['name']),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategoryId = categoryId);
                      final gId = _getEffectiveGroupId();
                      if (gId != null) {
                        context.read<FoodProvider>().fetchFoodsInGroup(
                          gId,
                          name: _searchController.text,
                          categoryId: categoryId,
                        );
                      }
                    }
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.grey.shade100,
                  elevation: 0,
                  pressElevation: 0,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return Consumer2<FoodProvider, GroupProvider>(
      builder: (context, foodProvider, groupProvider, child) {
        final totalFoods = foodProvider.foods.length;
        final effectiveGroupName = groupProvider.managementGroup?['name'] ?? widget.groupName ?? 'Hệ thống';

        return SliverAppBar(
          expandedHeight: 220.0,
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
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
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                      ),
                    ),
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
                            'THỰC PHẨM',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 34,
                              letterSpacing: -1.5,
                              height: 1.1,
                              shadows: [
                                const Shadow(color: Colors.white, blurRadius: 15),
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
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(child: _buildHeaderStat('$totalFoods', 'Loại', AppColors.primary)),
                                      Container(width: 1, height: 16, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.symmetric(horizontal: 12)),
                                      Flexible(child: _buildGroupChip(groupProvider)),
                                    ],
                                  ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderStat(String count, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(count, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16, height: 1), overflow: TextOverflow.ellipsis, maxLines: 1),
        Text(label.toUpperCase(), style: TextStyle(color: AppColors.textPrimary.withOpacity(0.6), fontWeight: FontWeight.w800, fontSize: 8, letterSpacing: 0.5), overflow: TextOverflow.ellipsis, maxLines: 1),
      ],
    );
  }

  Widget _buildGroupChip(GroupProvider provider) {
    final groupName = provider.managementGroup?['name'] ?? 'Chọn nhóm';
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
            Flexible(
              child: Text(
                groupName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
          ],
        ),
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
                const Text('Chọn nhóm thực phẩm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...provider.groups.map((group) {
              final isSelected = group['id'].toString() == provider.managementGroup?['id']?.toString();
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
                  provider.selectManagementGroup(group['id']);
                },
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return FadeInSlide(
      delay: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 24, 4, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                      ),
                  ],
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
        ],
      ),
    );
  }

  Widget _buildFoodCard(Map food, FoodProvider provider) {
    String categoryName = food['Category']?['name'] ?? food['category']?['name'] ?? 'Chưa rõ';
    String unitName = food['Unit']?['name'] ?? food['unit']?['name'] ?? 'Đơn vị';
    String? imageUrl = food['image_url'] ?? food['imageUrl'];
    final accentColor = AppColors.primary;

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
                onTap: () => _showAddEditDialog(context, food: food),
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
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.restaurant_rounded,
                                    color: accentColor.withOpacity(0.35),
                                    size: 28,
                                  ),
                                )
                              : Icon(
                                  Icons.restaurant_rounded,
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
                              food['name'] ?? 'Không tên',
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
                                Flexible(child: _buildMiniBadge(categoryName, AppColors.info)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    unitName,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => AddFridgeItemDialog(initialFood: Map<String, dynamic>.from(food)),
                          );
                        },
                        icon: const Icon(Icons.add_box_rounded, color: AppColors.primary, size: 24),
                        tooltip: 'Thêm vào tủ lạnh',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: AppColors.error.withOpacity(0.6), size: 22),
                        onPressed: () => _showDeleteConfirmation(food, provider),
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.restaurant_rounded, size: 80, color: AppColors.primary.withOpacity(0.3)),
          ),
          const SizedBox(height: 24),
          const Text('Danh sách trống', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Chưa có loại thực phẩm nào.', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text, 
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {Map? food}) {
    final isEditing = food != null;
    final nameController = TextEditingController(text: food?['name']);
    String? selectedCategoryId = (food?['category_id'] ?? food?['category']?['id'] ?? food?['Category']?['id'])?.toString();
    String? selectedUnitId = (food?['unit_id'] ?? food?['unit']?['id'] ?? food?['Unit']?['id'])?.toString();
    XFile? selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final foodProvider = Provider.of<FoodProvider>(context);
          final adminProvider = Provider.of<AdminProvider>(context);
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            ),
            child: Column(
              children: [
                centerHandle(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(isEditing ? 'Cập nhật thực phẩm' : 'Thêm thực phẩm mới', 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                      const SizedBox(height: 24),
                      
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Tên thực phẩm',
                          hintText: 'ví dụ: Thịt bò, Bắp cải...',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 24),

                      imagePickerArea(food, selectedImage, (f) => setModalState(() => selectedImage = f)),
                      const SizedBox(height: 32),

                      _buildSectionTitle('Thông tin chi tiết'),
                      const SizedBox(height: 16),
                      
                      _buildDropdownField<String>(
                        label: 'Danh mục',
                        value: selectedCategoryId,
                        items: (foodProvider.categories.isNotEmpty ? foodProvider.categories : adminProvider.categories).map((c) => 
                          DropdownMenuItem<String>(
                            value: c['id']?.toString(), 
                            child: Text(c['name'] ?? 'Không tên')
                          )).toList(),
                        onChanged: (val) => setModalState(() => selectedCategoryId = val),
                        icon: Icons.category_rounded,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDropdownField<String>(
                        label: 'Đơn vị tính',
                        value: selectedUnitId,
                        items: (foodProvider.units.isNotEmpty ? foodProvider.units : adminProvider.units).map((u) => 
                          DropdownMenuItem<String>(
                            value: u['id']?.toString(), 
                            child: Text(u['name'] ?? 'Không tên')
                          )).toList(),
                        onChanged: (val) => setModalState(() => selectedUnitId = val),
                        icon: Icons.straighten_rounded,
                      ),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
                saveButton(isEditing, food, foodProvider, nameController, selectedCategoryId, selectedUnitId, selectedImage),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget centerHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        width: 40,
        height: 5,
        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget imagePickerArea(Map? food, XFile? selectedImage, Function(XFile) onPicked) {
    return Row(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
            image: selectedImage != null 
              ? DecorationImage(
                  image: kIsWeb 
                    ? NetworkImage(selectedImage.path) 
                    : FileImage(File(selectedImage.path)) as ImageProvider, 
                  fit: BoxFit.cover
                )
              : ((food?['image_url'] ?? food?['imageUrl']) != null 
                  ? DecorationImage(image: NetworkImage(food?['image_url'] ?? food?['imageUrl']), fit: BoxFit.cover) 
                  : null),
          ),
          child: (selectedImage == null && (food?['image_url'] ?? food?['imageUrl']) == null)
              ? const Icon(Icons.image_search_rounded, size: 40, color: Colors.orange)
              : null,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              _buildImageButton(
                onPressed: () => _pickImage(ImageSource.gallery, onPicked),
                icon: Icons.photo_library_rounded,
                label: 'Thư viện',
              ),
              const SizedBox(height: 12),
              _buildImageButton(
                onPressed: () => _pickImage(ImageSource.camera, onPicked),
                icon: Icons.camera_alt_rounded,
                label: 'Chụp ảnh',
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isSaving = false;

  Widget saveButton(bool isEditing, Map? food, FoodProvider provider, TextEditingController nameController, String? categoryId, String? unitId, XFile? image) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : () async {
            if (nameController.text.isEmpty) return;
            setState(() => _isSaving = true);
            final foodProvider = Provider.of<FoodProvider>(context, listen: false);
            // Default quantity to 1.0 as requested, or keep existing if editing
            final quantity = food?['quantity'] ?? 1.0;
            
            try {
              if (isEditing) {
                await foodProvider.updateFood(
                  id: food!['id'],
                  name: nameController.text.trim(),
                  categoryId: categoryId,
                  unitId: unitId,
                  quantity: quantity,
                  image: image,
                  groupId: _getEffectiveGroupId(),
                );
              } else {
                await foodProvider.createFood(
                  name: nameController.text.trim(),
                  categoryId: categoryId,
                  unitId: unitId,
                  quantity: 1.0, // Default to 1.0 for new foods
                  groupId: _getEffectiveGroupId(),
                  image: image,
                );
              }
              if (mounted) Navigator.pop(context);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent));
              }
            } finally {
              if (mounted) {
                setState(() => _isSaving = false);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 5,
            shadowColor: Colors.orange.withOpacity(0.4),
          ),
          child: _isSaving 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(isEditing ? 'Cập nhật ngay' : 'Thêm thực phẩm', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary));
  }

  Widget _buildImageButton({required VoidCallback onPressed, required IconData icon, required String label}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: const BorderSide(color: Colors.orange),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          decoration: InputDecoration(
            border: InputBorder.none,
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.orange, size: 20),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, Function(XFile) onPicked) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      onPicked(picked);
    }
  }

  void _showDeleteConfirmation(Map food, FoodProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa "${food['name']}"? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.deleteFood(food['id']);
                if (context.mounted) {
                  final gId = _getEffectiveGroupId();
                  if (gId != null) {
                    context.read<FoodProvider>().fetchFoodsInGroup(
                      gId,
                      name: _searchController.text,
                      categoryId: _selectedCategoryId,
                    );
                  }
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Xóa ngay'),
          ),
        ],
      ),
    );
  }
}
