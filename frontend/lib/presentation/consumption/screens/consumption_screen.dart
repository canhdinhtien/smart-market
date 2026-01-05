import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/consumption_provider.dart';
import '../../family_group/providers/group_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/components/fade_in_slide.dart';

class ConsumptionScreen extends StatefulWidget {
  const ConsumptionScreen({super.key});

  @override
  State<ConsumptionScreen> createState() => _ConsumptionScreenState();
}

class _ConsumptionScreenState extends State<ConsumptionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;
  @override
  void initState() {
    super.initState();
    final isAdmin = context.read<AuthProvider>().isAdmin;
    _tabController = TabController(length: isAdmin ? 3 : 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
        _loadDataForTab(_tabController.index);
      }
    });

    // Initialize management group for local context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProv = context.read<GroupProvider>();
      
      // Default management group to current home group if not set
      if (groupProv.managementGroup == null && groupProv.homeGroup != null) {
        groupProv.selectManagementGroup(groupProv.homeGroup!['id']);
      }
      
      _loadDataForTab(0);
      
      // Listen for local group selection changes
      groupProv.addListener(_groupListener);
    });
  }

  void _groupListener() {
    if (!mounted) return;
    
    // If we are on the group tab (index 1), refresh data when management group changes
    if (_tabController.index == 1) {
      final groupProv = context.read<GroupProvider>();
      final groupId = groupProv.managementGroup?['id'];
      if (groupId != null) {
        context.read<ConsumptionProvider>().fetchGroupStats(groupId);
      }
    }
  }

  void _loadDataForTab(int index) {
    final consumptionProv = context.read<ConsumptionProvider>();
    final groupProv = context.read<GroupProvider>();
    
    if (index == 0) {
      // My Stats
      consumptionProv.fetchMyStats();
    } else if (index == 1) {
      // Group Stats - Use managementGroup for decoupled selection
      final groupId = groupProv.managementGroup?['id'] ?? groupProv.homeGroup?['id'];
      if (groupId != null) {
        consumptionProv.fetchGroupStats(groupId);
      }
    } else if (index == 2) {
      // All Stats (Admin)
      consumptionProv.fetchAllStats();
    }
  }

  @override
  void dispose() {
    try {
      context.read<GroupProvider>().removeListener(_groupListener);
    } catch (_) {}
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<ConsumptionProvider, GroupProvider>(
        builder: (context, consumptionProv, groupProv, child) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(consumptionProv, groupProv),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 240,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMyStatsTab(),
                      _buildGroupStatsTab(),
                      if (isAdmin) _buildAllStatsTab(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(ConsumptionProvider consumptionProv, GroupProvider groupProv) {
    final isAdmin = context.read<AuthProvider>().isAdmin;
    
    // Calculate total consumption items based on tab
    int totalItems = 0;
    if (_currentTab == 0) totalItems = consumptionProv.myStats.length;
    else if (_currentTab == 1) totalItems = consumptionProv.groupStats.length;
    else if (_currentTab == 2) totalItems = consumptionProv.allStats.length;

    final effectiveGroupName = groupProv.managementGroup?['name'] ?? 'Hệ thống';

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
                  bottom: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'THỐNG KÊ',
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
                              children: [
                                _buildHeaderStat('$totalItems', 'Mặt hàng', AppColors.primary),
                                if (_currentTab == 1) ...[
                                  Container(width: 1, height: 16, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.symmetric(horizontal: 12)),
                                  _buildGroupChip(groupProv),
                                ],
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
      bottom: TabBar(
        controller: _tabController,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 4, color: AppColors.primary),
          insets: const EdgeInsets.symmetric(horizontal: 40),
        ),
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: Colors.grey.shade400,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
        tabs: [
          const Tab(text: 'CỦA TÔI'),
          const Tab(text: 'NHÓM'),
          if (isAdmin) const Tab(text: 'TOÀN BỘ'),
        ],
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
    final groupName = provider.managementGroup?['name'] ?? 'Chọn nhóm';
    return GestureDetector(
      onTap: () => _showGroupPicker(context, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
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
                const Text('Chọn nhóm thống kê', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
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

  Widget _buildMyStatsTab() {
    return Consumer<ConsumptionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _buildErrorState(provider.error!);
        }

        if (provider.myStats.isEmpty) {
          return _buildEmptyState('Chưa có dữ liệu tiêu thụ cá nhân');
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchMyStats(),
          child: _buildStatsList(provider.myStats),
        );
      },
    );
  }

  Widget _buildGroupStatsTab() {
    return Consumer2<ConsumptionProvider, GroupProvider>(
      builder: (context, consumptionProv, groupProv, child) {
        final currentGroupId = groupProv.managementGroup?['id'] ?? groupProv.homeGroup?['id'];
        
        return Column(
          children: [
            // Stats Content
            Expanded(
              child: Builder(
                builder: (context) {
                  if (consumptionProv.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (consumptionProv.error != null) {
                    return _buildErrorState(consumptionProv.error!);
                  }

                  if (consumptionProv.groupStats.isEmpty) {
                    return _buildEmptyState('Chưa có dữ liệu tiêu thụ nhóm');
                  }

                  return RefreshIndicator(
                    onRefresh: () {
                      final groupId = currentGroupId;
                      return groupId != null
                          ? consumptionProv.fetchGroupStats(groupId)
                          : Future.value();
                    },
                    child: _buildStatsList(consumptionProv.groupStats),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAllStatsTab() {
    return Consumer<ConsumptionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _buildErrorState(provider.error!);
        }

        if (provider.allStats.isEmpty) {
          return _buildEmptyState('Chưa có dữ liệu tiêu thụ');
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchAllStats(),
          child: _buildStatsList(provider.allStats),
        );
      },
    );
  }

  Widget _buildStatsList(List<Map<String, dynamic>> stats) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final item = stats[index];
        return FadeInSlide(
          delay: 0.05 * index,
          child: _buildConsumptionCard(
            name: item['name'] ?? 'Unknown',
            unit: item['unit'] ?? '',
            quantity: (item['total_quantity'] ?? 0).toDouble(),
            rank: index + 1,
          ),
        );
      },
    );
  }

  Widget _buildConsumptionCard({
    required String name,
    required String unit,
    required double quantity,
    required int rank,
  }) {
    // Medal colors and accent colors
    Color? medalColor;
    IconData? medalIcon;
    Color accentColor = AppColors.primary;

    if (rank == 1) {
      medalColor = const Color(0xFFFFD700); // Gold
      medalIcon = Icons.emoji_events_rounded;
      accentColor = const Color(0xFFFFD700);
    } else if (rank == 2) {
      medalColor = const Color(0xFFC0C0C0); // Silver
      medalIcon = Icons.emoji_events_rounded;
      accentColor = const Color(0xFF9E9E9E);
    } else if (rank == 3) {
      medalColor = const Color(0xFFCD7F32); // Bronze
      medalIcon = Icons.emoji_events_rounded;
      accentColor = const Color(0xFF8D6E63);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: medalColor?.withOpacity(0.15) ?? AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: medalIcon != null
                          ? Icon(medalIcon, color: medalColor, size: 24)
                          : Text(
                              '#$rank',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Food info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
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
                            Icon(Icons.trending_up_rounded, size: 14, color: accentColor.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Tổng tiêu thụ',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Quantity
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        quantity.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: accentColor,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        unit,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadDataForTab(_currentTab),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
