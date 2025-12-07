/// 响应式布局断点配置
/// 统一管理所有页面的断点判断
class ResponsiveBreakpoints {
  /// 移动端最大宽度
  static const double mobileMaxWidth = 600;
  
  /// 平板端最大宽度
  static const double tabletMaxWidth = 1024;
  
  /// 桌面端最小宽度
  static const double desktopMinWidth = 1024;
  
  /// 大桌面端最小宽度（宽屏）
  static const double largeDesktopMinWidth = 1440;

  /// 笔记详情页 - 显示侧边元信息栏的最小宽度
  static const double noteDetailSidebarMinWidth = 900;
  
  /// 首页 - 显示导航侧边栏的最小宽度
  static const double homeSidebarMinWidth = 768;

  /// 判断是否为移动端布局
  static bool isMobile(double width) => width < mobileMaxWidth;

  /// 判断是否为平板布局
  static bool isTablet(double width) => 
      width >= mobileMaxWidth && width < tabletMaxWidth;

  /// 判断是否为桌面端布局
  static bool isDesktop(double width) => width >= desktopMinWidth;

  /// 判断是否为大桌面端布局
  static bool isLargeDesktop(double width) => width >= largeDesktopMinWidth;

  /// 判断是否应该显示笔记详情页的侧边元信息栏
  static bool shouldShowNoteDetailSidebar(double width) => 
      width >= noteDetailSidebarMinWidth;

  /// 判断是否应该显示首页侧边导航栏
  static bool shouldShowHomeSidebar(double width) => 
      width >= homeSidebarMinWidth;

  /// 获取设备类型描述
  static String getDeviceType(double width) {
    if (isMobile(width)) return 'mobile';
    if (isTablet(width)) return 'tablet';
    if (isLargeDesktop(width)) return 'large_desktop';
    return 'desktop';
  }
}
