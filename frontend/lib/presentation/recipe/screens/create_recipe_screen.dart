import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import '../../family_group/providers/group_provider.dart';
import '../../food/providers/food_provider.dart';
import '../../../../core/components/custom_text_field.dart';
import 'dart:typed_data';
import '../../../../core/components/primary_button.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';

class CreateRecipeScreen extends StatefulWidget {
  final Recipe? recipeToEdit;

  const CreateRecipeScreen({super.key, this.recipeToEdit});

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  XFile? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _ingredients = [];

  @override
  void initState() {
    super.initState();
    if (widget.recipeToEdit != null) {
      _nameController.text = widget.recipeToEdit!.name;
      _descController.text = widget.recipeToEdit!.description ?? '';
      _instructionsController.text = widget.recipeToEdit!.instructions ?? '';
      
      if (widget.recipeToEdit!.ingredients != null) {
        _ingredients = widget.recipeToEdit!.ingredients!.map((i) => {
          'food_id': i.foodId,
          'foodId': i.foodId,
          'quantity': i.quantity,
          'unit_id': i.unitId,
          'unitId': i.unitId,
          'food_name': i.foodName,
          'unit_name': i.unitName,
        }).toList();
      }
    }
  }

  void _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chọn ảnh món ăn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(Icons.photo_library_rounded, 'Thư viện', ImageSource.gallery),
                _buildPickerOption(Icons.camera_alt_rounded, 'Máy ảnh', ImageSource.camera),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(IconData icon, String label, ImageSource source) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
        if (image != null) {
          final bytes = await image.readAsBytes();
          setState(() {
            _imageFile = image;
            _imageBytes = bytes;
          });
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.orange, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _addIngredient() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddIngredientSheet(
        onAdd: (foodId, quantity, unitId, foodName, unitName) {
          setState(() {
            _ingredients.add({
              'food_id': foodId,
              'foodId': foodId,
              'quantity': quantity,
              'unit_id': unitId,
              'unitId': unitId,
              'food_name': foodName,
              'unit_name': unitName,
            });
          });
        },
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text;
    final description = _descController.text;
    final instructions = _instructionsController.text;
    
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final groupId = groupProvider.managementGroup?['id'];

    if (groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: Chưa chọn nhóm')));
      return;
    }

    final data = {
      'name': name,
      'description': description,
      'instructions': instructions,
      'group_id': groupId,
      'ingredients': _ingredients,
    };

    final provider = Provider.of<RecipeProvider>(context, listen: false);
    bool success;

    if (widget.recipeToEdit != null) {
      success = await provider.updateRecipe(widget.recipeToEdit!.id, data, image: _imageFile);
    } else {
      success = await provider.createRecipe(data, image: _imageFile);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.recipeToEdit != null ? '✅ Cập nhật món ăn thành công!' : '✅ Đã thêm món ăn mới!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi: ${provider.error ?? "Không thể lưu món ăn"}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.recipeToEdit != null ? 'Chỉnh sửa' : 'Tạo món mới',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker Section
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                      image: _imageBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_imageBytes!),
                              fit: BoxFit.cover,
                            )
                          : (widget.recipeToEdit?.imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(widget.recipeToEdit!.imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null),
                    ),
                    child: (_imageFile == null && widget.recipeToEdit?.imageUrl == null)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'Thêm ảnh món ăn',
                                style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                              ),
                            ],
                          )
                        : Stack(
                            children: [
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: const Icon(Icons.edit_rounded, size: 20, color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                label: 'Tên món ăn',
                controller: _nameController,
                hintText: 'VD: Phở bò Hà Nội',
                prefixIcon: Icons.restaurant_rounded,
                validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập tên món' : null,
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Mô tả ngắn',
                controller: _descController,
                maxLines: 2,
                hintText: 'Chia sẻ một chút về món ăn này...',
                prefixIcon: Icons.description_rounded,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text(
                    'Nguyên liệu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: _addIngredient,
                    icon: const Icon(Icons.add_circle_rounded, color: Colors.orange, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_ingredients.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade100, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.shopping_basket_outlined, color: Colors.grey.shade300, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có nguyên liệu nào',
                        style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ingredients.length,
                  itemBuilder: (context, index) {
                    final item = _ingredients[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          item['food_name'] ?? 'Món ăn',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          '${item['quantity']} ${item['unit_name']}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: Colors.red),
                          onPressed: () => setState(() => _ingredients.removeAt(index)),
                        ),
                      ),
                    );
                  },
                ),
              
              const SizedBox(height: 32),
              const Text(
                'Hướng dẫn thực hiện',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Các bước nấu',
                controller: _instructionsController,
                maxLines: 8,
                hintText: 'Bước 1: ...\nBước 2: ...',
              ),
              
              const SizedBox(height: 100), // Spacing for fab or button
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        child: Consumer<RecipeProvider>(
          builder: (context, provider, child) {
            return PrimaryButton(
              text: widget.recipeToEdit != null ? 'Cập nhật món ăn' : 'Lưu món ăn',
              isLoading: provider.isLoading,
              onPressed: _submit,
            );
          },
        ),
      ),
    );
  }
}

class _AddIngredientSheet extends StatefulWidget {
  final Function(int foodId, double quantity, int unitId, String foodName, String unitName) onAdd;

  const _AddIngredientSheet({required this.onAdd});

  @override
  State<_AddIngredientSheet> createState() => _AddIngredientSheetState();
}

class _AddIngredientSheetState extends State<_AddIngredientSheet> {
  final _searchController = TextEditingController();
  final _qtyController = TextEditingController();
  
  // Selection
  Map<String, dynamic>? _selectedFood;
  int? _selectedUnitId;
  String? _selectedUnitName;

  bool _isSearching = false;
  List<dynamic> _searchResults = [];
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FoodProvider>(context, listen: false).fetchUnits();
    });
  }

  // Unit picker removed as per user request

  void _searchFood(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    
    try {
      final provider = Provider.of<FoodProvider>(context, listen: false);
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final groupId = groupProvider.managementGroup?['id'] ?? groupProvider.currentGroup?['id'];
      
      if (groupId != null) {
        await provider.fetchFoodsInGroup(groupId);
      } else {
        await provider.fetchFoods();
      }
      // Filter locally
      final allFoods = provider.foods;
      _searchResults = allFoods.where((f) => 
        (f['name'] as String).toLowerCase().contains(query.toLowerCase())
      ).take(10).toList();
      
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
     return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Thêm Nguyên Liệu', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)
            ),
            const SizedBox(height: 24),
            
            if (_selectedFood == null) ...[
              CustomTextField(
                controller: _searchController,
                label: 'Tìm kiếm thực phẩm',
                hintText: 'VD: Hành lá, Thịt bò...',
                prefixIcon: Icons.search_rounded,
                onChanged: (val) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    _searchFood(val);
                  });
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final food = _searchResults[index];
                          final img = food['image_url'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  image: img != null ? DecorationImage(image: NetworkImage(img), fit: BoxFit.cover) : null,
                                ),
                                child: img == null ? const Icon(Icons.fastfood_rounded, color: Colors.orange, size: 24) : null,
                              ),
                              title: Text(food['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Đơn vị mặc định: ${food['unit_name'] ?? 'Cái'}'),
                              trailing: const Icon(Icons.add_circle_outline_rounded, color: Colors.orange),
                              onTap: () {
                                setState(() {
                                  _selectedFood = food;
                                  // Simplified: Always use food's linked unit
                                  _selectedUnitId = food['unit_id'] ?? food['unitId'] ?? food['Unit']?['id'];
                                  _selectedUnitName = food['unit_name'] ?? food['unitName'] ?? food['Unit']?['name'] ?? 'đv';
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
            ] else ...[
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.orange.withOpacity(0.05),
                   borderRadius: BorderRadius.circular(20),
                 ),
                 child: Row(
                   children: [
                     Container(
                       width: 60, height: 60,
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(15),
                         image: _selectedFood!['image_url'] != null 
                             ? DecorationImage(image: NetworkImage(_selectedFood!['image_url']), fit: BoxFit.cover) : null,
                       ),
                       child: _selectedFood!['image_url'] == null 
                           ? const Icon(Icons.fastfood_rounded, color: Colors.orange) : null,
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(_selectedFood!['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                           const Text('Đang chọn nguyên liệu', style: TextStyle(color: Colors.grey, fontSize: 13)),
                         ],
                       ),
                     ),
                     IconButton(
                       icon: const Icon(Icons.close_rounded, color: Colors.grey),
                       onPressed: () => setState(() => _selectedFood = null),
                     ),
                   ],
                 ),
               ),
               const SizedBox(height: 32),
               Row(
                 children: [
                   Expanded(
                     child: CustomTextField(
                       controller: _qtyController,
                       label: 'Số lượng',
                       hintText: '0.0',
                       keyboardType: const TextInputType.numberWithOptions(decimal: true),
                     ),
                   ),
                   const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Đơn vị',
                        readOnly: true,
                        controller: TextEditingController(text: _selectedUnitName ?? ''),
                        hintText: 'Tự động',
                        prefixIcon: Icons.unfold_more_rounded,
                      ),
                    ),
                 ],
               ),
               const Spacer(),
               PrimaryButton(
                 text: 'Thêm vào danh sách',
                 onPressed: () {
                    final qty = double.tryParse(_qtyController.text);
                    if (qty == null) return;
                    
                    final foodId = int.tryParse(_selectedFood!['id'].toString()) ?? _selectedFood!['id'];
                    final unitId = int.tryParse((_selectedUnitId ?? _selectedFood!['unit_id'] ?? _selectedFood!['Unit']?['id'] ?? 1).toString()) ?? 1;

                    widget.onAdd(
                      foodId,
                      qty,
                      unitId,
                      _selectedFood!['name'],
                      _selectedUnitName ?? 'đv',
                    );
                    Navigator.pop(context);
                 },
               ),
            ],
          ],
        ),
     );
  }
}
