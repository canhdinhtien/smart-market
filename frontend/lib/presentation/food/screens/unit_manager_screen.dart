import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/components/fade_in_slide.dart';
import '../../../core/components/custom_text_field.dart';
import '../../admin/providers/admin_provider.dart';

class UnitManagerScreen extends StatefulWidget {
  final String? groupName;

  const UnitManagerScreen({
    super.key,
    this.groupName,
  });

  @override
  State<UnitManagerScreen> createState() => _UnitManagerScreenState();
}

class _UnitManagerScreenState extends State<UnitManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AdminProvider>(context, listen: false).fetchUnits());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Consumer<AdminProvider>(
              builder: (context, provider, child) {
                if (provider.error != null && provider.units.isEmpty) {
                  return _buildErrorState(provider.error!);
                }
                
                if (provider.isLoading && provider.units.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(100.0),
                    child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
                  );
                }

                if (provider.units.isEmpty && !_isSearching) {
                  return _buildEmptyState();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      if (_isSearching)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: CustomTextField(
                            label: 'Tìm đơn vị',
                            controller: _searchController,
                            hint: 'Nhập tên đơn vị...',
                            prefixIcon: Icons.search,
                            onChanged: (val) => provider.fetchUnits(name: val),
                          ),
                        ),
                      ...provider.units.asMap().entries.map((entry) {
                        return FadeInSlide(
                          delay: 0.1 + (entry.key * 0.05),
                          child: _buildUnitCard(entry.value, provider),
                        );
                      }),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FadeInSlide(
        delay: 0.5,
        direction: FadeInDirection.btt,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.secondary, Color(0xFF81C784)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.4),
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
            label: const Text('Thêm đơn vị', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      backgroundColor: AppColors.secondary,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                Provider.of<AdminProvider>(context, listen: false).fetchUnits();
              }
            });
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Quản lý đơn vị', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Icon(Icons.straighten_rounded, size: 180, color: Colors.white.withOpacity(0.12)),
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
            child: Icon(Icons.architecture_rounded, size: 80, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text('Danh sách trống', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Chưa có đơn vị tính nào.', style: TextStyle(color: Colors.grey.shade500)),
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
              onPressed: () => Provider.of<AdminProvider>(context, listen: false).fetchUnits(),
              child: const Text('Thử lại'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCard(Map item, AdminProvider provider) {
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
                color: AppColors.secondary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.scale_rounded, color: AppColors.secondary, size: 24),
            ),
            title: Text(item['name'] ?? '', 
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
            subtitle: Text('Đơn vị thực phẩm', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF90A4AE)),
                  onPressed: () => _showAddEditDialog(context, unit: item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF9A9A)),
                  onPressed: () => _showDeleteConfirmation(item, provider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {Map? unit}) {
    final isEditing = unit != null;
    final controller = TextEditingController(text: unit?['name']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
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
              Text(isEditing ? 'Cập nhật đơn vị' : 'Thêm đơn vị mới', 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              const SizedBox(height: 24),
              TextField(
                controller: controller, 
                decoration: InputDecoration(
                  labelText: 'Tên đơn vị',
                  hintText: 'ví dụ: kg, cái, hộp...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.straighten_rounded, color: AppColors.secondary),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (controller.text.isEmpty) return;
                    final provider = Provider.of<AdminProvider>(context, listen: false);
                    try {
                      if (isEditing) {
                        await provider.updateUnitByName(unit['name'], controller.text.trim());
                      } else {
                        await provider.addUnit(controller.text.trim());
                      }
                      await provider.fetchUnits();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing ? 'Đã cập nhật đơn vị thành công!' : 'Đã thêm đơn vị mới thành công!'),
                            backgroundColor: Colors.green,
                          )
                        );
                      }
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().contains('403') ? 'Lỗi: Chỉ Admin mới có quyền sửa/thêm.' : e.toString()),
                          backgroundColor: Colors.redAccent,
                        )
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(isEditing ? 'Lưu thay đổi' : 'Tạo đơn vị', 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map item, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa đơn vị "${item['name']}"? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.deleteUnitByName(item['name']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa đơn vị thành công!'),
                      backgroundColor: Colors.green,
                    )
                  );
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().contains('403') ? 'Lỗi: Chỉ Admin mới có quyền xóa.' : e.toString()),
                    backgroundColor: Colors.redAccent,
                  )
                );
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
