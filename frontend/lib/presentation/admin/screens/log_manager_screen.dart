import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/fade_in_slide.dart';
import '../providers/admin_provider.dart';
import 'package:intl/intl.dart';

class LogManagerScreen extends StatefulWidget {
  const LogManagerScreen({super.key});

  @override
  State<LogManagerScreen> createState() => _LogManagerScreenState();
}

class _LogManagerScreenState extends State<LogManagerScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  static const int _pageSize = 20;
  String _searchQuery = '';
  String _selectedFilter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchLogs(page: 1, limit: 100); // Fetch more for better initial stats
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    final provider = context.read<AdminProvider>();
    if (!provider.isLoading && (provider.logs?.length ?? 0) < provider.logsCount) {
      _currentPage++;
      await provider.fetchLogs(page: _currentPage, limit: _pageSize);
    }
  }

  List<dynamic> _getFilteredLogs(List<dynamic> logs) {
    return logs.where((log) {
      if (log == null || log is! Map) return false;
      
      final String action = (log['action']?.toString() ?? '').toLowerCase();
      final String details = (log['details']?.toString() ?? '').toLowerCase();
      
      // Robust User mapping
      String userName = '';
      final userData = log['User'];
      if (userData is Map) {
        userName = (userData['name']?.toString() ?? '').toLowerCase();
      } else if (userData != null) {
        userName = userData.toString().toLowerCase();
      }
      
      final String q = _searchQuery.toLowerCase();
      
      // 1. Filter by Search Query
      final matchesSearch = details.contains(q) || userName.contains(q);
      if (!matchesSearch) return false;

      // 2. Filter by Action Type
      if (_selectedFilter == 'Tất cả') return true;
      if (_selectedFilter == 'Tạo' && (action.contains('create') || action.contains('add'))) return true;
      if (_selectedFilter == 'Sửa' && (action.contains('update') || action.contains('edit'))) return true;
      if (_selectedFilter == 'Xóa' && (action.contains('delete') || action.contains('remove'))) return true;
      
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final stats = adminProvider.logStats;
    final filteredLogs = _getFilteredLogs(adminProvider.logs ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              title: const Text('Nhật ký hệ thống', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          
          // Activity Summary Chart
          SliverToBoxAdapter(
            child: _buildActivitySummary(stats),
          ),

          // Filters and Search
          SliverToBoxAdapter(
            child: _buildFilterSection(),
          ),

          if (adminProvider.isLoading && (adminProvider.logs?.isEmpty ?? true))
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredLogs.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final log = filteredLogs[index];
                    return FadeInSlide(
                      delay: 0.05 * index,
                      child: _buildLogCard(log),
                    );
                  },
                  childCount: filteredLogs.length,
                ),
              ),
            ),
          
          if (adminProvider.isLoading && (adminProvider.logs?.isNotEmpty ?? false))
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo nội dung hoặc người dùng...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tất cả'),
                const SizedBox(width: 8),
                _buildFilterChip('Tạo'),
                const SizedBox(width: 8),
                _buildFilterChip('Sửa'),
                const SizedBox(width: 8),
                _buildFilterChip('Xóa'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = label);
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
      ),
    );
  }

  Widget _buildActivitySummary(Map<String, int> stats) {
    final total = stats.values.fold(0, (a, b) => a + b);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Tổng quan hoạt động', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text('(Dựa trên dữ liệu đã tải)', 
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatMetric('Tạo', stats['create'] ?? 0, Colors.green, total),
              _buildStatMetric('Sửa', stats['update'] ?? 0, Colors.blue, total),
              _buildStatMetric('Xóa', stats['delete'] ?? 0, Colors.red, total),
              _buildStatMetric('Khác', stats['other'] ?? 0, Colors.grey, total),
            ],
          ),
          const SizedBox(height: 20),
          // Simple Bar Distribution
          Container(
            height: 10,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                if ((stats['create'] ?? 0) > 0) Expanded(flex: stats['create']!, child: Container(color: Colors.green)),
                if ((stats['update'] ?? 0) > 0) Expanded(flex: stats['update']!, child: Container(color: Colors.blue)),
                if ((stats['delete'] ?? 0) > 0) Expanded(flex: stats['delete']!, child: Container(color: Colors.red)),
                if ((stats['other'] ?? 0) > 0) Expanded(flex: stats['other']!, child: Container(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, int count, Color color, int total) {
    final percent = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Expanded(
      child: Column(
        children: [
          Text(count.toString(), 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, 
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          Text('$percent%', 
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildLogCard(dynamic logData) {
    if (logData is! Map) return const SizedBox.shrink();
    
    final Map<String, dynamic> log = Map<String, dynamic>.from(logData);
    final DateTime timestamp = DateTime.tryParse(log['timestamp']?.toString() ?? '') ?? DateTime.now();
    final String timeStr = DateFormat('HH:mm dd/MM').format(timestamp);
    final String action = log['action']?.toString() ?? 'N/A';
    final String details = log['details']?.toString() ?? '';
    
    String uName = 'Hệ thống';
    final userData = log['User'];
    if (userData is Map) {
      uName = userData['name']?.toString() ?? 'Hệ thống';
    } else if (userData != null) {
      uName = userData.toString();
    }

    final actionColor = _getActionColor(action);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    action.toUpperCase(),
                    style: TextStyle(color: actionColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(uName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              details, 
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActionColor(String action) {
    action = action.toLowerCase();
    if (action.contains('create') || action.contains('add')) return Colors.green;
    if (action.contains('update') || action.contains('edit')) return Colors.blue;
    if (action.contains('delete') || action.contains('remove')) return Colors.red;
    if (action.contains('login')) return Colors.orange;
    return Colors.grey;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty && _selectedFilter == 'Tất cả' 
                ? 'Chưa có hoạt động nào' 
                : 'Không tìm thấy hoạt động phù hợp',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
