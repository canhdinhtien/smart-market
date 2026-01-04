import 'dart:async';
import 'package:flutter/material.dart';

// Định nghĩa các hướng trượt
enum FadeInDirection { ttb, btt, ltr, rtl } // Top to Bottom, Bottom to Top, Left to Right, Right to Left

class FadeInSlide extends StatefulWidget {
  final Widget child;
  final double delay;
  final FadeInDirection direction;
  final double fadeOffset;
  final Duration duration;

  const FadeInSlide({
    super.key,
    required this.child,
    this.delay = 0,
    this.direction = FadeInDirection.btt, // Mặc định trượt từ dưới lên
    this.fadeOffset = 30.0,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Tính toán hướng trượt dựa trên enum
    Offset startOffset;
    switch (widget.direction) {
      case FadeInDirection.ttb:
        startOffset = Offset(0, -widget.fadeOffset);
        break;
      case FadeInDirection.btt:
        startOffset = Offset(0, widget.fadeOffset);
        break;
      case FadeInDirection.ltr:
        startOffset = Offset(-widget.fadeOffset, 0);
        break;
      case FadeInDirection.rtl:
        startOffset = Offset(widget.fadeOffset, 0);
        break;
    }

    _offset = Tween<Offset>(begin: startOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Xử lý delay
    if (widget.delay <= 0) {
      _controller.forward();
    } else {
      _timer = Timer(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _offset.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}