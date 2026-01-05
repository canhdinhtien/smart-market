import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/custom_text_field.dart';
import '../../../../core/components/primary_button.dart';
import '../../../../core/components/fade_in_slide.dart';
import '../providers/auth_provider.dart';
import './email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedGender = 'Nam';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Nền trang trí (Đồng bộ với Login)
          Positioned(
            top: -size.width * 0.3,
            left: -size.width * 0.2,
            child: _buildBlurCircle(AppColors.primary.withOpacity(0.12), size.width * 0.7),
          ),
          Positioned(
            bottom: -size.width * 0.4,
            right: -size.width * 0.3,
            child: _buildBlurCircle(AppColors.primary.withOpacity(0.08), size.width * 0.8),
          ),

          // 2. Nội dung chính
          SafeArea(
            child: Column(
              children: [
                // Nút Back tinh tế
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          
                          // Header Section
                          FadeInSlide(
                            delay: 0.1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tạo tài khoản 👋',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -1,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tham gia FoodY để quản lý bữa ăn gia đình thông minh và tiết kiệm hơn.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withOpacity(0.8),
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Form Fields
                          FadeInSlide(
                            delay: 0.2,
                            child: CustomTextField(
                              label: 'Họ và tên',
                              hint: 'Nhập tên của bạn',
                              controller: _nameController,
                              prefixIcon: Icons.person_outline_rounded,
                              validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập họ tên' : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeInSlide(
                            delay: 0.3,
                            child: CustomTextField(
                              label: 'Email',
                              hint: 'example@mail.com',
                              controller: _emailController,
                              prefixIcon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                                if (!value.contains('@')) return 'Email không hợp lệ';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeInSlide(
                            delay: 0.35,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Giới tính',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildGenderChip('Nam'),
                                    const SizedBox(width: 12),
                                    _buildGenderChip('Nữ'),
                                    const SizedBox(width: 12),
                                    _buildGenderChip('Khác'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeInSlide(
                            delay: 0.4,
                            child: CustomTextField(
                              label: 'Mật khẩu',
                              hint: '••••••••',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (value) => (value != null && value.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeInSlide(
                            delay: 0.5,
                            child: CustomTextField(
                              label: 'Xác nhận mật khẩu',
                              hint: '••••••••',
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              prefixIcon: Icons.verified_user_outlined,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                              validator: (value) => (value != _passwordController.text) ? 'Mật khẩu không khớp' : null,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Button Đăng ký
                          FadeInSlide(
                            delay: 0.6,
                            child: Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                return PrimaryButton(
                                  text: 'Tạo tài khoản ngay',
                                  isLoading: auth.isLoading,
                                  onPressed: () => _handleRegister(auth),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Login Link
                          FadeInSlide(
                            delay: 0.7,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Đã có tài khoản? ',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
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
    );
  }

  // Widget hỗ trợ: Lựa chọn giới tính
  Widget _buildGenderChip(String gender) {
    final isSelected = _selectedGender == gender;
    return ChoiceChip(
      label: Text(gender),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedGender = gender);
        }
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

  // Widget hỗ trợ: Vòng tròn mờ nền (Đồng nhất với Login)
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

  Future<void> _handleRegister(AuthProvider auth) async {
    if (_formKey.currentState!.validate()) {
      try {
        String genderValue = 'other';
        if (_selectedGender == 'Nam') genderValue = 'male';
        if (_selectedGender == 'Nữ') genderValue = 'female';

        await auth.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          gender: genderValue,
        );

        if (!mounted) return;

        if (auth.isVerificationPending) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                email: _emailController.text.trim(),
              ),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Đã có lỗi xảy ra'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}