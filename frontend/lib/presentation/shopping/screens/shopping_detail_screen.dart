import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/components/fade_in_slide.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_provider.dart';
import '../../fridge/providers/fridge_provider.dart';
import '../../family_group/providers/group_provider.dart';
import '../../food/providers/food_provider.dart';

class ShoppingDetailScreen extends StatefulWidget {
  final dynamic listId;
  final String? listName;

  const ShoppingDetailScreen({
    super.key,
    required this.listId,
    this.listName,
  });

  @override
  State<ShoppingDetailScreen> createState() => _ShoppingDetailScreenState();
}

class _ShoppingDetailScreenState extends State<ShoppingDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final shoppingProv = Provider.of<ShoppingProvider>(context, listen: false);
      final foodProv = Provider.of<FoodProvider>(context, listen: false);
      final groupProv = Provider.of<GroupProvider>(context, listen: false);
      
      shoppingProv.fetchTasks(widget.listId);
      
      if (groupProv.homeGroup != null) {
        // Ensure food list is loaded for detail lookups
        if (foodProv.foods.isEmpty) {
          foodProv.fetchFoodsInGroup(groupProv.homeGroup!['id']);
        }
        // Ensure members are loaded for assignment
        groupProv.fetchGroupMembers(groupProv.homeGroup!['id']);
      } else {
        if (foodProv.foods.isEmpty) foodProv.fetchFoods();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: Consumer<ShoppingProvider>(
        builder: (context, shoppingProv, _) {
          final tasks = shoppingProv.tasks;
          
          if (shoppingProv.isLoading && tasks.isEmpty) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),
              if (tasks.isEmpty)
                SliverFillRemaining(child: _buildEmptyTasksState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = tasks[index];
                        return _buildTaskCard(context, task);
                      },
                      childCount: tasks.length,
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
          colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4500).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: const Text('Thêm món đồ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final shoppingProv = context.watch<ShoppingProvider>();
    final completedTasks = shoppingProv.tasks.where((t) => t['is_purchased'] == true).length;
    final totalTasks = shoppingProv.tasks.length;

    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          onPressed: () => _showDeleteListDialog(context),
        ),
      ],
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
                    widget.listName?.toUpperCase() ?? 'CHI TIẾT',
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
                            _buildHeaderStat('$completedTasks/$totalTasks', 'Đã mua', const Color(0xFFFF4500)),
                            Container(width: 1, height: 16, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.symmetric(horizontal: 12)),
                            _buildHeaderStat(totalTasks > 0 ? '${(completedTasks / totalTasks * 100).toInt()}%' : '0%', 'Tiến độ', Colors.blue.shade700),
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

  Widget _buildEmptyTasksState() {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_turned_in_outlined, size: 80, color: const Color(0xFFFF8C00).withOpacity(0.3)),
            ),
            const SizedBox(height: 24),
            Text('Danh sách trống', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text('Hãy thêm các món đồ cần mua ngay nhé!', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> task) {
    final foodProv = Provider.of<FoodProvider>(context, listen: false);
    
    // Attempt to get food details from the task or fallback to FoodProvider lookup
    final foodData = task['Food'] ?? 
                     foodProv.foods.firstWhere(
                       (f) => f['id'].toString() == task['food_id'].toString(), 
                       orElse: () => null
                     );

    final foodName = foodData?['name'] ?? task['name'] ?? 'Món ăn #$task["food_id"]';
    final imageUrl = foodData?['image_url'] ?? foodData?['imageUrl'];
    final isPurchased = task['is_purchased'] == true;
    final quantity = task['quantity'] ?? 1;
    final unitName = foodData?['Unit']?['name'] ?? foodData?['unit_name'] ?? '';

    return FadeInSlide(
      delay: 0.1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: isPurchased ? Colors.grey.withOpacity(0.05) : AppColors.primary.withOpacity(0.08),
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
            color: isPurchased ? Colors.grey.withOpacity(0.1) : AppColors.primary.withOpacity(0.12),
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
                      colors: isPurchased 
                        ? [Colors.grey.shade400, Colors.grey.shade200]
                        : [AppColors.primary, AppColors.primary.withOpacity(0.5)],
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showEditTaskSheet(context, task),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
                    child: Row(
                      children: [
                        Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: isPurchased,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            onChanged: (val) => _updateTaskStatus(task, val ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: (imageUrl != null)
                                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.fastfood_rounded, color: AppColors.primary.withOpacity(0.3), size: 28))
                                : Icon(Icons.fastfood_rounded, color: AppColors.primary.withOpacity(0.3), size: 28),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                foodName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: isPurchased ? Colors.grey.shade400 : const Color(0xFF1A1D1E),
                                  decoration: isPurchased ? TextDecoration.lineThrough : null,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPurchased ? Colors.grey.shade50 : AppColors.primary.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'SL: $quantity $unitName',
                                      style: TextStyle(
                                        color: isPurchased ? Colors.grey.shade400 : AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (task['assign_to_user_id'] != null) ...[
                                    const SizedBox(width: 8),
                                    Icon(Icons.person_outline_rounded, size: 14, color: isPurchased ? Colors.grey.shade300 : Colors.blue),
                                    const SizedBox(width: 4),
                                    Text(
                                      task['AssignedUser']?['name'] ?? 'Đã gán',
                                      style: TextStyle(
                                        color: isPurchased ? Colors.grey.shade400 : Colors.blue.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        _buildTaskMenu(context, task),
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

  void _updateTaskStatus(Map<String, dynamic> task, bool val) async {
    final foodName = task['Food']?['name'] ?? task['name'] ?? 'Không rõ';
    await Provider.of<ShoppingProvider>(context, listen: false).updateTask(task['id'].toString(), {'is_purchased': val});
    
    // UI feedback or side effects
    if (val == true && task['food_id'] != null && mounted) {
      // Auto add to fridge
      final fridgeProv = Provider.of<FridgeProvider>(context, listen: false);
      final groupProv = Provider.of<GroupProvider>(context, listen: false);
      await fridgeProv.addItem(
        foodId: task['food_id'],
        groupId: groupProv.homeGroup?['id'],
        quantity: (task['quantity'] ?? 1).toDouble(),
        useWithin: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7))),
        note: 'Tự động thêm từ danh sách đi chợ',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã mua và thêm $foodName vào tủ lạnh!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )
        );
      }
    }
    
    // Refresh tasks
    if (mounted) {
      Provider.of<ShoppingProvider>(context, listen: false).fetchTasks(widget.listId);
    }
  }

  Widget _buildTaskMenu(BuildContext context, Map<String, dynamic> task) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (value) {
        // Use addPostFrameCallback to ensure the menu is closed before showing the sheet
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (value == 'edit') {
            _showEditTaskSheet(context, task);
          } else if (value == 'delete') {
            _confirmDeleteTask(task);
          }
        });
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
              Text('Xóa món', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    _showAddEditTaskSheet(context);
  }

  void _showEditTaskSheet(BuildContext context, Map<String, dynamic> task) {
    _showAddEditTaskSheet(context, task: task);
  }

  void _showAddEditTaskSheet(BuildContext context, {Map<String, dynamic>? task}) {
    try {
      final isEditing = task != null;
      final foodProv = Provider.of<FoodProvider>(context, listen: false);
      final groupProv = Provider.of<GroupProvider>(context, listen: false);
      final members = groupProv.homeGroup?['members'] as List? ?? [];
      
      // Improved food lookup
      Map<String, dynamic>? selectedFood = isEditing 
          ? (task['Food'] ?? foodProv.foods.firstWhere(
              (f) => f['id'].toString() == task['food_id'].toString(), 
              orElse: () => null
            ))
          : null;

      Map<String, dynamic>? selectedMember = isEditing && task['assign_to_user_id'] != null
          ? members.firstWhere((m) => m['id'].toString() == task['assign_to_user_id'].toString(), orElse: () => null)
          : null;

      final quantityController = TextEditingController(text: isEditing ? task['quantity'].toString() : '1');
      final noteController = TextEditingController(text: isEditing ? (task['note'] ?? '') : '');
      String searchQuery = '';

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => StatefulBuilder(
          builder: (stContext, setState) {
          final filteredFoods = foodProv.foods.where((f) => 
            f['name'].toString().toLowerCase().contains(searchQuery.toLowerCase())
          ).toList();

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            ),
            child: SingleChildScrollView(
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
                Text(isEditing ? 'Sửa món đồ' : 'Thêm vào danh sách', 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                const SizedBox(height: 24),
                
                if (!isEditing) ...[
                  TextField(
                    onChanged: (v) => setState(() => searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm thực phẩm...',
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: filteredFoods.length,
                      itemBuilder: (context, index) {
                        final f = filteredFoods[index];
                        final isSelected = selectedFood?['id'] == f['id'];
                        return ListTile(
                          onTap: () => setState(() => selectedFood = f),
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? AppColors.primary : Colors.grey.shade100,
                            backgroundImage: f['image_url'] != null ? NetworkImage(f['image_url']) : null,
                            child: f['image_url'] == null ? Icon(Icons.fastfood_rounded, color: isSelected ? Colors.white : Colors.grey) : null,
                          ),
                          title: Text(f['name'], style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold)),
                          trailing: isSelected ? Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Số lượng',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                        child: Text(selectedFood?['Unit']?['name'] ?? selectedFood?['unit_name'] ?? 'Đơn vị', 
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Người thực hiện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: members.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = selectedMember == null;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('Bất kỳ ai'),
                            selected: isSelected,
                            onSelected: (val) => setState(() => selectedMember = null),
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            labelStyle: TextStyle(color: isSelected ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      final member = members[index - 1];
                      final isSelected = selectedMember?['id']?.toString() == member['id']?.toString();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: CircleAvatar(
                            backgroundImage: member['avatar_url'] != null ? NetworkImage(member['avatar_url']) : null,
                            child: member['avatar_url'] == null ? Text(member['name']?[0] ?? '?') : null,
                          ),
                          label: Text(member['name'] ?? 'K.Tên'),
                          selected: isSelected,
                          onSelected: (val) => setState(() => selectedMember = member),
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          labelStyle: TextStyle(color: isSelected ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedFood == null) {
                        ScaffoldMessenger.of(stContext).showSnackBar(const SnackBar(content: Text('Vui lòng chọn thực phẩm')));
                        return;
                      }
                      final shoppingProv = Provider.of<ShoppingProvider>(stContext, listen: false);
                      try {
                        if (isEditing) {
                          await shoppingProv.updateTask(task!['id'].toString(), {
                            'quantity': int.tryParse(quantityController.text) ?? 1,
                            'note': noteController.text.trim(),
                            'assign_to_user_id': selectedMember?['id'],
                          });
                        } else {
                          await shoppingProv.addTask(widget.listId, {
                            'food_id': selectedFood!['id'],
                            'quantity': int.tryParse(quantityController.text) ?? 1,
                            'note': noteController.text.trim(),
                            'assign_to_user_id': selectedMember?['id'],
                          });
                        }
                        if (mounted) {
                          Navigator.pop(context);
                          shoppingProv.fetchTasks(widget.listId);
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4500),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text(isEditing ? 'Lưu thay đổi' : 'Thêm ngay', 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      ),
    );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể mở bảng chỉnh sửa: $e')));
      }
    }
  }

  void _confirmDeleteTask(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Xóa món đồ', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        content: const Text('Bạn có chắc muốn xóa món đồ này khỏi danh sách không?', style: TextStyle(fontWeight: FontWeight.w500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold))),
          TextButton(
            onPressed: () async {
              await Provider.of<ShoppingProvider>(context, listen: false).deleteTask(task['id'].toString());
              if (mounted) {
                Navigator.pop(context);
                Provider.of<ShoppingProvider>(context, listen: false).fetchTasks(widget.listId);
              }
            },
            child: const Text('Xóa ngay', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showDeleteListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Xóa danh sách', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        content: const Text('Bạn có chắc muốn xóa toàn bộ danh sách này không?', style: TextStyle(fontWeight: FontWeight.w500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<ShoppingProvider>(context, listen: false).deleteShoppingList(widget.listId);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, 
              foregroundColor: Colors.white, 
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
            ),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
