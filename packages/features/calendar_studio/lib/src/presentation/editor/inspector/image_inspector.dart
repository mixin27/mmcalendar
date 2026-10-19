import 'package:flutter/material.dart';

import '../../../models/calendar_studio_document.dart';
import '../../../theme/calendar_studio_theme.dart';
import 'studio_inspector_controls.dart';
import 'studio_inspector_host.dart';
import '../../calendar_studio_strings.dart';

/// Image and logo: the photo, its print quality, fit and frame.
class StudioImageInspector extends StatelessWidget {
  const StudioImageInspector({
    required this.block,
    required this.host,
    super.key,
  });
  final CalendarStudioBlock block;
  final StudioInspectorHost host;

  @override
  Widget build(BuildContext context) {
    final tokens = CalendarStudioTokens.of(context);
    final width = (block.content['pixelWidth'] as num?)?.toInt() ?? 0;
    final height = (block.content['pixelHeight'] as num?)?.toInt() ?? 0;
    final fit = block.style['imageFit'] as String? ?? 'crop';
    final opacity = (block.style['opacity'] as num?)?.toDouble() ?? 1;
    final requiredPixels = (block.bounds.width * 2480).clamp(1, 2480);
    final dpi = width == 0 ? 0 : (width / requiredPixels * 300).round();
    final goodQuality = dpi >= 240;
    final hasImage = block.content['assetId'] != null;
    final editImage = host.editImage;
    final removeBackground = host.removeBackground;
    final borderWidth = (block.style['borderWidth'] as num?)?.toDouble() ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tokens.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.image_outlined),
          ),
          title: Text(
            block.content['assetName'] as String? ?? StudioStrings.image,
          ),
          subtitle: Text('$width × $height px'),
          trailing: OutlinedButton(
            onPressed: () => host.replaceImage(block),
            child: const Text(StudioStrings.replace),
          ),
        ),
        if (hasImage &&
            (editImage != null ||
                removeBackground != null ||
                block.content['originalAssetId'] != null))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (editImage != null)
                  FilledButton.tonalIcon(
                    key: const ValueKey('calendar-studio-edit-image'),
                    onPressed: () => editImage(block),
                    icon: const Icon(Icons.auto_fix_high_outlined),
                    label: const Text(StudioStrings.editImage),
                  ),
                if (removeBackground != null)
                  FilledButton.tonalIcon(
                    key: const ValueKey('calendar-studio-remove-background'),
                    onPressed: () => removeBackground(block),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text(StudioStrings.removeBackground),
                  ),
                if (block.content['originalAssetId'] != null)
                  OutlinedButton.icon(
                    onPressed: () => host.revertImage(block),
                    icon: const Icon(Icons.restore),
                    label: const Text(StudioStrings.revertToOriginal),
                  ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.surface2,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  StudioStrings.printQuality,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                width == 0
                    ? StudioStrings.imageRequired
                    : goodQuality
                    ? StudioStrings.qualityGood(dpi)
                    : StudioStrings.qualityCheck(dpi),
                style: TextStyle(
                  color: goodQuality ? tokens.ok : tokens.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        StudioSection(
          title: StudioStrings.imageFit,
          children: [
            StudioSegmented<String>(
              segments: const [
                ('crop', StudioStrings.crop, null),
                ('fit', StudioStrings.imageFit, null),
                ('fill', StudioStrings.stretch, null),
              ],
              value: fit,
              onChanged: (value) => host.setStyle(block, 'imageFit', value),
            ),
            Row(
              children: [
                const SizedBox(width: 70, child: Text(StudioStrings.opacity)),
                Expanded(
                  child: Slider(
                    value: opacity.clamp(0, 1),
                    onChangeStart: (_) =>
                        host.controller.beginBlockInteraction(),
                    onChangeEnd: (_) => host.controller.endBlockInteraction(),
                    onChanged: (value) => host.controller.updateBlockLive(
                      block.copyWith(style: {...block.style, 'opacity': value}),
                    ),
                  ),
                ),
                SizedBox(width: 46, child: Text('${(opacity * 100).round()}%')),
              ],
            ),
          ],
        ),
        StudioSection(
          title: StudioStrings.frame,
          children: [
            StudioStepper(
              label: StudioStrings.cornerRadius,
              unit: 'px',
              value: (block.style['cornerRadius'] as num?)?.toDouble() ?? 0,
              max: 200,
              step: 2,
              onChanged: (value) => host.setStyle(block, 'cornerRadius', value),
            ),
            StudioStepper(
              label: StudioStrings.border,
              unit: 'px',
              value: borderWidth,
              max: 40,
              onChanged: (value) => host.setStyle(block, 'borderWidth', value),
            ),
            if (borderWidth > 0)
              StudioColorField(
                id: 'border',
                label: StudioStrings.borderColour,
                value: block.style['borderColor'] as int?,
                host: host,
                pageColors: host.pageColors(host.controller.currentPage),
                onChanged: (value) =>
                    host.setStyle(block, 'borderColor', value),
              ),
          ],
        ),
      ],
    );
  }
}
