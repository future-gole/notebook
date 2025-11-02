// 路径: lib/pages/share_success_page.dart
import 'dart:async';
import 'dart:ui'; // ⬅️ 1. 导入
import 'package:flutter/material.dart';

class ShareSuccessPage extends StatefulWidget {
  final String title;
  final String content;
  final VoidCallback onDismiss; // 添加 onDismiss 回调

  const ShareSuccessPage({
    super.key,
    required this.title,
    required this.content,
    required this.onDismiss,
  });

  @override
  _ShareSuccessPageState createState() => _ShareSuccessPageState();
}

class _ShareSuccessPageState extends State<ShareSuccessPage> {
  Timer? _countdownTimer; // 加回倒计时

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  // ⬅️ 4. 加回倒计时逻辑
  void startCountdown() {
    _countdownTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onDismiss(); // 3秒到，调用回调以“隐藏”
      }
    });
  }

  void _onDetailClicked() {
    _countdownTimer?.cancel(); // 用户交互，取消倒计时

    // 导航到“编辑”页面
    Navigator.of(context).pushNamed(
      '/editNote',
      arguments: {
        'title': widget.title,
        'content': widget.content,
      },
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel(); // ⬅️ 6. 销毁
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      // ⬅️ 7. 添加模糊和遮罩
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withOpacity(0.1), // 半透明遮罩
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //todo logo
                Icon(Icons.lightbulb_outline, color: Colors.white, size: 30),
                SizedBox(height: 20),
                Text(
                  "Good find!",
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  "It's in your notebook.",
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 24),
                ),
                SizedBox(height: 40),
                // "Add Details" 按钮
                OutlinedButton.icon(
                  icon: Icon(Icons.add, size: 18),
                  label: Text("Add Details"),
                  onPressed: _onDetailClicked,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}