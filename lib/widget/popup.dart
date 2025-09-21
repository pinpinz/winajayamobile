import 'package:flutter/material.dart';

Future<void> showAnimatedBottomSheet({
  required BuildContext context,
  required String title,
  required List<Map<String, dynamic>> options,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return AnimatedPadding(
        padding: MediaQuery.of(context).viewInsets,
        duration: const Duration(milliseconds: 150),
        curve: Curves.decelerate,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...options.map((opt) {
              return ListTile(
                leading: opt['icon'],
                title: Text(opt['label']),
                onTap: () {
                  if (opt['onTap'] != null) {
                    opt['onTap'](
                        sheetContext); // ✅ sheetContext hanya untuk popup
                  }
                },
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}
