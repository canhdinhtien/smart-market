import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/primary_button.dart';
import '../../../../core/components/fade_in_slide.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Decor (Tạo các khối màu nghệ thuật)
          Positioned(
            top: -size.height * 0.1,
            right: -size.width * 0.2,
            child: _buildCircle(AppColors.primary.withOpacity(0.1), size.width * 0.8),
          ),
          Positioned(
            top: size.height * 0.1,
            left: -size.width * 0.1,
            child: _buildCircle(AppColors.primary.withOpacity(0.05), size.width * 0.4),
          ),

          // 2. Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Hình ảnh minh họa hoặc Logo lớn
                  FadeInSlide(
                    delay: 0.2,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded, // Icon đại diện cho ẩm thực
                        size: 100,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Tên ứng dụng & Slogan
                  FadeInSlide(
                    delay: 0.4,
                    child: Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: -1,
                                ),
                            children: const [
                              TextSpan(text: 'Food'),
                              TextSpan(
                                text: 'Y',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Trợ lý thông minh cho việc đi chợ, nấu nướng và quản lý thực phẩm hàng ngày.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary.withOpacity(0.8),
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Nhóm nút bấm hành động
                  FadeInSlide(
                    delay: 0.6,
                    child: Column(
                      children: [
                        PrimaryButton(
                          text: 'Đăng nhập ngay',
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                        ),
                        const SizedBox(height: 16),
                        _buildSecondaryButton(
                          context,
                          'Tạo tài khoản mới',
                          () => Navigator.pushNamed(context, '/register'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hỗ trợ: Vòng tròn trang trí nền
  Widget _buildCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  // Widget hỗ trợ: Nút phụ (Outlined) phong cách hiện đại
  Widget _buildSecondaryButton(BuildContext context, String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: Colors.black,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}