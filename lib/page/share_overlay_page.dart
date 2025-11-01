import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notebook/server/note_service.dart';
import 'package:notebook/util/logger_service.dart';
import 'package:notebook/main.dart';

/// 透明的分享接收页面，显示在原应用上层
class ShareOverlayPage extends StatefulWidget {
  final String title;
  final String content;

  const ShareOverlayPage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  State<ShareOverlayPage> createState() => _ShareOverlayPageState();
}

class _ShareOverlayPageState extends State<ShareOverlayPage>
    with SingleTickerProviderStateMixin {
  static const String _tag = 'ShareOverlayPage';
  static const int _countdownSeconds = 3;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  Timer? _countdownTimer;
  int _remainingSeconds = _countdownSeconds;
  bool _isDetailDialogShown = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startCountdown();
    log.d(_tag, 'ShareOverlayPage initialized');
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // 淡入动画
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // 缩放动画
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // 滑动动画
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        if (!_isDetailDialogShown) {
          _closeOverlay();
        }
      }
    });
  }

  void _closeOverlay() {
    if (!mounted) return;

    log.d(_tag, 'Closing overlay');
    _animationController.reverse().then((_) {
      if (mounted) {
        // 通知原生关闭 Activity
        SystemNavigator.pop();
      }
    });
  }

  void _showDetailDialog() {
    if (_isDetailDialogShown) return;

    setState(() {
      _isDetailDialogShown = true;
    });

    _countdownTimer?.cancel();
    log.d(_tag, 'Showing detail dialog');

    final titleController = TextEditingController(text: widget.title);
    final contentController = TextEditingController(text: widget.content);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_note,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '编辑笔记',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _closeOverlay();
                      },
                    ),
                  ],
                ),
              ),
              // 内容区域
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: '标题',
                          hintText: '给你的笔记起个名字...',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: contentController,
                        decoration: InputDecoration(
                          labelText: '内容',
                          hintText: '记录你的想法...',
                          prefixIcon: const Icon(Icons.notes),
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        maxLines: 8,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              // 按钮区域
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _closeOverlay();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('取消', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final newTitle = titleController.text.trim();
                          final newContent = contentController.text.trim();

                          if (newTitle.isNotEmpty && newContent.isNotEmpty) {
                            final noteService = NoteService(isar);
                            await noteService.addOrUpdateNote(
                              title: newTitle,
                              content: newContent,
                            );
                            log.d(_tag, 'Note updated: $newTitle');
                          }

                          if (mounted) {
                            Navigator.of(context).pop();
                            _closeOverlay();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '保存',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
    ).then((_) {
      if (mounted && !_isDetailDialogShown) {
        _closeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.transparent,
        child: SafeArea(
          child: Stack(
            children: [
              // 点击背景区域也能关闭
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeOverlay,
                  behavior: HitTestBehavior.translucent,
                ),
              ),
              // 主要内容
              Positioned(
                left: 0,
                right: 0,
                bottom: 100,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 成功图标
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade400,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // 标题
                              const Text(
                                '已保存到笔记',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 内容预览
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              // 倒计时和按钮
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 倒计时
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$_remainingSeconds',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Detail 按钮
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _showDetailDialog,
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'Detail',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
