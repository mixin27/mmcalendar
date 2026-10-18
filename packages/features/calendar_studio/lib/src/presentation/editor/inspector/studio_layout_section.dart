import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/calendar_studio_document.dart';
import 'studio_inspector_controls.dart';
import 'studio_inspector_host.dart';

/// Position, size, rotation and layer settings, shared by every block.
class StudioLayoutSection extends StatelessWidget {
  const StudioLayoutSection({
    required this.block,
    required this.host,
    super.key,
  });
  final CalendarStudioBlock block;
  final StudioInspectorHost host;

  @override
  Widget build(BuildContext context) {
    final w = host.designSize.width;
    final h = host.designSize.height;
    final b = block.bounds;
    void bounds(double left, double top, double width, double height) =>
        host.update(
          block.copyWith(
            bounds: b.copyWith(
              width: width.clamp(4 / w, 1),
              height: height.clamp(4 / h, 1),
              left: left.clamp(0, 1 - width.clamp(4 / w, 1)),
              top: top.clamp(0, 1 - height.clamp(4 / h, 1)),
            ),
          ),
        );
    final apply = host.applyToAllPages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSection(
          title: 'Position and size',
          children: [
            StudioStepper(
              label: 'X',
              unit: 'px',
              value: b.left * w,
              max: w,
              onChanged: (v) => bounds(v / w, b.top, b.width, b.height),
            ),
            StudioStepper(
              label: 'Y',
              unit: 'px',
              value: b.top * h,
              max: h,
              onChanged: (v) => bounds(b.left, v / h, b.width, b.height),
            ),
            StudioStepper(
              label: 'Width',
              unit: 'px',
              value: b.width * w,
              min: 4,
              max: w,
              onChanged: (v) => bounds(b.left, b.top, v / w, b.height),
            ),
            StudioStepper(
              label: 'Height',
              unit: 'px',
              value: b.height * h,
              min: 4,
              max: h,
              onChanged: (v) => bounds(b.left, b.top, b.width, v / h),
            ),
            StudioStepper(
              label: 'Rotation',
              unit: '°',
              value: block.rotation * 180 / math.pi,
              min: -180,
              max: 180,
              step: 5,
              onChanged: (v) =>
                  host.update(block.copyWith(rotation: v * math.pi / 180)),
            ),
          ],
        ),
        StudioSection(
          title: 'Layer',
          children: [
            StudioSwitch(
              label: 'Lock layer',
              value: block.locked,
              onChanged: (v) => host.update(block.copyWith(locked: v)),
            ),
            StudioSwitch(
              label: 'Visible',
              value: block.visible,
              onChanged: (v) => host.update(block.copyWith(visible: v)),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => host.controller.moveSelectedLayer(1),
                    icon: const Icon(Icons.flip_to_front_outlined),
                    label: const Text('Forward'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => host.controller.moveSelectedLayer(-1),
                    icon: const Icon(Icons.flip_to_back_outlined),
                    label: const Text('Back'),
                  ),
                ),
              ],
            ),
            if (apply != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('studio-apply-layout-all'),
                onPressed: () => apply(block, layout: true),
                icon: const Icon(Icons.library_add_check_outlined),
                label: const Text('Use this size and place on every month'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
