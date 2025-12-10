import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/page/widget/hero_gallery.dart';
import 'package:pocketmind/util/image_storage_helper.dart';
import 'package:pocketmind/util/url_helper.dart';
import 'note_link_content_section.dart';
import 'note_source_link_card.dart';

class NoteOriginalDataSection extends StatelessWidget {
  final NoteEntity note;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final VoidCallback onCategoryPressed;
  final String categoryName;
  final String formattedDate;
  final String? previewImageUrl;
  final String? previewTitle;
  final String? previewDescription;
  final bool isLoadingPreview;
  final VoidCallback onSave;
  final Function(String) onLaunchUrl;
  final bool isDesktop;
  final bool titleEnabled;

  const NoteOriginalDataSection({
    super.key,
    required this.note,
    required this.titleController,
    required this.contentController,
    required this.onCategoryPressed,
    required this.categoryName,
    required this.formattedDate,
    this.previewImageUrl,
    this.previewTitle,
    this.previewDescription,
    required this.isLoadingPreview,
    required this.onSave,
    required this.onLaunchUrl,
    required this.isDesktop,
    required this.titleEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isLocalImage = UrlHelper.isLocalImagePath(note.url);
    final isHttpsUrl = UrlHelper.containsHttpsUrl(note.url);
    final hasTitle =
        titleEnabled && note.title != null && note.title!.isNotEmpty;

    // 收集可显示的图片
    List<String> displayImages = [];
    bool isNetworkImage = false;

    // 只有本地图片才使用 getFileByRelativePath
    if (isLocalImage && note.url != null) {
      final fullPath = ImageStorageHelper()
          .getFileByRelativePath(note.url!)
          .path;
      displayImages.add(fullPath);
    }

    // 如果是网络链接且预览图已加载，使用预览图
    if (isHttpsUrl && !isLocalImage) {
      isNetworkImage = true;
      if (previewImageUrl != null && previewImageUrl!.isNotEmpty) {
        displayImages.add(previewImageUrl!);
      }
    }

    final hasImages = displayImages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 图片/画廊区域
        if (hasImages) ...[
          HeroGallery(
            images: displayImages,
            title: hasTitle ? note.title! : '',
            isDesktop: isDesktop,
            showGradientFade: true,
            categoryLabel: categoryName,
            dateLabel: formattedDate,
            overlayTitle: previewTitle ?? '',
          ),
        ] else if (isNetworkImage && isLoadingPreview) ...[
          // 加载中显示占位
          Container(
            height: isDesktop ? 0.35.sh : 0.25.sh,
            color: colorScheme.surfaceContainerHighest,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],

        // 内容容器
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 无图时显示分类和日期
              if (!hasImages && !isLoadingPreview) ...[
                SizedBox(height: 24.h),
                // 分类标签和日期
                Row(
                  children: [
                    // 分类胶囊 - 可点击切换分类
                    GestureDetector(
                      onTap: onCategoryPressed,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: colorScheme.tertiary,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.expand_more_rounded,
                              size: 14.sp,
                              color: colorScheme.tertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // 日期
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12.sp,
                          color: colorScheme.secondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // 标题（无图时）
                if (hasTitle) ...[
                  TextField(
                    controller: titleController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      letterSpacing: -0.5,
                      color: colorScheme.onSurface,
                    ),
                    onChanged: (_) => onSave(),
                  ),
                  SizedBox(height: 16.h),
                  // 装饰线
                  Container(
                    width: 60.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ],

              // 网络链接时显示链接标题和正文（来自预览数据）
              if (isHttpsUrl) ...[
                NoteLinkContentSection(
                  previewDescription: previewDescription,
                  contentController: contentController,
                  onSave: onSave,
                ),
              ],

              // 用户笔记区（个人笔记）
              if (!isHttpsUrl) ...[
                // 非链接类型时，content 就是用户内容
                TextField(
                  controller: contentController,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: '记录你的想法...',
                    hintStyle: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.secondary.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 16.sp,
                    height: 1.8,
                    letterSpacing: 0.2,
                    color: colorScheme.onSurface,
                  ),
                  onChanged: (_) => onSave(),
                ),
              ],

              SizedBox(height: 24.h),

              // 来源链接卡片（仅移动端或无侧边栏时显示）
              if (isHttpsUrl && !isDesktop && note.url != null) ...[
                NoteSourceLinkCard(
                  url: note.url!,
                  isHttpsUrl: isHttpsUrl,
                  onTap: () => onLaunchUrl(note.url!),
                ),
                SizedBox(height: 16.h),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
