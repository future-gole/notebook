// 路径: lib/pages/share_success_page.dart
import 'dart:async';
import 'package:flutter/material.dart';

class ShareSuccessPage extends StatefulWidget {
  final String title;
  final String content;
  final VoidCallback onDismiss;
  final VoidCallback onAddDetailsClicked;

  const ShareSuccessPage({
    super.key,
    required this.title,
    required this.content,
    required this.onDismiss,
    required this.onAddDetailsClicked,
  });

  @override
  State<ShareSuccessPage> createState() => _ShareSuccessPageState();
}

class _ShareSuccessPageState extends State<ShareSuccessPage>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _startCountdown();
  }

  void _startCountdown() {
    _progressController.forward();
    _countdownTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  void _onUserInteraction() {
    _countdownTimer?.cancel();
    _progressController.stop();
    widget.onAddDetailsClicked();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo/Icon - 使用点睛色
        Icon(
          Icons.check_circle_outline,
          color: colorScheme.surfaceContainerHighest, // 点睛色
          size: 48,
        ),
        const SizedBox(height: 24),

        // 主标题
        Text(
          "Good find!",
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),

        // 副标题
        Text(
          "It's in your notebook.",
          style: TextStyle(
            color: colorScheme.secondary,
            fontSize: 24,
            fontWeight: FontWeight.normal,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 48),

        // "Add Details" 文本按钮
        GestureDetector(
          onTap: _onUserInteraction,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              "Add Details",
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 进度条 - 极细的线 - 使用点睛色
        AnimatedBuilder(
          animation: _progressController,
          builder: (context, child) {
            return Container(
              height: 2,
              width: 150 * _progressController.value,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest, // 点睛色
                borderRadius: BorderRadius.circular(1),
              ),
            );
          },
        ),
      ],
    );
  }
}
