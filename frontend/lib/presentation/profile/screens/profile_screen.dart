import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/fade_in_slide.dart';
import '../../../../core/components/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<ProfileProvider>(context, listen: false).fetchProfile());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Background Decor (Đồng bộ với các màn hình Auth)
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.2,
            child: _buildBlurCircle(AppColors.primary.withOpacity(0.12), size.width * 0.7),
          ),
          Positioned(
            bottom: -size.width * 0.4,
            left: -size.width * 0.3,
            child: _buildBlurCircle(AppColors.primary.withOpacity(0.08), size.width * 0.8),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                _buildAppBar(context),

                Expanded(
                  child: Consumer<ProfileProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(provider.error!, style: TextStyle(color: AppColors.textSecondary)),
                              TextButton(
                                onPressed: () => provider.fetchProfile(),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        );
                      }

                      final user = provider.user;
                      if (user == null) {
                        return const Center(child: Text('Không thể tải thông tin'));
                      }

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            
                            // Avatar Section
                            FadeInSlide(
                              delay: 0.1,
                              child: _buildAvatarSection(context, user),
                            ),

                            const SizedBox(height: 40),

                            // Profile Actions Group
                            FadeInSlide(
                              delay: 0.2,
                              child: _buildProfileCard(
                                children: [
                                  _buildProfileItem(
                                    icon: Icons.person_outline_rounded,
                                    title: 'Chỉnh sửa thông tin',
                                    subtitle: 'Tên, giới tính, email...',
                                    onTap: () => _showEditProfileBottomSheet(context, user),
                                  ),
                                  _buildDivider(),
                                  _buildProfileItem(
                                    icon: Icons.lock_outline_rounded,
                                    title: 'Đổi mật khẩu',
                                    subtitle: 'Bảo mật tài khoản của bạn',
                                    onTap: () => _showChangePasswordDialog(context),
                                  ),
                                  _buildDivider(),
                                  _buildProfileItem(
                                    icon: Icons.notifications_none_rounded,
                                    title: 'Thông báo',
                                    subtitle: 'Quản lý cài đặt thông báo',
                                    onTap: () => _showNotImplementedSnackBar(),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Secondary Actions
                            FadeInSlide(
                              delay: 0.3,
                              child: _buildProfileCard(
                                children: [
                                  _buildProfileItem(
                                    icon: Icons.help_outline_rounded,
                                    title: 'Trợ giúp & Hỗ trợ',
                                    onTap: () => _showNotImplementedSnackBar(),
                                  ),
                                  _buildDivider(),
                                  _buildProfileItem(
                                    icon: Icons.info_outline_rounded,
                                    title: 'Về chúng tôi',
                                    onTap: () => _showNotImplementedSnackBar(),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Delete Account Button
                            FadeInSlide(
                              delay: 0.35,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: InkWell(
                                  onTap: () => _showDeleteAccountDialog(context),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.delete_forever_rounded, color: Colors.red.shade700, size: 20),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Xóa tài khoản',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Logout Button
                            FadeInSlide(
                              delay: 0.4,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.red.shade100),
                                ),
                                child: InkWell(
                                  onTap: () => _handleLogout(context),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 20),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Đăng xuất',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
          ),
          Text(
            'Hồ sơ của bạn',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(width: 48), // Spacer for balance
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, Map<String, dynamic> user) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: AppColors.shadowLg,
              ),
              child: GestureDetector(
                onTap: () => _showAvatarDialog(context, user['avatar']),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: Colors.white,
                  backgroundImage: (user['avatar'] ?? user['profile_pic'] ?? user['image_url']) != null
                      ? NetworkImage(user['avatar'] ?? user['profile_pic'] ?? user['image_url'])
                      : null,
                  child: (user['avatar'] ?? user['profile_pic'] ?? user['image_url']) == null
                      ? const Icon(Icons.person_rounded, size: 54, color: AppColors.textSecondary)
                      : null,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user['name'] ?? 'Guest User',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user['email'] ?? '',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24), // Ideally matching the card
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 64, color: Colors.grey.shade100);
  }

  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  void _showNotImplementedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tính năng đang được phát triển 🚀'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              // Chờ quá trình đăng xuất hoàn tất (xóa token, gọi API)
              await Provider.of<AuthProvider>(context, listen: false).logout();
              
              if (context.mounted) {
                // Sau khi đã đăng xuất xong xuôi mới quay về màn hình chính
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Reusing existing logic but styled better ---

  void _showChangePasswordDialog(BuildContext context) {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? localErrorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 32,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Đổi mật khẩu',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (localErrorMessage != null) ...[
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
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              localErrorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  CustomTextField(
                    label: 'Mật khẩu hiện tại',
                    hint: '••••••••',
                    controller: oldPassController,
                    obscureText: obscureOld,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(obscureOld ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                      onPressed: () => setModalState(() => obscureOld = !obscureOld),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập mật khẩu cũ' : null,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Mật khẩu mới',
                    hint: '••••••••',
                    controller: newPassController,
                    obscureText: obscureNew,
                    prefixIcon: Icons.vpn_key_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                      onPressed: () => setModalState(() => obscureNew = !obscureNew),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                      if (value.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Xác nhận mật khẩu mới',
                    hint: '••••••••',
                    controller: confirmPassController,
                    obscureText: obscureConfirm,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.verified_user_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                      onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                    ),
                    validator: (value) {
                      if (value != newPassController.text) return 'Mật khẩu xác nhận không khớp';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        setModalState(() => localErrorMessage = null);
                        Provider.of<ProfileProvider>(context, listen: false)
                            .changePassword(oldPassController.text, newPassController.text)
                            .then((_) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đổi mật khẩu thành công'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }).catchError((e) {
                          setModalState(() => localErrorMessage = e.toString());
                        });
                      }
                    },
                    child: const Text('Cập nhật mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAvatarDialog(BuildContext context, String? imageUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cập nhật ảnh đại diện',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceTile(
                    icon: Icons.camera_alt_rounded,
                    label: 'Máy ảnh',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageSourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Thư viện',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showEditProfileBottomSheet(BuildContext context, Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name'] ?? '');
    
    // Map backend value to UI Label
    String initialGender = 'Khác';
    if (user['gender'] == 'male') initialGender = 'Nam';
    else if (user['gender'] == 'female') initialGender = 'Nữ';
    
    String selectedGender = initialGender;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 32,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Chỉnh sửa hồ sơ',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    label: 'Họ và tên',
                    hint: 'Nhập tên của bạn',
                    controller: nameController,
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập họ tên' : null,
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Giới tính',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildEditGenderChip('Nam', selectedGender, (val) => setModalState(() => selectedGender = val)),
                          const SizedBox(width: 12),
                          _buildEditGenderChip('Nữ', selectedGender, (val) => setModalState(() => selectedGender = val)),
                          const SizedBox(width: 12),
                          _buildEditGenderChip('Khác', selectedGender, (val) => setModalState(() => selectedGender = val)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        // Map UI label to Backend Value
                        String genderValue = 'other';
                        if (selectedGender == 'Nam') genderValue = 'male';
                        else if (selectedGender == 'Nữ') genderValue = 'female';

                        Provider.of<ProfileProvider>(context, listen: false)
                            .updateProfile({
                          'name': nameController.text.trim(),
                          'gender': genderValue,
                        }).then((_) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cập nhật thông tin thành công'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }).catchError((e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi: ${e.toString()}'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        });
                      }
                    },
                    child: const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditGenderChip(String gender, String current, Function(String) onSelected) {
    final isSelected = current == gender;
    return ChoiceChip(
      label: Text(gender),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onSelected(gender);
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey.shade100,
      elevation: 0,
      pressElevation: 0,
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.shade200,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      if (!mounted) return;
      
      try {
        final bytes = await pickedFile.readAsBytes();
        final fileName = pickedFile.name;
        
        await Provider.of<ProfileProvider>(context, listen: false)
            .uploadAvatar(bytes, fileName);
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật ảnh đại diện thành công'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Xóa tài khoản',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn có chắc chắn muốn xóa tài khoản vĩnh viễn?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Lưu ý quan trọng:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Tất cả dữ liệu sẽ bị xóa vĩnh viễn\n• Bạn sẽ bị đăng xuất ngay lập tức\n• Không thể khôi phục sau khi xóa',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteAccount(context);
            },
            child: Text(
              'Tiếp tục',
              style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Xác nhận xóa tài khoản',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Để xác nhận, vui lòng nhập "XOA TAI KHOAN" vào ô bên dưới:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmController,
                decoration: InputDecoration(
                  hintText: 'XOA TAI KHOAN',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.shade700, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().toUpperCase() != 'XOA TAI KHOAN') {
                    return 'Vui lòng nhập chính xác "XOA TAI KHOAN"';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context); // Close confirmation dialog
                
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Đang xóa tài khoản...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                try {
                  await Provider.of<ProfileProvider>(context, listen: false).deleteAccount();
                  // Logout is automatically triggered in ProfileProvider
                  // User will be redirected to login screen by AuthWrapper
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Xóa tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
