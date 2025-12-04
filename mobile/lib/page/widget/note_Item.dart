import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketmind/providers/note_providers.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/service/note_service.dart';
import 'package:pocketmind/util/url_helper.dart';
import 'link_preview_card.dart';
import '../home/note_add_sheet.dart';
import '../home/note_detail_page.dart';
import 'package:pocketmind/util/link_preview_cache.dart';
import 'package:pocketmind/util/app_config.dart';
import 'load_image_widget.dart';

String tag = "noteItem";

// 改为 StatefulWidget 以支持 AutomaticKeepAliveClientMixin
class NoteItem extends ConsumerStatefulWidget {
  final NoteEntity note;
  final bool isGridMode;
  final bool isDesktop;

  final NoteService noteService;

  const NoteItem({
    required this.note,
    required this.noteService,
    required this.isGridMode,
    this.isDesktop = false,
    super.key,
  });

  @override
  ConsumerState<NoteItem> createState() => _NoteItemState();
}

class _NoteItemState extends ConsumerState<NoteItem>
    with AutomaticKeepAliveClientMixin {
  // 保持 widget 状态，避免滚动时被销毁重建
  @override
  bool get wantKeepAlive => true;

  final _config = AppConfig();
  bool _titleEnabled = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _loadTitleSetting();
  }

  Future<void> _loadTitleSetting() async {
    await _config.init();
    if (mounted) {
      setState(() {
        _titleEnabled = _config.titleEnabled;
      });
    }
  }

  // 显示笔记详情页
  void _showNoteDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteDetailPage(note: widget.note),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return date.toString().substring(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    // 必须调用 super.build，让 AutomaticKeepAliveClientMixin 工作
    super.build(context);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 判断是否为纯文本笔记
    final isTextOnly = widget.note.url == null ? true : false;
    final isHttpsUrl = UrlHelper.containsHttpsUrl(widget.note.url);
    final isLocalImage = UrlHelper.isLocalImagePath(widget.note.url);

    final content = widget.note.content;

    // 桌面端样式调整
    final margin = widget.isDesktop
        ? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0)
        : (widget.isGridMode
              ? const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0)
              : const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0));

    // 桌面端悬停效果
    final transform = widget.isDesktop && _isHovered
        ? Matrix4.identity().scaled(1.02)
        : Matrix4.identity();

    final shadow = widget.isDesktop && _isHovered
        ? [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 4),
            ),
          ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.2)
        : Colors.black.withOpacity(0.1);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: transform,
        transformAlignment: Alignment.center,
        margin: margin,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: shadow,
        ),
        child: InkWell(
          onTap: () => _showNoteDetail(context),
          borderRadius: BorderRadius.circular(16),
          child: isTextOnly
              // 1. 纯文本模式：
              ? Container(
                  // 给卡片一个最小高度，
                  constraints: const BoxConstraints(minHeight: 80.0),
                  padding: EdgeInsets.all(widget.isDesktop ? 24.0 : 16.0),
                  child: _titleEnabled && widget.note.title != null
                      // 启用标题且标题存在时，显示标题+内容
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 标题
                            Text(
                              widget.note.title!,
                              style: TextStyle(
                                fontSize: widget.isDesktop ? 22 : 20,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // 分割线
                            Divider(
                              color: colorScheme.primary.withOpacity(0.1),
                              thickness: 1,
                            ),
                            const SizedBox(height: 8),
                            // 内容
                            Text(
                              content ?? "",
                              style: TextStyle(
                                fontSize: widget.isDesktop ? 17 : 16,
                                fontWeight: FontWeight.w300,
                                color: colorScheme.onSurface,
                                height: 1.6,
                              ),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      // 不显示标题时，居中显示内容
                      : Center(
                          child: Text(
                            content ?? "",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: widget.isDesktop ? 26 : 25,
                              fontWeight: FontWeight.w300,
                              color: colorScheme.primary,
                              height: 1.7,
                            ),
                            maxLines: 8,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                )
              : isLocalImage
              // 2. 本地图片模式
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 图片部分
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: AspectRatio(
                        aspectRatio: widget.isGridMode ? 1.0 : 16 / 9,
                        child: LocalImageWidget(relativePath: widget.note.url!),
                      ),
                    ),
                    // 图片下面的文字部分
                    if (content != null && content.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.all(widget.isDesktop ? 16.0 : 12.0),
                        child: Text(
                          content,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: widget.isDesktop ? 15 : null,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                )
              : isHttpsUrl
              // 3. HTTPS 链接模式
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 链接卡片部分
                    LinkPreviewCard(
                      url: widget.note.url!,
                      isVertical: widget.isGridMode,
                      hasContent: content != null && content.isNotEmpty,
                      onTap: () => _showNoteDetail(context),
                      isDesktop: widget.isDesktop,
                      publishDate: _formatDate(widget.note.time),
                    ),
                    // 链接卡片下面的文字部分
                    if (content != null && content.isNotEmpty)
                      ...[
                      Divider(
                        color: colorScheme.outline,
                        thickness: 1.0,
                        height: 5.0,
                        indent: 12.0, // 左侧缩进
                        endIndent: 12.0, // 右侧缩进
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8),
                        child: Text(
                          content,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: widget.isDesktop ? 15 : null,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]
                  ],
                )
              // 4. 其他URL
              : Container(
                  padding: EdgeInsets.all(widget.isDesktop ? 24.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.note.url != null)
                        Text(
                          widget.note.url!,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (content != null && content.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          content,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: widget.isDesktop ? 15 : null,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
