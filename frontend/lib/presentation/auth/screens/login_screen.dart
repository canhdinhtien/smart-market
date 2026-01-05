import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/custom_text_field.dart';
import '../../../../core/components/primary_button.dart';
import '../../../../core/components/fade_in_slide.dart';
import '../providers/auth_provider.dart';
import './email_verification_screen.dart';
import './forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Decor (Các đốm màu trang trí tạo sự hiện đại)
          Positioned(
            top: -size.width * 0.4,
            right: -size.width * 0.2,
            child: _buildBlurCircle(AppColors.primary.withOpacity(0.15), size.width * 0.8),
          ),
          Positioned(
            bottom: -size.width * 0.2,
            left: -size.width * 0.3,
            child: _buildBlurCircle(AppColors.primary.withOpacity(0.1), size.width * 0.6),
          ),

          // 2. Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        
                        // Logo mang phong cách hiện đại
                        FadeInSlide(
                          delay: 0.1,
                          child: Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.fastfood_rounded, // Đổi icon cho "thực phẩm"
                                    size: 48,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Chào mừng trở lại!',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -1,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Đăng nhập để tiếp tục quản lý bếp ăn của bạn',
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withOpacity(0.7),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),

                        // Form Fields
                        FadeInSlide(
                          delay: 0.2,
                          child: CustomTextField(
                            label: 'Email',
                            hint: 'Nhập email của bạn',
                            controller: _emailController,
                            prefixIcon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeInSlide(
                          delay: 0.3,
                          child: CustomTextField(
                            label: 'Mật khẩu',
                            hint: '••••••••',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),

                        // Quên mật khẩu
                        FadeInSlide(
                          delay: 0.4,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                              ),
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Error Message (Animated)
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            if (auth.errorMessage == null) return const SizedBox.shrink();
                            return FadeInSlide(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade100),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_rounded, color: Colors.red.shade400, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        auth.errorMessage!,
                                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Nút Đăng nhập
                        FadeInSlide(
                          delay: 0.5,
                          child: Consumer<AuthProvider>(
                            builder: (context, auth, _) {
                              return PrimaryButton(
                                text: 'Đăng nhập',
                                isLoading: auth.isLoading,
                                onPressed: () => _handleLogin(auth),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Hoặc đăng nhập bằng (Divider)
                        FadeInSlide(
                          delay: 0.6,
                          child: Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  "Hoặc",
                                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 13),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Social Buttons
                        FadeInSlide(
                          delay: 0.7,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _socialButton(Icons.g_mobiledata_rounded, () {}),
                              const SizedBox(width: 20),
                              _socialButton(Icons.apple_rounded, () {}),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Footer
                        FadeInSlide(
                          delay: 0.8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Bạn mới sử dụng ứng dụng? ',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/register'),
                                child: const Text(
                                  'Đăng ký',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hỗ trợ: Vòng tròn mờ nền
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

  // Widget hỗ trợ: Nút mạng xã hội
  Widget _socialButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, size: 32, color: AppColors.textPrimary),
      ),
    );
  }

  void _handleLogin(AuthProvider auth) {
    if (_formKey.currentState!.validate()) {
      auth.login(_emailController.text, _passwordController.text).then((_) async {
        if (!mounted) return;

        if (auth.status == AuthStatus.authenticated) {
          // Đăng nhập thành công -> Vào Home
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (auth.isVerificationPending) {
          // CHƯA XÁC THỰC -> CHUYỂN ĐẾN MÀN HÌNH NHẬP OTP
          
          // Trước khi chuyển, gọi gửi lại mã để lấy verifyToken mới
          await auth.sendVerificationCode(_emailController.text); 
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                email: _emailController.text,
              ),
            ),
          );
        }
      });
    }
  }
}