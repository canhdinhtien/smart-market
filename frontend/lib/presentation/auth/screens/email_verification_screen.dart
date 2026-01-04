import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Thêm thư viện này để giới hạn nhập số
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/primary_button.dart';
import '../../../../core/components/fade_in_slide.dart';
import '../providers/auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  int _resendCodeTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Tự động mở bàn phím khi vào màn hình
    Future.delayed(const Duration(milliseconds: 500), () {
      _focusNode.requestFocus();
    });
  }

  void _startResendTimer() {
    setState(() => _resendCodeTimer = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCodeTimer > 0) {
        setState(() => _resendCodeTimer--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -size.width * 0.2,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInSlide(
                    delay: 0.1,
                    child: const Center(
                      child: Icon(Icons.mark_email_unread_rounded, size: 80, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeInSlide(
                    delay: 0.2,
                    child: Column(
                      children: [
                        Text('Xác thực Email',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        Text('Nhập mã 6 chữ số đã gửi tới\n${widget.email}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // PHẦN QUAN TRỌNG: 6 Ô NHẬP MÃ OTP
                  FadeInSlide(
                    delay: 0.3,
                    child: Stack(
                      children: [
                        // TextField ẩn để xử lý nhập liệu
                        Opacity(
                          opacity: 0,
                          child: TextFormField(
                            controller: _codeController,
                            focusNode: _focusNode,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            onChanged: (value) {
                              setState(() {}); // Rebuild để cập nhật các ô số
                              if (value.length == 6) {
                                // Tự động gọi verify khi đủ 6 số
                                _handleVerify(context.read<AuthProvider>());
                              }
                            },
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(counterText: ""),
                          ),
                        ),
                        // Hiển thị 6 ô số giả
                        GestureDetector(
                          onTap: () => _focusNode.requestFocus(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) => _buildOtpBox(index)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),
                  FadeInSlide(
                    delay: 0.4,
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return PrimaryButton(
                          text: 'Xác nhận',
                          isLoading: auth.isLoading,
                          onPressed: () => _handleVerify(auth),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInSlide(
                    delay: 0.5,
                    child: Column(
                      children: [
                        Text('Bạn chưa nhận được mã?', style: TextStyle(color: AppColors.textSecondary)),
                        TextButton(
                          onPressed: _resendCodeTimer > 0 ? null : () => _handleResendCode(),
                          child: Text(
                            _resendCodeTimer > 0 ? 'Gửi lại mã sau ${_resendCodeTimer}s' : 'Gửi lại mã ngay',
                            style: TextStyle(
                              color: _resendCodeTimer > 0 ? Colors.grey : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget vẽ từng ô số
  Widget _buildOtpBox(int index) {
    String char = "";
    if (_codeController.text.length > index) {
      char = _codeController.text[index];
    }

    bool isFocused = _codeController.text.length == index;
    if (index == 5 && _codeController.text.length == 6) isFocused = true;

    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: isFocused ? AppColors.primary.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? AppColors.primary : Colors.grey.shade200,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
    );
  }

  void _handleVerify(AuthProvider auth) {
    if (_codeController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ 6 số')));
      return;
    }
    auth.verifyEmail(_codeController.text.trim()).then((_) {
      if (auth.errorMessage == null && !auth.isVerificationPending) {
        _showSuccessDialog();
      }
    });
  }

  void _handleResendCode() {
    Provider.of<AuthProvider>(context, listen: false).sendVerificationCode(widget.email);
    _startResendTimer();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            const SizedBox(height: 20),
            const Text('Xác thực thành công!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: 'Đăng nhập ngay',
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ),
          ],
        ),
      ),
    );
  }
}