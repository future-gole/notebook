import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
/// 构建通用的文本输入框
/// [expands] 为 true 时，输入框会尝试填满父容器高度（需要父容器有固定高度限制，如 Expanded）
class MyTextField extends StatelessWidget{

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.colorScheme,
    this.maxLines = 1,
    this.autofocus = false,
    this.expands = false,
    this.padding = const EdgeInsets.all(20),
    });

  final TextEditingController controller;
  final String hintText;
  final ColorScheme colorScheme;
  final EdgeInsetsGeometry padding;

  final int? maxLines;

  final bool autofocus;

  final bool expands;


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: colorScheme.secondary, fontSize: 16),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface,
          height: 1.5,
        ),
        // 当 expands 为 true 时，maxLines 必须为 null，minLines 必须为 null
        maxLines: expands ? null : maxLines,
        minLines: null,
        expands: expands,
        textAlignVertical: expands
            ? TextAlignVertical.top
            : TextAlignVertical.center,
        autofocus: autofocus,
      ),
    );
  }
}