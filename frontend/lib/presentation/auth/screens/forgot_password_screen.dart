import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/custom_text_field.dart';
import '../../../../core/components/primary_button.dart';
import '../../../../core/components/fade_in_slide.dart';
import '../providers/auth_provider.dart';
import './reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decor
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
                // Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
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
                          const SizedBox(height: 20),
                          
                          // Header
                          FadeInSlide(
                            delay: 0.1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quên mật khẩu? 🔑',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -1,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Đừng lo lắng! Nhập email của bạn và chúng tôi sẽ gửi mã xác nhận để đặt lại mật khẩu.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withOpacity(0.8),
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Email Field
                          FadeInSlide(
                            delay: 0.2,
                            child: CustomTextField(
                              label: 'Email',
                              hint: 'Nhập email của bạn',
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

                          const SizedBox(height: 32),

                          // Error Message
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

                          // Submit Button
                          FadeInSlide(
                            delay: 0.3,
                            child: Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                return PrimaryButton(
                                  text: 'Gửi mã xác nhận',
                                  isLoading: auth.isLoading,
                                  onPressed: () => _handleSubmit(auth),
                                );
                              },
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
        ],
      ),
    );
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

  void _handleSubmit(AuthProvider auth) async {
    if (_formKey.currentState!.validate()) {
      final success = await auth.forgotPassword(_emailController.text.trim());
      if (success && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    }
  }
}
