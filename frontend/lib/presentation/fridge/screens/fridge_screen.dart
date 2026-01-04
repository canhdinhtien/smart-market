import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fridge_provider.dart';
import '../../family_group/providers/group_provider.dart';
import '../../food/providers/food_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/components/fade_in_slide.dart';
import 'package:intl/intl.dart';
import '../widgets/add_fridge_item_dialog.dart';
import '../../shopping/providers/shopping_provider.dart';

class _ExpiryInfo {
  final String label;
  final String dateText;
  final Color color;
  final IconData icon;
  final bool isUrgent;

  _ExpiryInfo({
    required this.label,
    required this.dateText,
    required this.color,
    required this.icon,
    required this.isUrgent,
  });
}

class FridgeScreen extends StatefulWidget {
  const FridgeScreen({super.key});

  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  String _sortBy = 'expiry'; // 'expiry', 'name', 'date_added'
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      _loadData(groupProvider.homeGroup?['id']);
      groupProvider.addListener(_onGroupChanged);
    });
  }

  void _onGroupChanged() {
    if (!mounted) return;
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    _loadData(groupProvider.homeGroup?['id']);
  }

  void _loadData(dynamic groupId) {
    if (groupId == null) return;
    final fridgeProv = Provider.of<FridgeProvider>(context, listen: false);
    final foodProv = Provider.of<FoodProvider>(context, listen: false);
    
    fridgeProv.fetchItems(groupId);
    foodProv.fetchFoodsInGroup(groupId);
    foodProv.fetchCategories();
    foodProv.fetchUnits();
  }

  @override
  void dispose() {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      groupProvider.removeListener(_onGroupChanged);
    } catch (_) {}
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: Consumer<FridgeProvider>(
        builder: (context, provider, child) {
          // Filter logic
          var filteredItems = provider.items.where((item) {
            final food = item['Food'] ?? {};
            final foodName = food['name'] ?? item['food_name'] ?? 'Không rõ';
            final nameMatch = foodName.toString().toLowerCase().contains(_searchQuery.toLowerCase());
            
            bool categoryMatch = true;
            if (_selectedCategoryId != null) {
              final catId = food['category_id'] ?? food['category']?['id'] ?? food['Category']?['id'];
              categoryMatch = catId?.toString() == _selectedCategoryId;
            }
            
            return nameMatch && categoryMatch;
          }).toList();

          // Sort logic
          filteredItems.sort((a, b) {
            int result = 0;
            if (_sortBy == 'expiry') {
              // Calculate expiry dates from updated_at + use_within_days
              DateTime? dateA;
              DateTime? dateB;
              
              try {
                final updatedAtA = a['updated_at'];
                final daysA = int.tryParse(a['use_within_days']?.toString() ?? '0') ?? 0;
                if (updatedAtA != null && daysA > 0) {
                  final parsedDate = DateTime.tryParse(updatedAtA.toString());
                  if (parsedDate != null) {
                    dateA = parsedDate.add(Duration(days: daysA));
                  }
                }
              } catch (_) {}
              
              try {
                final updatedAtB = b['updated_at'];
                final daysB = int.tryParse(b['use_within_days']?.toString() ?? '0') ?? 0;
                if (updatedAtB != null && daysB > 0) {
                  final parsedDate = DateTime.tryParse(updatedAtB.toString());
                  if (parsedDate != null) {
                    dateB = parsedDate.add(Duration(days: daysB));
                  }
                }
              } catch (_) {}
              
              final finalDateA = dateA ?? DateTime(2100);
              final finalDateB = dateB ?? DateTime(2100);
              result = finalDateA.compareTo(finalDateB);
            } else if (_sortBy == 'name') {
              final nameA = (a['Food']?['name'] ?? '').toString().toLowerCase();
              final nameB = (b['Food']?['name'] ?? '').toString().toLowerCase();
              result = nameA.compareTo(nameB);
            }
            return _sortAscending ? result : -result;
          });

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              
              // Search & Filter
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildCategoryFilters(),
                      _buildSortBar(),
                    ],
                  ),
                ),
              ),

              if (provider.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.orange)),
                )
              else if (filteredItems.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildFridgeItemCard(context, filteredItems[index], provider);
                      },
                      childCount: filteredItems.length,
                    ),
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

  Widget _buildCategoryFilters() {
    return Consumer<FoodProvider>(
      builder: (context, foodProvider, child) {
        if (foodProvider.categories.isEmpty) return const SizedBox();

        return Container(
          height: 40,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: foodProvider.categories.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final category = isAll ? null : foodProvider.categories[index - 1];
              final categoryId = isAll ? null : category!['id']?.toString();
              final isSelected = _selectedCategoryId == categoryId;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(isAll ? 'Tất cả' : category!['name']),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategoryId = categoryId);
                    }
                  },
                  selectedColor: Colors.orange,
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

  Widget _buildSortBar() {
    return Row(
      children: [
        Text(
          'Sắp xếp theo:',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        _buildSortChip('Hạn dùng', 'expiry'),
        const SizedBox(width: 8),
        _buildSortChip('Tên', 'name'),
        const Spacer(),
        IconButton(
          onPressed: () => setState(() => _sortAscending = !_sortAscending),
          icon: Icon(
            _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 18,
            color: Colors.orange,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.orange : Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.orange : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrangeAccent],
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
        onPressed: () => _showAddEditDialog(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Thêm đồ mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return Consumer2<FridgeProvider, GroupProvider>(
      builder: (context, fridgeProv, groupProv, _) {
        final totalItems = fridgeProv.items.length;
        return SliverAppBar(
          expandedHeight: 220.0,
          floating: false,
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
            centerTitle: false,
            titlePadding: EdgeInsets.zero,
            background: LayoutBuilder(
              builder: (context, constraints) {
                final double percentage = (constraints.maxHeight - kToolbarHeight) / (220.0 - kToolbarHeight);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Consistent Background to prevent loading flicker
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
                        ),
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4), // Darker top for status bar
                            Colors.transparent,
                            Colors.white.withOpacity(0.95), // Solid white at bottom
                            Colors.white,
                          ],
                          stops: const [0.0, 0.3, 0.8, 1.0],
                        ),
                      ),
                    ),
                    // Creative Content Layer
                    Positioned(
                      left: 24,
                      bottom: 50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'TỦ LẠNH',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 34,
                              letterSpacing: -1.5,
                              height: 1.1,
                              shadows: [
                                Shadow(
                                  color: Colors.white,
                                  blurRadius: 15,
                                  offset: const Offset(0, 0),
                                ),
                                Shadow(
                                  color: Colors.white.withOpacity(0.8),
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Floating Neo-Glass Status Bar
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
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    _buildHeaderStat('${totalItems}', 'Tất cả', AppColors.primary),
                                    Container(width: 1, height: 16, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.symmetric(horizontal: 12)),
                                    _buildHeaderStat('${fridgeProv.items.where((i) => _isExpiringSoon(i)).length}', 'Sắp hết hạn', Colors.orange),
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
      },
    );
  }

  bool _isExpiringSoon(Map<String, dynamic> item) {
    try {
      final updatedAt = DateTime.parse(item['updated_at'].toString());
      final days = int.tryParse(item['use_within_days'].toString()) ?? 0;
      if (days == 0) return false;
      final expiry = updatedAt.add(Duration(days: days));
      return expiry.difference(DateTime.now()).inDays <= 3;
    } catch (_) {
      return false;
    }
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


  _ExpiryInfo _getExpiryInfo(Map<String, dynamic> item) {
    try {
      final updatedAtStr = item['updated_at']?.toString();
      if (updatedAtStr == null) throw Exception('Missing updated_at');
      
      final updatedAt = DateTime.tryParse(updatedAtStr);
      if (updatedAt == null) throw Exception('Invalid date format');

      final days = int.tryParse(item['use_within_days']?.toString() ?? '0') ?? 0;
      final expiryDate = updatedAt.add(Duration(days: days));
      final now = DateTime.now();
      final difference = expiryDate.difference(now).inDays;
      final dateText = DateFormat('dd/MM').format(expiryDate);

      if (difference < 0) {
        return _ExpiryInfo(label: 'Hết hạn', dateText: dateText, color: Colors.black, icon: Icons.error_outline_rounded, isUrgent: true);
      } else if (difference == 0) {
        return _ExpiryInfo(label: 'Hết hôm nay', dateText: dateText, color: Colors.red.shade700, icon: Icons.warning_amber_rounded, isUrgent: true);
      } else if (difference <= 3) {
        return _ExpiryInfo(label: 'Còn $difference ngày', dateText: dateText, color: Colors.orange.shade800, icon: Icons.timer_outlined, isUrgent: true);
      } else {
        return _ExpiryInfo(label: 'Còn $difference ngày', dateText: dateText, color: AppColors.primary, icon: Icons.check_circle_outline_rounded, isUrgent: false);
      }
    } catch (_) {
      return _ExpiryInfo(label: 'N/A', dateText: '--/--', color: Colors.grey, icon: Icons.help_outline_rounded, isUrgent: false);
    }
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm thực phẩm...',
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.4),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(Icons.search_rounded, color: Color(0xFFFF5500), size: 24),
            ),
            suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5500).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFFFF5500)),
                ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupChip(GroupProvider provider) {
    final groupName = provider.homeGroup?['name'] ?? 'Chọn nhóm';
    return GestureDetector(
      onTap: () => _showGroupPicker(context, Offset.zero, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3), // Darker background for readability
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
                shadows: [
                  Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
              child: Icon(Icons.kitchen_outlined, size: 80, color: Colors.orange.shade200),
            ),
            const SizedBox(height: 24),
            const Text('Tủ lạnh trống trơn!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            const SizedBox(height: 8),
            Text(_searchQuery.isEmpty ? 'Hãy thêm thực phẩm để quản lý nhé.' : 'Không tìm thấy kết quả phù hợp.', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  Widget _buildFridgeItemCard(BuildContext context, Map<String, dynamic> item, FridgeProvider provider) {
    final food = item['Food'] ?? {};
    final foodName = food['name'] ?? 'Không rõ';
    final imageUrl = food['image_url'];

    // Calculate expiry date from updated_at + use_within_days
    DateTime? expiryDate;
    
    try {
      // Get updated_at date
      final updatedAtValue = item['updated_at'];
      final useWithinDays = item['use_within_days'];
      
      if (updatedAtValue != null && useWithinDays != null) {
        final updatedAt = DateTime.tryParse(updatedAtValue.toString());
        if (updatedAt == null) throw Exception('Invalid date format');
        
        final days = int.tryParse(useWithinDays.toString()) ?? 0;
        
        if (days > 0) {
          expiryDate = updatedAt.add(Duration(days: days));
          // print('Calculated expiry for $foodName: updated_at=$updatedAt + $days days = $expiryDate');
        } else {
          // print('⚠️ Invalid use_within_days for $foodName: $useWithinDays');
        }
      } else {
        // print('⚠️ Missing data for $foodName - updated_at: $updatedAtValue, use_within_days: $useWithinDays');
      }
    } catch (e) {
      // print('❌ Failed to calculate expiry for $foodName: $e');
    }

    final expiryInfo = _getExpiryInfo(item);
    // print('🎨 Color for $foodName: ${expiryInfo.color}, Label: ${expiryInfo.label}, Date: ${expiryInfo.dateText}');

    return FadeInSlide(
      duration: const Duration(milliseconds: 400),
      direction: FadeInDirection.btt,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          // Add subtle background tint based on urgency
          color: expiryInfo.isUrgent 
              ? expiryInfo.color.withOpacity(0.03)
              : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: expiryInfo.color.withOpacity(0.12),
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
            color: expiryInfo.color.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Expiry indicator bar - wider and more visible
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(
                  width: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        expiryInfo.color,
                        expiryInfo.color.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showAddEditDialog(context, item: item),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
                    child: Row(
                      children: [
                        // Visual Area
                        Stack(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Stack(
                                  children: [
                                    if (imageUrl == null)
                                      Center(
                                        child: Icon(
                                          _getFoodIcon(foodName),
                                          color: expiryInfo.color.withOpacity(0.5),
                                          size: 32,
                                        ),
                                      ),
                                    if (imageUrl != null)
                                      Image.network(
                                        imageUrl,
                                        width: 76,
                                        height: 76,
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
                                        errorBuilder: (context, error, stackTrace) => Center(
                                          child: Icon(
                                            _getFoodIcon(foodName),
                                            color: expiryInfo.color.withOpacity(0.5),
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (expiryInfo.isUrgent)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: expiryInfo.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Icon(
                                    expiryInfo.icon,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                foodName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: Color(0xFF1A1D1E),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Expiry date display
                              if (expiryDate != null && expiryInfo.dateText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 12,
                                        color: expiryInfo.color.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'HSD: ${expiryInfo.dateText}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: expiryInfo.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _buildModernBadge(
                                    '${item['quantity']} ${food['Unit']?['name'] ?? ""}', 
                                    const Color(0xFF007AFF),
                                    Icons.horizontal_rule_rounded,
                                  ),
                                  if (expiryDate != null)
                                    _buildModernBadge(
                                      expiryInfo.label, 
                                      expiryInfo.color,
                                      expiryInfo.icon,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Action Button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF8E8E93), size: 20),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showAddEditDialog(context, item: item);
                              } else if (value == 'delete') {
                                final groupProv = Provider.of<GroupProvider>(context, listen: false);
                                _confirmDelete(context, item['id'], groupProv.homeGroup?['id']);
                              } else if (value == 'shopping') {
                                _addToShoppingList(context, item);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'shopping',
                                child: Row(
                                  children: [
                                    Icon(Icons.add_shopping_cart_rounded, size: 18, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Mua thêm'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Chỉnh sửa'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Loại bỏ', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFoodIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('rau') || name.contains('củ')) return Icons.eco_rounded;
    if (name.contains('thịt') || name.contains('bò') || name.contains('heo')) return Icons.kebab_dining_rounded;
    if (name.contains('sữa') || name.contains('trứng')) return Icons.egg_rounded;
    if (name.contains('nước') || name.contains('bia')) return Icons.local_drink_rounded;
    return Icons.restaurant_rounded;
  }

  Widget _buildModernBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            text, 
            style: TextStyle(
              color: color, 
              fontSize: 12, 
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _addToShoppingList(BuildContext context, Map<String, dynamic> item) {
    final food = item['Food'] ?? {};
    final foodName = food['name'] ?? 'Thực phẩm';
    final groupProv = Provider.of<GroupProvider>(context, listen: false);
    final shoppingProv = Provider.of<ShoppingProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Thêm vào danh sách đi chợ', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn muốn thêm "$foodName" vào danh sách đi chợ của nhóm?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              try {
                // Find if there is an active shopping list for this group
                if (shoppingProv.shoppingLists.isEmpty) {
                  await shoppingProv.fetchShoppingLists(groupId: groupProv.homeGroup?['id']);
                }

                String? listId;
                if (shoppingProv.shoppingLists.isNotEmpty) {
                  listId = shoppingProv.shoppingLists.first['id'].toString();
                } else {
                  // If no list exists, create one
                  await shoppingProv.createShoppingList(
                    name: 'Danh sách đi chợ ${groupProv.homeGroup?['name'] ?? ""}',
                    groupId: groupProv.homeGroup?['id'],
                  );
                  listId = shoppingProv.shoppingLists.first['id'].toString();
                }

                await shoppingProv.addTask(listId, {
                  'name': foodName,
                  'quantity': 1,
                  'is_bought': false,
                  'notes': 'Thêm từ tủ lạnh (Sắp hết)',
                  'food_id': food['id'],
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã thêm vào danh sách đi chợ'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {Map<String, dynamic>? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFridgeItemDialog(item: item),
    );
  }

  void _pickFood(BuildContext context, Function(Map) onSelected) {
    final foodProv = Provider.of<FoodProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Thư Viện Thực Phẩm', 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1D1E), letterSpacing: -0.8),
            ),
            const SizedBox(height: 8),
            Text('Chọn một món để thêm vào tủ lạnh', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Expanded(
              child: foodProv.foods.isEmpty
                ? const Center(child: Text('Không có dữ liệu thực phẩm'))
                : ListView.builder(
                    itemCount: foodProv.foods.length,
                    itemBuilder: (context, index) {
                      final food = foodProv.foods[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          onTap: () {
                            onSelected(food);
                            Navigator.pop(context);
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              image: food['image_url'] != null ? DecorationImage(image: NetworkImage(food['image_url']), fit: BoxFit.cover) : null,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
                              ],
                            ),
                            child: food['image_url'] == null ? const Icon(Icons.fastfood_rounded, color: Color(0xFFFF5500), size: 24) : null,
                          ),
                          title: Text(food['name'] ?? 'Không tên', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1D1E))),
                          subtitle: Text(food['Category']?['name'] ?? 'Chưa rõ danh mục', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5500).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_rounded, color: Color(0xFFFF5500), size: 20),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600));
  }

  Widget _buildDialogTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.transparent),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1D1E)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: const Color(0xFFFF5500), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(BuildContext context, TextEditingController controller, String label, IconData icon, StateSetter setModalState) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          builder: (context, child) => Theme(
             data: Theme.of(context).copyWith(
               colorScheme: const ColorScheme.light(
                 primary: Color(0xFFFF5500), 
                 onPrimary: Colors.white, 
                 onSurface: Color(0xFF1A1D1E),
               ),
               textButtonTheme: TextButtonThemeData(
                 style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF5500)),
               ),
             ),
             child: child!,
          ),
        );
        if (date != null) {
          setModalState(() {
            controller.text = DateFormat('yyyy-MM-dd').format(date);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA), 
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF5500), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                controller.text.isEmpty ? label : controller.text, 
                style: TextStyle(
                  color: controller.text.isEmpty ? Colors.grey.shade500 : const Color(0xFF1A1D1E),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF8E8E93), size: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, dynamic id, dynamic groupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc muốn xóa thực phẩm này khỏi tủ lạnh?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<FridgeProvider>(context, listen: false).deleteItem(id, groupId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xóa ngay'),
          ),
        ],
      ),
    );
  }

  void _showGroupPicker(BuildContext context, Offset position, GroupProvider provider) {
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
                    color: isSelected ? Colors.orange : Colors.grey.shade100,
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
                    color: isSelected ? Colors.orange : AppColors.textPrimary,
                  ),
                ),
                trailing: isSelected 
                    ? const Icon(Icons.check_circle_rounded, color: Colors.orange) 
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  provider.selectHomeGroup(group['id']);
                },
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
