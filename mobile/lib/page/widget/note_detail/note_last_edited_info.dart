import 'package:flutter/material.dart';

class NoteLastEditedInfo extends StatelessWidget {
  final String formattedDate;

  const NoteLastEditedInfo({Key? key, required this.formattedDate})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      'Last edited on $formattedDate',
      style: TextStyle(
        fontSize: 12,
        fontStyle: FontStyle.italic,
        color: colorScheme.secondary.withValues(alpha: 0.7),
      ),
    );
  }
}
