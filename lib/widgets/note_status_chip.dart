import 'package:flutter/material.dart';
import '../models/note_status.dart';

class NoteStatusChip extends StatelessWidget {
  final String status;

  const NoteStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = NoteStatus.color(status);
    return Chip(
      label: Text(
        NoteStatus.label(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
