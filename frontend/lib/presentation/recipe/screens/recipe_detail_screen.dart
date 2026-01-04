import 'package:flutter/material.dart';
import '../../../../data/models/recipe_model.dart';
import 'create_recipe_screen.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../../shopping/providers/shopping_provider.dart';
import '../../family_group/providers/group_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/glass_container.dart';
import '../../../../core/components/fade_in_slide.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Recipe? _detailedRecipe;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _detailedRecipe = widget.recipe;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final provider = Provider.of<RecipeProvider>(context, listen: false);
    final groupProv = Provider.of<GroupProvider>(context, listen: false);
    final groupId = groupProv.managementGroup?['id'];
    
    final fullRecipe = await provider.getRecipeDetail(widget.recipe.id, groupId: groupId);
    
    if (mounted && fullRecipe != null) {
      setState(() {
        _detailedRecipe = fullRecipe;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _addToShoppingList() async {
    final recipe = _detailedRecipe ?? widget.recipe;
    final missing = recipe.ingredients?.where((ing) => ing.inFridge == false).toList() ?? [];
    
    if (missing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Tất cả nguyên liệu đã có sẵn trong tủ lạnh!')),
      );
      return;
    }

    final shoppingProv = Provider.of<ShoppingProvider>(context, listen: false);
    final groupProv = Provider.of<GroupProvider>(context, listen: false);
    final groupId = groupProv.managementGroup?['id'];

    if (groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn nhóm trước khi thêm vào danh sách đi chợ')),
      );
      return;
    }

    try {
      // Find or create shopping list
      if (shoppingProv.shoppingLists.isEmpty) {
        await shoppingProv.fetchShoppingLists(groupId: groupId);
      }

      String? listId;
      if (shoppingProv.shoppingLists.isNotEmpty) {
        listId = shoppingProv.shoppingLists.first['id'].toString();
      } else {
        await shoppingProv.createShoppingList(
          name: 'Đi chợ cho ${recipe.name}',
          groupId: groupId,
        );
        listId = shoppingProv.shoppingLists.first['id'].toString();
      }

      for (var ing in missing) {
        await shoppingProv.addTask(listId, {
          'name': ing.foodName ?? 'Nguyên liệu',
          'quantity': ing.quantity ?? 1,
          'is_bought': false,
          'notes': 'Mua cho món: ${recipe.name}',
          'food_id': ing.foodId,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Đã thêm nguyên liệu thiếu vào danh sách đi chợ!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = _detailedRecipe ?? widget.recipe;
    final missingCount = recipe.ingredients?.where((ing) => ing.inFridge == false).length ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: recipe.imageUrl != null
                ? Image.network(recipe.imageUrl!, fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.restaurant_rounded, 
                        size: 100, 
                        color: Colors.white.withOpacity(0.3)
                      ),
                    ),
                  ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateRecipeScreen(recipeToEdit: recipe),
                    ),
                  );
                  _fetchDetails();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _confirmDelete(),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInSlide(
                    direction: FadeInDirection.ttb,
                    child: Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (recipe.description != null && recipe.description!.isNotEmpty)
                    FadeInSlide(
                      delay: 0.1,
                      child: Text(
                        recipe.description!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Nguyên liệu', Icons.shopping_basket_rounded),
                  const SizedBox(height: 16),
                  if (recipe.ingredients != null && recipe.ingredients!.isNotEmpty)
                    ...recipe.ingredients!.asMap().entries.map((entry) {
                      return FadeInSlide(
                        delay: 0.2 + (entry.key * 0.05),
                        child: _buildIngredientCard(entry.value),
                      );
                    })
                  else
                    const Text('Chưa có thông tin nguyên liệu'),
                  
                  if (missingCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addToShoppingList,
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                          label: Text('Mua $missingCount nguyên liệu còn thiếu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                  _buildSectionHeader('Cách thực hiện', Icons.menu_book_rounded),
                  const SizedBox(height: 16),
                  FadeInSlide(
                    delay: 0.5,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        recipe.instructions ?? 'Chưa có hướng dẫn cụ thể.',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.8,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 22),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientCard(RecipeIngredient ing) {
    final bool hasInFridge = ing.inFridge == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (hasInFridge ? Colors.green : Colors.orange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasInFridge ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: hasInFridge ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ing.foodName ?? 'Nguyên liệu',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  hasInFridge ? 'Sẵn có trong tủ lạnh' : 'Cần chuẩn bị thêm',
                  style: TextStyle(
                    fontSize: 12, 
                    color: hasInFridge ? Colors.green : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${ing.quantity ?? ""} ${ing.unitName ?? ""}',
            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final recipe = _detailedRecipe ?? widget.recipe;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Xóa công thức?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Anh/chị chắc chắn muốn xóa công thức này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Xóa ngay', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = Provider.of<RecipeProvider>(context, listen: false);
      final success = await provider.deleteRecipe(recipe.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã xóa món ăn'), behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: ${provider.error ?? "Không thể xóa"}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
