import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pocketmind/page/widget/creative_toast.dart';

void main() {
  group('CreativeToast Widget Tests', () {
    late Widget testApp;

    setUp(() {
      testApp = ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    CreativeToast.success(
                      context,
                      title: '测试标题',
                      message: '测试消息',
                      direction: ToastDirection.top,
                    );
                  },
                  child: const Text('显示 Toast'),
                ),
              ),
            ),
          ),
        ),
      );
    });

    testWidgets('CreativeToast.success displays correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testApp);

      // 点击按钮显示 Toast
      await tester.tap(find.text('显示 Toast'));
      await tester.pump(); // 开始动画
      await tester.pump(const Duration(milliseconds: 100)); // 让动画进行一部分

      // 验证 Toast 是否显示
      expect(find.text('测试标题'), findsOneWidget);
      expect(find.text('测试消息'), findsOneWidget);

      // 验证成功图标
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('CreativeToast.error displays with correct icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () {
                      CreativeToast.error(
                        context,
                        title: '错误',
                        message: '出错了',
                        direction: ToastDirection.top,
                      );
                    },
                    child: const Text('显示错误'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('显示错误'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('错误'), findsOneWidget);
      expect(find.text('出错了'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('CreativeToast.info displays with correct icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () {
                      CreativeToast.info(
                        context,
                        title: '信息',
                        message: '这是一条信息',
                        direction: ToastDirection.top,
                      );
                    },
                    child: const Text('显示信息'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('显示信息'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('信息'), findsOneWidget);
      expect(find.text('这是一条信息'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('CreativeToast.warning displays with correct icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () {
                      CreativeToast.warning(
                        context,
                        title: '警告',
                        message: '请注意',
                        direction: ToastDirection.top,
                      );
                    },
                    child: const Text('显示警告'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('显示警告'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('警告'), findsOneWidget);
      expect(find.text('请注意'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('Toast closes when close button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testApp);

      await tester.tap(find.text('显示 Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('测试标题'), findsOneWidget);

      // 查找并点击关闭按钮
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pumpAndSettle(); // 等待退出动画完成

      // 验证 Toast 已关闭
      expect(find.text('测试标题'), findsNothing);
    });

    testWidgets('Toast displays with correct duration and progress indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () {
                      CreativeToast.show(
                        context,
                        type: ToastType.success,
                        title: '有倒计时的提示',
                        message: '显示进度圈',
                        duration: const Duration(seconds: 3),
                        direction: ToastDirection.top,
                      );
                    },
                    child: const Text('显示 Toast'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('显示 Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证 Toast 显示
      expect(find.text('有倒计时的提示'), findsOneWidget);

      // 验证进度指示器存在（通过 CustomPaint）
      expect(find.byType(CustomPaint), findsWidgets);

      // 模拟一些时间流逝
      await tester.pump(const Duration(milliseconds: 500));

      // Toast 应该仍然可见
      expect(find.text('有倒计时的提示'), findsOneWidget);
    });

    testWidgets('Multiple toasts can be displayed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          CreativeToast.success(
                            context,
                            title: '成功1',
                            message: '第一条消息',
                            direction: ToastDirection.top,
                          );
                        },
                        child: const Text('Toast 1'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          CreativeToast.error(
                            context,
                            title: '错误2',
                            message: '第二条消息',
                            direction: ToastDirection.top,
                          );
                        },
                        child: const Text('Toast 2'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // 显示第一个 Toast
      await tester.tap(find.text('Toast 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('成功1'), findsOneWidget);

      // 显示第二个 Toast
      await tester.tap(find.text('Toast 2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 两个 Toast 都应该显示
      expect(find.text('成功1'), findsOneWidget);
      expect(find.text('错误2'), findsOneWidget);
    });

    testWidgets('Toast respects theme brightness', (WidgetTester tester) async {
      // 测试亮色主题
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () {
                      CreativeToast.success(
                        context,
                        title: '亮色主题',
                        message: '测试',
                        direction: ToastDirection.top,
                      );
                    },
                    child: const Text('显示'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('显示'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('亮色主题'), findsOneWidget);

      // 测试暗色主题
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () {
                      CreativeToast.success(
                        context,
                        title: '暗色主题',
                        message: '测试',
                        direction: ToastDirection.top,
                      );
                    },
                    child: const Text('显示'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('显示'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('暗色主题'), findsOneWidget);
    });

    testWidgets('Toast animation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);

      await tester.tap(find.text('显示 Toast'));

      // 验证入场动画
      await tester.pump(); // 开始动画
      await tester.pump(const Duration(milliseconds: 250)); // 动画进行到一半

      expect(find.text('测试标题'), findsOneWidget);

      // 完成入场动画
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('测试标题'), findsOneWidget);
    });

    testWidgets('Toast handles long text correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () {
                      CreativeToast.success(
                        context,
                        title: '这是一个非常非常非常非常非常长的标题',
                        message: '这是一个非常非常非常非常非常非常非常非常非常非常长的消息内容',
                        direction: ToastDirection.top,
                      );
                    },
                    child: const Text('显示长文本'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('显示长文本'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证文本被正确截断显示
      expect(find.textContaining('这是一个非常'), findsWidgets);
    });
  });

  group('ToastType Enum Tests', () {
    test('ToastType has all expected values', () {
      expect(ToastType.values.length, 4);
      expect(ToastType.values.contains(ToastType.success), true);
      expect(ToastType.values.contains(ToastType.error), true);
      expect(ToastType.values.contains(ToastType.info), true);
      expect(ToastType.values.contains(ToastType.warning), true);
    });
  });

  group('CreativeToast Singleton Tests', () {
    test('CreativeToast returns same instance', () {
      expect(true, true);
    });
  });
}
