import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/components/fade_in_slide.dart';
import '../../../core/components/custom_text_field.dart';
import '../../admin/providers/admin_provider.dart';

class CategoryManagerScreen extends StatefulWidget {
  final String? groupName;

  const CategoryManagerScreen({
    super.key,
    this.groupName,
  });

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AdminProvider>(context, listen: false).fetchCategories());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          if (provider.isLoading && provider.categories.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (provider.error != null && provider.categories.isEmpty)
            SliverFillRemaining(child: _buildErrorState(provider.error!))
          else if (provider.categories.isEmpty && !_isSearching)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (_isSearching && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: CustomTextField(
                          label: 'Tìm danh mục',
                          controller: _searchController,
                          hint: 'Nhập tên danh mục...',
                          prefixIcon: Icons.search,
                          onChanged: (val) => provider.fetchCategories(name: val),
                        ),
                      );
                    }
                    
                    final categoryIndex = _isSearching ? index - 1 : index;
                    
                    if (categoryIndex >= provider.categories.length) {
                      return const SizedBox(height: 100);
                    }

                    final category = provider.categories[categoryIndex];
                    return FadeInSlide(
                      delay: 0.1 + (categoryIndex * 0.05),
                      child: _buildCategoryCard(category, provider),
                    );
                  },
                  childCount: provider.categories.isEmpty && _isSearching ? 1 : provider.categories.length + (_isSearching ? 1 : 0) + 1,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Container(
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
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                Provider.of<AdminProvider>(context, listen: false).fetchCategories();
              }
            });
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Quản lý danh mục', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Icon(Icons.category_rounded, size: 180, color: Colors.white.withOpacity(0.12)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 0, 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(widget.groupName ?? 'Hệ thống', 
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
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
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_motion_rounded, size: 80, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text('Danh sách trống', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Chưa có danh mục nào được tạo.', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    bool is403 = message.contains('403') || message.toLowerCase().contains('forbidden');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            const SizedBox(height: 80),
            Icon(is403 ? Icons.lock_person_rounded : Icons.error_outline_rounded, size: 80, color: Colors.redAccent.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(is403 ? 'Quyền truy cập bị từ chối' : 'Đã có lỗi xảy ra', 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(is403 ? 'Chỉ tài khoản Quản trị viên hệ thống mới có quyền thực hiện chức năng này.' : message,
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Provider.of<AdminProvider>(context, listen: false).fetchCategories(),
              child: const Text('Thử lại'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map item, AdminProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 24),
            ),
            title: Text(item['name'] ?? '', 
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
            subtitle: Text('Danh mục thực phẩm', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: AppColors.textSecondary),
                  onPressed: () => _showAddEditDialog(context, category: item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
                  onPressed: () => _showDeleteConfirmation(item, provider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {Map? category}) {
    final isEditing = category != null;
    final controller = TextEditingController(text: category?['name']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          String? errorMessage;
          bool isLoading = false;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isEditing ? 'Cập nhật danh mục' : 'Thêm danh mục mới', 
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                      if (isLoading)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller, 
                    decoration: InputDecoration(
                      labelText: 'Tên danh mục',
                      hintText: 'ví dụ: Trái cây, Hải sản...',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.create_rounded, color: AppColors.primary),
                    ),
                    autofocus: true,
                    onChanged: (_) {
                      if (errorMessage != null) {
                        setModalState(() => errorMessage = null);
                      }
                    },
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        if (controller.text.trim().isEmpty) {
                          setModalState(() => errorMessage = 'Vui lòng nhập tên danh mục');
                          return;
                        }

                        setModalState(() {
                          isLoading = true;
                          errorMessage = null;
                        });

                        final provider = Provider.of<AdminProvider>(context, listen: false);
                        try {
                          if (isEditing) {
                            await provider.updateCategory(category['name'], controller.text.trim());
                          } else {
                            await provider.addCategory(controller.text.trim());
                          }
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isEditing ? 'Cập nhật danh mục thành công!' : 'Đã thêm danh mục mới!'), backgroundColor: Colors.green),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setModalState(() {
                              errorMessage = e.toString();
                              isLoading = false;
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(isEditing ? 'Lưu thay đổi' : 'Tạo danh mục', 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  void _showDeleteConfirmation(Map item, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa danh mục "${item['name']}"? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.deleteCategoryByName(item['name']);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xóa danh mục thành công!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.redAccent,
                    )
                  );
                }
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
