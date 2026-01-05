import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/fridge_provider.dart';
import '../../family_group/providers/group_provider.dart';
import '../../food/providers/food_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/components/fade_in_slide.dart';

class AddFridgeItemDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Map<String, dynamic>? initialFood;

  const AddFridgeItemDialog({super.key, this.item, this.initialFood});

  @override
  State<AddFridgeItemDialog> createState() => _AddFridgeItemDialogState();
}

class _AddFridgeItemDialogState extends State<AddFridgeItemDialog> {
  late dynamic selectedFoodId;
  late Map? selectedFoodItem;
  late TextEditingController quantityController;
  late TextEditingController useWithinController;
  late TextEditingController noteController;
  bool isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    isEditing = widget.item != null;
    selectedFoodId = widget.item?['food_id'] ?? widget.initialFood?['id'];
    selectedFoodItem = widget.item?['Food'] ?? widget.initialFood;

    quantityController = TextEditingController(text: widget.item?['quantity']?.toString() ?? '1');
    // Important: use_within is the date string, use_within_days is the integer
    useWithinController = TextEditingController(text: widget.item?['use_within']?.toString() ?? '');
    noteController = TextEditingController(text: widget.item?['note'] ?? '');
  }

  @override
  void dispose() {
    quantityController.dispose();
    useWithinController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    double current = double.tryParse(quantityController.text) ?? 0;
    setState(() {
      quantityController.text = (current + 1).toString();
    });
  }

  void _decrementQuantity() {
    double current = double.tryParse(quantityController.text) ?? 1;
    if (current > 1) {
      setState(() {
        quantityController.text = (current - 1).toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProv = Provider.of<GroupProvider>(context, listen: false);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Drag Handle
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    const SizedBox(height: 16),
                    FadeInSlide(
                      delay: 0.1,
                      child: Text(
                        isEditing ? 'Chỉnh sửa thực phẩm' : 'Thêm vào tủ lạnh',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1D1E),
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Food Selector
                    FadeInSlide(
                      delay: 0.2,
                      child: _buildSectionTitle('THỰC PHẨM'),
                    ),
                    const SizedBox(height: 8),
                    FadeInSlide(
                      delay: 0.25,
                      child: _buildFoodCard(context),
                    ),

                    const SizedBox(height: 16),
                    FadeInSlide(
                      delay: 0.3,
                      child: _buildSectionTitle('THÔNG TIN CHI TIẾT'),
                    ),
                    const SizedBox(height: 8),

                    FadeInSlide(
                      delay: 0.35,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildQuantityControl()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDatePickerField(context)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInSlide(
                      delay: 0.4,
                      child: _buildNoteField(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              
              // Bottom Action Button
              Padding(
                padding: EdgeInsets.fromLTRB(24, 4, 24, MediaQuery.of(context).padding.bottom + 12),
                child: FadeInSlide(
                  delay: 0.5,
                  direction: FadeInDirection.btt,
                  child: _buildActionButton(groupProv),
                ),
              ),
            ],
          ),

          if (_isLoading)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: AppColors.primary.withOpacity(0.8),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildFoodCard(BuildContext context) {
    return InkWell(
      onTap: isEditing ? null : () => _pickFood(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selectedFoodId != null 
                ? AppColors.primary.withOpacity(0.3) 
                : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(20),
                image: selectedFoodItem?['image_url'] != null
                    ? DecorationImage(image: NetworkImage(selectedFoodItem!['image_url']), fit: BoxFit.cover)
                    : null,
              ),
              child: selectedFoodItem?['image_url'] == null
                  ? Icon(Icons.restaurant_rounded, color: AppColors.primary.withOpacity(0.5), size: 32)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedFoodItem?['name'] ?? 'Chưa chọn thực phẩm',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: selectedFoodId != null ? const Color(0xFF1A1D1E) : Colors.grey.shade400,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      selectedFoodItem?['Category']?['name'] ?? selectedFoodItem?['category']?['name'] ?? 'Thư viện thực phẩm',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isEditing) 
              Icon(Icons.unfold_more_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControl() {
    final unit = selectedFoodItem?['Unit']?['name'] ?? selectedFoodItem?['unit']?['name'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SỐ LƯỢNG',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Color(0xFF8E8E93),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _decrementQuantity,
                icon: const Icon(Icons.remove_circle_rounded, color: AppColors.primary, size: 28),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: quantityController,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: Color(0xFF1A1D1E),
                        height: 1,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (unit.isNotEmpty)
                      Text(
                        unit,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _incrementQuantity,
                icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HẠN SỬ DỤNG',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Color(0xFF8E8E93),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: useWithinController.text.isNotEmpty 
                  ? DateTime.tryParse(useWithinController.text) ?? DateTime.now().add(const Duration(days: 7))
                  : DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF1A1D1E),
                  ),
                ),
                child: child!,
              ),
            );
            if (date != null) {
              setState(() {
                useWithinController.text = DateFormat('yyyy-MM-dd').format(date);
              });
            }
          },
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: useWithinController.text.isNotEmpty ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_note_rounded, color: AppColors.primary, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        useWithinController.text.isEmpty 
                            ? 'Chọn ngày' 
                            : () {
                                final date = DateTime.tryParse(useWithinController.text);
                                return date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Ngày không hợp lệ';
                              }(),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: useWithinController.text.isEmpty ? Colors.grey.shade400 : const Color(0xFF1A1D1E),
                        ),
                      ),
                      if (useWithinController.text.isNotEmpty && DateTime.tryParse(useWithinController.text) != null)
                        Text(
                          '${DateTime.parse(useWithinController.text).difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays} ngày nữa',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ghi chú',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8E8E93),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: noteController,
            maxLines: 2,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1D1E)),
            decoration: const InputDecoration(
              hintText: 'Nhập ghi chú tại đây...',
              hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(GroupProvider groupProv) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (selectedFoodId == null) ? null : () => _handleSubmit(groupProv),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
        child: Text(
          isEditing ? 'CẬP NHẬT THAY ĐỔI' : 'THÊM VÀO TỦ LẠNH',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(GroupProvider groupProv) async {
    setState(() => _isLoading = true);
    final provider = Provider.of<FridgeProvider>(context, listen: false);
    final groupId = groupProv.homeGroup?['id'];

    try {
      final parsedFoodId = int.tryParse(selectedFoodId.toString()) ?? selectedFoodId;
      final parsedGroupId = int.tryParse(groupId.toString()) ?? groupId;

      if (isEditing) {
        await provider.updateItem(
          id: widget.item!['id'],
          foodId: parsedFoodId,
          groupId: parsedGroupId,
          quantity: double.tryParse(quantityController.text),
          useWithin: useWithinController.text,
          note: noteController.text,
          foodMap: selectedFoodItem,
        );
      } else {
        await provider.addItem(
          foodId: parsedFoodId,
          groupId: parsedGroupId,
          quantity: double.tryParse(quantityController.text) ?? 1,
          useWithin: useWithinController.text,
          note: noteController.text,
          foodMap: selectedFoodItem,
        );
      }
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _pickFood(BuildContext context) {
    final foodProv = Provider.of<FoodProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Thư Viện Thực Phẩm',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1D1E), letterSpacing: -1.0),
            ),
            const SizedBox(height: 4),
            Text('Chọn một món để quản lý', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            Expanded(
              child: foodProv.foods.isEmpty
                  ? const Center(child: Text('Không có dữ liệu thực phẩm'))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: foodProv.foods.length,
                      itemBuilder: (context, index) {
                        final food = foodProv.foods[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            onTap: () {
                              setState(() {
                                selectedFoodId = food['id'];
                                selectedFoodItem = food;
                              });
                              Navigator.pop(context);
                            },
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                image: food['image_url'] != null ? DecorationImage(image: NetworkImage(food['image_url']), fit: BoxFit.cover) : null,
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: food['image_url'] == null ? const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 28) : null,
                            ),
                            title: Text(
                              food['name'] ?? 'Không tên', 
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1D1E), letterSpacing: -0.5),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                food['Category']?['name'] ?? food['category']?['name'] ?? 'Chưa rõ danh mục', 
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 24),
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
}
