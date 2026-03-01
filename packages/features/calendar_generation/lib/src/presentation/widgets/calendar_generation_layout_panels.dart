import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../domain/entities/calendar_generation_mode.dart';
import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_page_model.dart';
import '../../domain/entities/calendar_page_orientation.dart';
import 'calendar_generation_preview_page.dart';
import 'calendar_generation_ui_sections.dart';

class CalendarGenerationSettingsLauncherCard extends StatelessWidget {
  const CalendarGenerationSettingsLauncherCard({
    required this.onGeneralTap,
    required this.onLayoutTap,
    required this.onVisibilityTap,
    required this.onThemeTap,
    required this.onBackgroundTap,
    required this.onTemplateTap,
    super.key,
  });

  final VoidCallback onGeneralTap;
  final VoidCallback onLayoutTap;
  final VoidCallback onVisibilityTap;
  final VoidCallback onThemeTap;
  final VoidCallback onBackgroundTap;
  final VoidCallback onTemplateTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              'Open a group to edit calendar generation options.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SettingsGroupButton(
                  icon: Icons.tune,
                  label: 'General',
                  onTap: onGeneralTap,
                ),
                SettingsGroupButton(
                  icon: Icons.aspect_ratio,
                  label: 'Layout',
                  onTap: onLayoutTap,
                ),
                SettingsGroupButton(
                  icon: Icons.visibility_outlined,
                  label: 'Visibility',
                  onTap: onVisibilityTap,
                ),
                SettingsGroupButton(
                  icon: Icons.palette_outlined,
                  label: 'Theme',
                  onTap: onThemeTap,
                ),
                SettingsGroupButton(
                  icon: Icons.image_outlined,
                  label: 'Background',
                  onTap: onBackgroundTap,
                ),
                SettingsGroupButton(
                  icon: Icons.bookmarks_outlined,
                  label: 'Templates',
                  onTap: onTemplateTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarGenerationPreviewSummaryCard extends StatelessWidget {
  const CalendarGenerationPreviewSummaryCard({
    required this.request,
    required this.pages,
    required this.previewOrientation,
    required this.activePage,
    required this.syncPreviewOrientationToExport,
    required this.onPreviewOrientationChanged,
    required this.onSyncPreviewOrientationChanged,
    super.key,
  });

  final CalendarGenerationRequest request;
  final List<CalendarPageModel> pages;
  final CalendarPageOrientation previewOrientation;
  final CalendarPageModel? activePage;
  final bool syncPreviewOrientationToExport;
  final ValueChanged<CalendarPageOrientation> onPreviewOrientationChanged;
  final ValueChanged<bool> onSyncPreviewOrientationChanged;

  @override
  Widget build(BuildContext context) {
    final isYearMode = request.mode == CalendarGenerationMode.year;
    final sectionTitle = isYearMode
        ? 'Year Preview (${pages.length} pages)'
        : 'Month Preview';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sectionTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PreviewMetaChip(
                  icon: Icons.language_outlined,
                  text: request.language.name.capitalize,
                ),
                PreviewMetaChip(
                  icon: Icons.view_day_outlined,
                  text: switch (request.mode) {
                    CalendarGenerationMode.month => 'Month',
                    CalendarGenerationMode.year => 'Year',
                  },
                ),
              ],
            ),
            if (activePage != null && isYearMode) ...[
              const SizedBox(height: 6),
              Text(
                activePage!.westernTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Preview Orientation',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<CalendarPageOrientation>(
                showSelectedIcon: false,
                segments: CalendarPageOrientation.values
                    .map(
                      (orientation) => ButtonSegment<CalendarPageOrientation>(
                        value: orientation,
                        label: Text(orientation.label),
                      ),
                    )
                    .toList(growable: false),
                selected: <CalendarPageOrientation>{previewOrientation},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) {
                    return;
                  }
                  onPreviewOrientationChanged(selection.first);
                },
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sync preview orientation with export setting',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Switch.adaptive(
                  value: syncPreviewOrientationToExport,
                  onChanged: onSyncPreviewOrientationChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarGenerationPreviewWorkspace extends StatelessWidget {
  const CalendarGenerationPreviewWorkspace({
    required this.pages,
    required this.previewPage,
    required this.previewPageController,
    required this.previewRequest,
    required this.previewCanvasSize,
    required this.onPageChanged,
    required this.onGoToPage,
    super.key,
  });

  final List<CalendarPageModel> pages;
  final int previewPage;
  final PageController previewPageController;
  final CalendarGenerationRequest previewRequest;
  final Size previewCanvasSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onGoToPage;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: previewPageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pages.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) => _PreviewCanvasCard(
                pages: pages,
                index: index,
                previewRequest: previewRequest,
                previewCanvasSize: previewCanvasSize,
              ),
            ),
          ),
          if (pages.length > 1)
            _PreviewPageNavigation(
              pages: pages,
              previewPage: previewPage,
              onGoToPage: onGoToPage,
            ),
        ],
      ),
    );
  }
}

class _PreviewPageNavigation extends StatelessWidget {
  const _PreviewPageNavigation({
    required this.pages,
    required this.previewPage,
    required this.onGoToPage,
  });

  final List<CalendarPageModel> pages;
  final int previewPage;
  final ValueChanged<int> onGoToPage;

  @override
  Widget build(BuildContext context) {
    final safePage = previewPage.clamp(0, pages.length - 1);
    final currentTitle = pages[safePage].westernTitle;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          FilledButton.tonalIcon(
            onPressed: previewPage > 0
                ? () => onGoToPage(previewPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Page ${safePage + 1} / ${pages.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    currentTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: previewPage < pages.length - 1
                ? () => onGoToPage(previewPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }
}

class _PreviewCanvasCard extends StatelessWidget {
  const _PreviewCanvasCard({
    required this.pages,
    required this.index,
    required this.previewRequest,
    required this.previewCanvasSize,
  });

  final List<CalendarPageModel> pages;
  final int index;
  final CalendarGenerationRequest previewRequest;
  final Size previewCanvasSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: InteractiveViewer(
            constrained: true,
            boundaryMargin: const EdgeInsets.all(80),
            minScale: 1.0,
            maxScale: 4.0,
            panEnabled: true,
            scaleEnabled: true,
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: SizedBox(
                  width: previewCanvasSize.width,
                  height: previewCanvasSize.height,
                  child: CalendarGenerationPreviewPage(
                    model: pages[index],
                    request: previewRequest,
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    contentPadding: const EdgeInsets.all(12),
                    useCardChrome: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
