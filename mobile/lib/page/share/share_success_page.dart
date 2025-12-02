// 路径: lib/pages/share_success_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:pocketmind/providers/http_providers.dart';
import 'package:pocketmind/service/page_analysis_service.dart';
import 'package:pocketmind/util/logger_service.dart';
import 'package:pocketmind/util/theme_data.dart' show sharePageColors, SharePageThemeColors;

final String _tag = "ShareSuccessPage";

class ShareSuccessPage extends ConsumerStatefulWidget {

  final VoidCallback onDismiss;
  final VoidCallback onAddDetailsClicked;

  const ShareSuccessPage({
    super.key,
    required this.onDismiss,
    required this.onAddDetailsClicked,
  });

  @override
  ConsumerState<ShareSuccessPage> createState() => _ShareSuccessPageState();
}

class _ShareSuccessPageState extends ConsumerState<ShareSuccessPage>
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
    final shareColors = Theme.of(context).extension<SharePageThemeColors>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo/Icon - 使用点睛色
        Lottie.asset(
          'assets/lottie/success.json',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
          repeat: false,
          animate: true,
        ),
        const SizedBox(height: 24),

        // 主标题
        Text(
          "Good find!",
          style: TextStyle(
            color: shareColors?.primary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),

        // 副标题
        Text(
          "It's in your pocketmind.",
          style: TextStyle(
            color: shareColors?.secondary,
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
            decoration: BoxDecoration(
              // 设置边框
              border: Border.all(
                color: shareColors?.secondary ?? Colors.white,
                width: 1.0, // 边框的宽度
              ),
              // 设置圆角
              borderRadius: BorderRadius.circular(30.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              "Add Details",
              style: TextStyle(
                color: shareColors?.secondary,
                fontSize: 16,
                fontFamily: "Poppins",
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
              width: MediaQuery.of(context).size.width * _progressController.value,
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
