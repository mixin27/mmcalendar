import 'package:flutter/material.dart';

enum CalendarGenerationQuickAction {
  sharePdf,
  savePdf,
  shareImages,
  saveImages,
  printPdf,
}

class CalendarGenerationAppBarActions extends StatelessWidget {
  const CalendarGenerationAppBarActions({
    required this.isProcessing,
    required this.onOpenOverlayEditor,
    required this.onQuickActionSelected,
    super.key,
  });

  final bool isProcessing;
  final VoidCallback onOpenOverlayEditor;
  final ValueChanged<CalendarGenerationQuickAction> onQuickActionSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: isProcessing ? null : onOpenOverlayEditor,
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit Overlays',
        ),
        PopupMenuButton<CalendarGenerationQuickAction>(
          enabled: !isProcessing,
          tooltip: 'Export actions',
          icon: const Icon(Icons.ios_share_outlined),
          onSelected: onQuickActionSelected,
          itemBuilder: (context) => const [
            PopupMenuItem<CalendarGenerationQuickAction>(
              value: CalendarGenerationQuickAction.sharePdf,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.picture_as_pdf),
                title: Text('Share PDF'),
              ),
            ),
            PopupMenuItem<CalendarGenerationQuickAction>(
              value: CalendarGenerationQuickAction.savePdf,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.save_alt_outlined),
                title: Text('Save PDF to folder'),
              ),
            ),
            PopupMenuItem<CalendarGenerationQuickAction>(
              value: CalendarGenerationQuickAction.shareImages,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.image_outlined),
                title: Text('Share images'),
              ),
            ),
            PopupMenuItem<CalendarGenerationQuickAction>(
              value: CalendarGenerationQuickAction.saveImages,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.folder_copy_outlined),
                title: Text('Save images to folder'),
              ),
            ),
            PopupMenuItem<CalendarGenerationQuickAction>(
              value: CalendarGenerationQuickAction.printPdf,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.print_outlined),
                title: Text('Print PDF'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
