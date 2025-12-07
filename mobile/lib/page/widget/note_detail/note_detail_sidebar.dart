import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pocketmind/domain/entities/note_entity.dart';
import 'note_ai_insight_section.dart';
import 'note_source_section.dart';
import 'note_tags_section.dart';
import 'note_last_edited_info.dart';

class NoteDetailSidebar extends StatelessWidget {
  final NoteEntity note;
  final Function(String) onLaunchUrl;
  final List<String> tags;
  final VoidCallback onAddTag;
  final Function(String) onRemoveTag;
  final String formattedDate;

  const NoteDetailSidebar({
    Key? key,
    required this.note,
    required this.onLaunchUrl,
    required this.tags,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.formattedDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI 洞察区
        const NoteAIInsightSection(),

        SizedBox(height: 32.h),

        // 来源信息
        NoteSourceSection(note: note, onLaunchUrl: onLaunchUrl),

        SizedBox(height: 24.h),

        // 标签区
        NoteTagsSection(
          tags: tags,
          onAddTag: onAddTag,
          onRemoveTag: onRemoveTag,
        ),

        SizedBox(height: 24.h),

        // 最后编辑时间
        NoteLastEditedInfo(formattedDate: formattedDate),
      ],
    );
  }
}
