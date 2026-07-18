import 'package:flutter/material.dart';

import '../models/enums.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final DocumentStatus status;

  Color get _color {
    switch (status) {
      case DocumentStatus.draft:
        return Colors.grey;
      case DocumentStatus.pendingApproval:
        return Colors.orange;
      case DocumentStatus.approved:
        return Colors.blue;
      case DocumentStatus.completed:
        return Colors.green;
      case DocumentStatus.rejected:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
