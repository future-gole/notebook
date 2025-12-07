import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NoteTagsSection extends StatelessWidget {
  final List<String> tags;
  final VoidCallback onAddTag;
  final Function(String) onRemoveTag;

  const NoteTagsSection({
    Key? key,
    required this.tags,
    required this.onAddTag,
    required this.onRemoveTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Text(
                '标签',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: colorScheme.secondary,
                ),
              ),
              const Spacer(),
              // 添加标签按钮
              TextButton.icon(
                onPressed: onAddTag,
                icon: Icon(
                  Icons.add_rounded,
                  size: 16.sp,
                  color: colorScheme.tertiary,
                ),
                label: Text(
                  '添加',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.tertiary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // 标签列表
          if (tags.isEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: Text(
                  '点击添加标签',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: colorScheme.secondary.withOpacity(0.6),
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: tags
                  .map((tag) => _buildTagChip(tag, colorScheme))
                  .toList(),
            ),
        ],
      ),
    );
  }

  /// 标签芯片
  Widget _buildTagChip(String tag, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: TextStyle(
              fontSize: 12.sp,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 6.w),
          GestureDetector(
            onTap: () => onRemoveTag(tag),
            child: Icon(
              Icons.close_rounded,
              size: 12.sp,
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
