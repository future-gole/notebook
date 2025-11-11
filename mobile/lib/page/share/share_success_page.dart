// 路径: lib/pages/share_success_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/providers/http_providers.dart';
import 'package:pocketmind/server/page_analysis_service.dart';
import 'package:pocketmind/util/logger_service.dart';

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
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _startCountdown();

    // // 如果有 URL，自动触发页面分析
    // if (widget.url != null && widget.url!.isNotEmpty) {
    //   _analyzePageAutomatically();
    // }
  }

  // /// 自动分析页面
  // Future<void> _analyzePageAutomatically() async {
  //   if (_isAnalyzing || widget.url == null) return;
  //
  //   setState(() {
  //     _isAnalyzing = true;
  //   });
  //
  //   try {
  //     log.d(_tag, "开始自动分析页面: ${widget.url}");
  //
  //     final pageAnalysisService = ref.read(pageAnalysisServiceProvider);
  //
  //     // 获取用户邮箱（这里需要根据你的实际情况获取）
  //     // 可以从 AppConfig 或用户登录信息中获取
  //     final userEmail = "double2z2@163.com"; // 临时硬编码，实际应该从配置中读取
  //
  //     final result = await pageAnalysisService.analyzePage(
  //       userQuery: "总结这个页面",
  //       url: widget.url!,
  //       userEmail: userEmail,
  //     );
  //
  //     log.d(_tag, "页面分析成功: ${result.summary}");
  //
  //     // 这里可以处理分析结果
  //     // 例如：显示一个 SnackBar 或更新 UI
  //     if (mounted) {
  //       _showAnalysisResult(result);
  //     }
  //   } catch (e) {
  //     log.e(_tag, "页面分析失败: $e");
  //     // 错误处理：可以显示错误提示
  //     if (mounted) {
  //       _showErrorMessage(e.toString());
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isAnalyzing = false;
  //       });
  //     }
  //   }
  // }
  //
  // /// 显示分析结果
  // void _showAnalysisResult(PageAnalysisResult result) {
  //   // 可以使用 SnackBar 或其他方式显示结果
  //   log.d(_tag, "显示分析结果: ${result.summary}");
  //   // TODO: 根据需求显示分析结果，例如添加到笔记内容中
  // }
  //
  // /// 显示错误信息
  // void _showErrorMessage(String message) {
  //   log.e(_tag, "显示错误信息: $message");
  //   // TODO: 显示错误提示
  // }

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
          "It's in your pocketmind.",
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
