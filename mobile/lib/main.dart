import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:pocketmind/page/home/home_screen.dart';
import 'package:pocketmind/service/notification_service.dart';
import 'package:pocketmind/page/home/settings_page.dart';
import 'package:pocketmind/providers/infrastructure_providers.dart';
import 'package:pocketmind/providers/shared_preferences_provider.dart';
import 'package:pocketmind/util/image_storage_helper.dart';
import 'package:pocketmind/util/proxy_config.dart';
import 'package:pocketmind/util/theme_data.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'model/category.dart';
import 'model/note.dart';
import 'lan_sync/model/sync_log.dart';
import 'data/repositories/isar_category_repository.dart';
import 'util/logger_service.dart';

// 这会强制构建系统将 main_share.dart 编译到应用中
// 防止另一个入口没有被引用
import 'package:pocketmind/main_share.dart';
late Isar isar;

const _uuid = Uuid();

/// 为旧数据迁移 UUID
///
/// 检查所有没有 UUID 的 Note 和 Category，为它们生成 UUID
/// 这是为了支持跨设备同步功能
Future<void> _migrateUuidsIfNeeded(Isar db) async {
  final tag = 'UuidMigration';

  await db.writeTxn(() async {
    // 迁移没有 UUID 的 Notes
    final notesWithoutUuid = await db.notes.filter().uuidIsNull().findAll();
    if (notesWithoutUuid.isNotEmpty) {
      PMlog.i(tag, 'Migrating ${notesWithoutUuid.length} notes without UUID');
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final note in notesWithoutUuid) {
        note.uuid = _uuid.v4();
        // 如果没有 updatedAt，使用 time 或当前时间
        if (note.updatedAt == 0) {
          note.updatedAt = note.time?.millisecondsSinceEpoch ?? now;
        }
      }
      await db.notes.putAll(notesWithoutUuid);
      PMlog.i(tag, 'Notes migration completed');
    }

    // 迁移没有 UUID 的 Categories
    final categoriesWithoutUuid = await db.categorys
        .filter()
        .uuidIsNull()
        .findAll();
    if (categoriesWithoutUuid.isNotEmpty) {
      PMlog.i(
        tag,
        'Migrating ${categoriesWithoutUuid.length} categories without UUID',
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final category in categoriesWithoutUuid) {
        category.uuid = _uuid.v4();
        // 如果没有 updatedAt，使用 createdTime 或当前时间
        if (category.updatedAt == 0) {
          category.updatedAt =
              category.createdTime?.millisecondsSinceEpoch ?? now;
        }
      }
      await db.categorys.putAll(categoriesWithoutUuid);
      PMlog.i(tag, 'Categories migration completed');
    }
  });
}

Future<void> main() async {
  // 确保 flutter 绑定初始化了
  WidgetsFlutterBinding.ensureInitialized();

  // 获取 SharedPreferences 实例用于 Provider
  final prefs = await SharedPreferences.getInstance();

  // 根据配置设置代理
  final proxyEnabled = prefs.getBool('proxy_enabled') ?? false;
  if (proxyEnabled) {
    final proxyHost = prefs.getString('proxy_host') ?? '127.0.0.1';
    final proxyPort = prefs.getInt('proxy_port') ?? 7890;
    HttpOverrides.global = GlobalHttpOverrides(
      '$proxyHost:$proxyPort',
      allowBadCertificates: true,
    );
  }

  // 获取一个可写目录
  final dir = await getApplicationDocumentsDirectory();
  // 打开 Isar 实例
  isar = await Isar.open([
    NoteSchema,
    CategorySchema,
    SyncLogSchema,
  ], directory: dir.path);

  // 确保初始化默认分类数据
  final categoryRepository = IsarCategoryRepository(isar);
  await categoryRepository.initDefaultCategories();

  // 为旧数据迁移 UUID（确保所有记录都有 UUID）
  await _migrateUuidsIfNeeded(isar);

  await ImageStorageHelper().init();
  final notificationSvc = NotificationService();
  await notificationSvc.init();
  runApp(
    // 使用 ProviderScope 包裹应用，并 override isarProvider
    // 后续都使用状态管理里面的isar
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notificationSvc),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;

        final double designWidth = isDesktop ? 1280 : 400;
        final double designHeight = isDesktop ? 720 : 869;
        return ScreenUtilInit(
          designSize: Size(designWidth, designHeight),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'PocketMind',
            theme: calmBeigeTheme,
            darkTheme: quietNightTheme,
            themeMode: ThemeMode.system,
            home: HomeScreen(),
            routes: {'/settings': (context) => const SettingsPage()},
          ),
        );
      },
    );
  }
}
