import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/components/fade_in_slide.dart';
import 'package:provider/provider.dart';
import '../../family_group/providers/group_provider.dart';
import '../providers/shopping_provider.dart';
import 'shopping_detail_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  @override
  void initState() {
    super.initState();
    _fetchLists();
    
    // Listen for group changes to refresh lists automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<GroupProvider>(context, listen: false).addListener(_onGroupChanged);
      }
    });
  }

  // Listener for group changes
  void _onGroupChanged() {
    if (mounted) _fetchLists();
  }

  void _fetchLists() {
    Future.microtask(() {
      if (!mounted) return;
      final shoppingProv = Provider.of<ShoppingProvider>(context, listen: false);
      final groupProv = Provider.of<GroupProvider>(context, listen: false);
      final groupId = groupProv.homeGroup?['id'];
      
      if (groupId != null) {
        shoppingProv.fetchShoppingLists(groupId: groupId);
      } else {
        shoppingProv.clearState();
      }
    });
  }

  @override
  void dispose() {
    // Safe removal of listener
    try {
      Provider.of<GroupProvider>(context, listen: false).removeListener(_onGroupChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<ShoppingProvider, GroupProvider>(
        builder: (context, provider, groupProv, child) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, groupProv),
              
              if (provider.isLoading && provider.shoppingLists.isEmpty)
                SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (provider.error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red.shade300, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'Lỗi khi tải dữ liệu:\n${provider.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _fetchLists,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text('Thử lại'),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              else if (groupProv.homeGroup == null)
                SliverFillRemaining(child: _buildNoGroupState())
              else if (provider.shoppingLists.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final list = provider.shoppingLists[index];
                        return FadeInSlide(
                          delay: index * 0.1,
                          child: _buildShoppingListCard(context, list),
                        );
                      },
                      childCount: provider.shoppingLists.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, GroupProvider groupProv) {
    final shoppingProv = context.watch<ShoppingProvider>();
    final totalLists = shoppingProv.shoppingLists.length;
    final totalTasks = shoppingProv.shoppingLists.fold<int>(0, (sum, list) {
      final tasks = (list['shopping_list_tasks'] as List?) ?? [];
      return sum + tasks.length;
    });

    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
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
                    Colors.black.withOpacity(0.2),
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
                    'ĐI CHỢ',
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
                            _buildHeaderStat('${totalLists}', 'Danh sách', const Color(0xFFFF4500)),
                            Container(width: 1, height: 16, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.symmetric(horizontal: 12)),
                            _buildHeaderStat('${totalTasks}', 'Mặt hàng', Colors.blue.shade700),
                            Container(width: 1, height: 16, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.symmetric(horizontal: 12)),
                            _buildGroupChip(groupProv),
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
                Text('Chọn gia đình', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                trailing: isSelected 
                    ? Icon(Icons.check_circle_rounded, color: AppColors.primary) 
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  provider.selectHomeGroup(group['id']);
                  Provider.of<ShoppingProvider>(context, listen: false).fetchShoppingLists(groupId: group['id']);
                },
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }


  Widget _buildNoGroupState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_work_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Vui lòng chọn gia đình', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_basket_outlined, size: 80, color: AppColors.primary.withOpacity(0.3)),
            ),
            const SizedBox(height: 24),
            Text('Danh sách trống', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text('Hãy lên kế hoạch mua sắm cho gia đình nhé.', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildShoppingListCard(BuildContext context, Map<String, dynamic> list) {
    final rawTasks = (list['shopping_list_tasks'] as List?) ?? 
                    (list['ShoppingListTasks'] as List?) ?? 
                    (list['tasks'] as List?) ?? [];
    int taskCount = rawTasks.where((t) => t['deleted_at'] == null).length;
    int completedCount = rawTasks.where((t) => t['deleted_at'] == null && t['is_purchased'] == true).length;
    double progress = taskCount == 0 ? 0 : completedCount / taskCount;

    final groupName = list['group']?['name'] ?? list['Group']?['name'] ?? 'N/A';
    final dateStr = list['date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(list['date'])) : 'Không đặt ngày';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
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
          color: AppColors.primary.withOpacity(0.12),
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
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.5)],
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShoppingDetailScreen(listId: list['id'], listName: list['name']),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 20, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Icon(Icons.assignment_rounded, color: AppColors.primary.withOpacity(0.8), size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  list['name'] ?? 'Không tên',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1A1D1E), letterSpacing: -0.5),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade400),
                                    const SizedBox(width: 6),
                                    Text(dateStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildListMenu(context, list),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildInfoTag(Icons.people_rounded, groupName, Colors.blue),
                              const SizedBox(width: 12),
                              _buildInfoTag(Icons.shopping_bag_rounded, '$completedCount/$taskCount món', Colors.teal),
                            ],
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: progress == 1.0 ? Colors.green : AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(progress == 1.0 ? Colors.green : AppColors.primary),
                          minHeight: 6,
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
    );
  }

  Widget _buildListMenu(BuildContext context, Map<String, dynamic> list) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (value) {
        if (value == 'edit') {
          _showEditSheet(context, list);
        } else if (value == 'delete') {
          _showDeleteDialog(context, list);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
              SizedBox(width: 12),
              Text('Chỉnh sửa', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
              SizedBox(width: 12),
              Text('Xóa danh sách', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    _showAddEditSheet(context);
  }

  void _showEditSheet(BuildContext context, Map<String, dynamic> list) {
    _showAddEditSheet(context, list: list);
  }

  void _showAddEditSheet(BuildContext context, {Map<String, dynamic>? list}) {
    final isEditing = list != null;
    final nameController = TextEditingController(text: list?['name']);
    final noteController = TextEditingController(text: list?['note'] ?? list?['nite'] ?? '');
    
    DateTime selectedDate = DateTime.now();
    if (list?['date'] != null) {
      try {
        selectedDate = DateTime.parse(list!['date'].toString());
      } catch (_) {
        selectedDate = DateTime.now();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
          ),
          padding: EdgeInsets.only(
            top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            left: 24, right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 32),
              Text(isEditing ? 'Sửa danh sách' : 'Lập danh sách mua sắm', 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Tên danh sách',
                  hintText: 'VD: Đi siêu thị tuần này',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.edit_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Colors.blue),
                      const SizedBox(width: 16),
                      Text('Ngày: ${DateFormat('dd/MM/yyyy').format(selectedDate)}', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Ghi chú thêm',
                  hintText: 'Nhớ mua đồ tươi...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.notes_rounded, color: Colors.orange),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final groupProv = Provider.of<GroupProvider>(context, listen: false);
                    final groupId = groupProv.homeGroup?['id'];
                    if (groupId == null) return;

                    final shoppingProv = Provider.of<ShoppingProvider>(context, listen: false);
                    try {
                      if (isEditing) {
                        await shoppingProv.updateShoppingList(list!['id'].toString(), {
                          'name': nameController.text.trim(),
                          'date': selectedDate.toIso8601String().split('T')[0],
                          'note': noteController.text.trim(),
                        });
                      } else {
                        await shoppingProv.createShoppingList(
                          name: nameController.text.trim(),
                          groupId: groupId,
                          date: selectedDate.toIso8601String().split('T')[0],
                          note: noteController.text.trim(),
                        );
                      }
                      if (context.mounted) Navigator.pop(context);
                      _fetchLists();
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4500),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text(isEditing ? 'Lưu thay đổi' : 'Tạo danh sách', 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        content: Text('Bạn có chắc chắn muốn xóa danh sách "${list['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              try {
                await Provider.of<ShoppingProvider>(context, listen: false).deleteShoppingList(list['id'].toString());
                _fetchLists();
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Xóa ngay', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
