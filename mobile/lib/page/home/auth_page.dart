import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pocketmind/page/widget/creative_toast.dart';
import 'package:pocketmind/page/widget/pm_app_bar.dart';
import 'package:pocketmind/providers/auth_providers.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _submitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      CreativeToast.error(
        context,
        title: '信息不完整',
        message: '请输入用户名和密码',
        direction: ToastDirection.bottom,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final notifier = ref.read(authControllerProvider.notifier);
      if (_isLoginMode) {
        await notifier.login(username: username, password: password);
        if (mounted) {
          CreativeToast.success(
            context,
            title: '登录成功',
            message: '已完成登录',
            direction: ToastDirection.bottom,
          );
        }
      } else {
        await notifier.register(username: username, password: password);
        if (mounted) {
          CreativeToast.success(
            context,
            title: '注册成功',
            message: '已完成注册并登录',
            direction: ToastDirection.bottom,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CreativeToast.error(
          context,
          title: '操作失败',
          message: e.toString(),
          direction: ToastDirection.bottom,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PMAppBar(title: Text('账号')),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          Card(
            color: theme.cardColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.isLoggedIn ? '已登录' : '未登录',
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    session.isLoggedIn
                        ? '用户ID：${session.userId ?? ''}'
                        : '未登录时依然可以使用全部本地功能。登录后将启用后端资源抓取/分析能力。',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (session.isLoggedIn) ...[
                    SizedBox(height: 12.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _submitting
                            ? null
                            : () => ref
                                  .read(authControllerProvider.notifier)
                                  .logout(),
                        child: const Text('退出登录'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),
          if (!session.isLoggedIn) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _isLoginMode = true),
                    child: Text(
                      '登录',
                      style: TextStyle(
                        fontWeight: _isLoginMode
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _isLoginMode = false),
                    child: Text(
                      '注册',
                      style: TextStyle(
                        fontWeight: !_isLoginMode
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Card(
              color: theme.cardColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  children: [
                    TextField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '用户名',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: '密码',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: Text(_isLoginMode ? '登录' : '注册'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
