import 'package:flutter/material.dart';

/// Hộp thoại nhập lý do, dùng cho Từ chối / Huỷ phiếu. Trả về null nếu người
/// dùng bấm Huỷ bỏ, hoặc chuỗi lý do (không rỗng) nếu xác nhận.
Future<String?> showReasonDialog(
  BuildContext context, {
  required String title,
  required String actionLabel,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Lý do', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Huỷ bỏ'),
        ),
        FilledButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isEmpty) return;
            Navigator.of(dialogContext).pop(text);
          },
          child: Text(actionLabel),
        ),
      ],
    ),
  );
}
