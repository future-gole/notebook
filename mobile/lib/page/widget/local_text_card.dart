import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'package:pocketmind/util/app_config.dart';
import 'source_info.dart';

/// 本地纯文本笔记卡片组件
class LocalTextCard extends StatefulWidget {
  final NoteEntity note;
  final bool isDesktop;

  const LocalTextCard({
    Key? key,
    required this.note,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  State<LocalTextCard> createState() => _LocalTextCardState();
}

class _LocalTextCardState extends State<LocalTextCard> {
  final _config = AppConfig();
  bool _titleEnabled = false;

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          // 给卡片一个最小高度
          constraints: BoxConstraints(minHeight: 80.w),
          padding: EdgeInsets.all(widget.isDesktop ? 24.w : 16.w),
          child: _titleEnabled && widget.note.title != null
              // 启用标题且标题存在时，显示标题+内容
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      widget.note.title!,
                      style: TextStyle(
                        fontSize: widget.isDesktop ? 22.sp : 20.sp,
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
                      widget.note.content ?? "",
                      style: TextStyle(
                        fontSize: widget.isDesktop ? 17.sp : 16.sp,
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
                    widget.note.content ?? "",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: widget.isDesktop ? 26.sp : 25.sp,
                      fontWeight: FontWeight.w300,
                      color: colorScheme.primary,
                      height: 1.7,
                    ),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        ),
        Padding(
          padding: EdgeInsets.all(widget.isDesktop ? 24.w : 16.w),
          child: SourceInfo(
            isLocal: true,
            publishDate: widget.note.time != null
                ? DateFormat('yyyy-MM-dd').format(widget.note.time!)
                : null,
          ),
        ),
      ],
    );
  }
}