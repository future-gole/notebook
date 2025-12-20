/// 日期格式化工具类
class DateFormatter {
  DateFormatter._();

  /// 格式化日期为中文格式（相对时间）
  ///
  /// - 今天：显示"今天 HH:mm"
  /// - 昨天：显示"昨天 HH:mm"
  /// - 7天内：显示"N天前"
  /// - 7天以上：显示"YYYY年M月D日"
  static String formatChinese(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.year}年${date.month}月${date.day}日';
    }
  }
}
