import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';

class CalendarStudioIssue {
  const CalendarStudioIssue({
    required this.severity,
    required this.title,
    required this.detail,
    this.pageId,
    this.blockId,
  });
  final CalendarStudioIssueSeverity severity;
  final String title;
  final String detail;
  final String? pageId;
  final String? blockId;
}

abstract final class CalendarStudioPreflight {
  static List<CalendarStudioIssue> check(CalendarStudioProject project) {
    final issues = <CalendarStudioIssue>[];
    for (final page in project.pages) {
      for (final block in page.blocks.where((value) => value.visible)) {
        final bounds = block.bounds;
        if (bounds.left < 0 ||
            bounds.top < 0 ||
            bounds.right > 1 ||
            bounds.bottom > 1) {
          issues.add(
            CalendarStudioIssue(
              severity: CalendarStudioIssueSeverity.error,
              title: '${block.name} is outside the page',
              detail: 'Move or resize it inside the canvas before exporting.',
              pageId: page.id,
              blockId: block.id,
            ),
          );
        }
        if (block.type == CalendarStudioBlockType.image &&
            (block.content['assetId'] == null)) {
          issues.add(
            CalendarStudioIssue(
              severity: CalendarStudioIssueSeverity.error,
              title: 'Missing image',
              detail: 'Replace the image before exporting.',
              pageId: page.id,
              blockId: block.id,
            ),
          );
        }
        if ((block.type == CalendarStudioBlockType.image ||
                block.type == CalendarStudioBlockType.logo) &&
            block.content['assetId'] != null &&
            page.canvas.width <= 500) {
          final sourceWidth = block.content['pixelWidth'] as int? ?? 0;
          final requiredWidth = page.canvas.width * bounds.width / 25.4 * 300;
          if (sourceWidth > 0 && sourceWidth < requiredWidth * .8) {
            issues.add(
              CalendarStudioIssue(
                severity: CalendarStudioIssueSeverity.warning,
                title: '${block.name} may look soft in print',
                detail:
                    'Use an image at least ${requiredWidth.round()} px wide for 300 dpi output.',
                pageId: page.id,
                blockId: block.id,
              ),
            );
          }
        }
        if (block.type == CalendarStudioBlockType.text &&
            ((block.content['text'] as String?)?.trim().isEmpty ?? true)) {
          issues.add(
            CalendarStudioIssue(
              severity: CalendarStudioIssueSeverity.warning,
              title: 'Empty text block',
              detail: 'It will not appear in the exported calendar.',
              pageId: page.id,
              blockId: block.id,
            ),
          );
        }
        if (bounds.left < page.canvas.safeInset ||
            bounds.top < page.canvas.safeInset ||
            bounds.right > 1 - page.canvas.safeInset ||
            bounds.bottom > 1 - page.canvas.safeInset) {
          issues.add(
            CalendarStudioIssue(
              severity: CalendarStudioIssueSeverity.warning,
              title: '${block.name} is near the edge',
              detail: 'Keep important content within the safe area for print.',
              pageId: page.id,
              blockId: block.id,
            ),
          );
        }
      }
    }
    if (issues.isEmpty) {
      issues.add(
        const CalendarStudioIssue(
          severity: CalendarStudioIssueSeverity.tip,
          title: 'Ready to export',
          detail: 'All pages pass the Studio preflight check.',
        ),
      );
    }
    return issues;
  }
}
