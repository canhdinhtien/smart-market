import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/custom_text_field.dart';
import '../../../../core/components/primary_button.dart';
import '../../../../core/components/fade_in_slide.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _codeController.dispose();
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
                          const SizedBox(height: 10),
                          
                          // Header
                          FadeInSlide(
                            delay: 0.1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đặt lại mật khẩu 🔒',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -1,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Nhập mã xác nhận đã được gửi đến ${widget.email} và mật khẩu mới của bạn.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withOpacity(0.8),
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Code Field
                          FadeInSlide(
                            delay: 0.2,
                            child: CustomTextField(
                              label: 'Mã xác nhận (OTP)',
                              hint: 'Nhập mã 6 chữ số',
                              controller: _codeController,
                              prefixIcon: Icons.pin_rounded,
                              keyboardType: TextInputType.number,
                              validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập mã OTP' : null,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          FadeInSlide(
                            delay: 0.3,
                            child: CustomTextField(
                              label: 'Mật khẩu mới',
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

                          // Confirm Password Field
                          FadeInSlide(
                            delay: 0.4,
                            child: CustomTextField(
                              label: 'Xác nhận mật khẩu',
                              hint: '••••••••',
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              prefixIcon: Icons.verified_user_outlined,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                              validator: (value) => (value != _passwordController.text) ? 'Mật khẩu không khớp' : null,
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
                            delay: 0.5,
                            child: Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                return PrimaryButton(
                                  text: 'Cập nhật mật khẩu',
                                  isLoading: auth.isLoading,
                                  onPressed: () => _handleReset(auth),
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

  void _handleReset(AuthProvider auth) async {
    if (_formKey.currentState!.validate()) {
      final success = await auth.resetPassword(
        widget.email,
        _codeController.text.trim(),
        _passwordController.text.trim(),
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mật khẩu đã được đặt lại thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        // Quay về login
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }
}
