import 'package:flutter/material.dart';

import '../../../core/strings/diary_strings.dart';
import '../relog/relog_screen.dart';
import '../review/review_meal_screen.dart';

/// Bottom sheet mở từ nút Quét (FAB) ở giữa thanh điều hướng.
class ScanOptionsSheet {
  ScanOptionsSheet._();

  static Future<void> show(BuildContext context) {
    // [context] là của MainShell, vẫn còn sống sau khi đóng sheet.
    void openAfterClose(BuildContext sheetContext, void Function() action) {
      Navigator.pop(sheetContext);
      action();
    }

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ScanSheetStrings.title, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 8),
              _Option(
                icon: Icons.replay,
                title: ScanSheetStrings.relog,
                subtitle: ScanSheetStrings.relogSub,
                onTap: () => openAfterClose(
                  sheetContext,
                  () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const RelogScreen())),
                ),
              ),
              _Option(
                icon: Icons.edit_note,
                title: ScanSheetStrings.manual,
                subtitle: ScanSheetStrings.manualSub,
                onTap: () => openAfterClose(
                  sheetContext,
                  () => ReviewMealScreen.openManual(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Icon(icon, color: scheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
