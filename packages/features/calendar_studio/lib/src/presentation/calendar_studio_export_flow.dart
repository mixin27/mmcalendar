import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import '../services/calendar_studio_contracts.dart';
import '../theme/calendar_studio_theme.dart';
import '../widgets/calendar_studio_scene.dart';

enum StudioExportStage { rendering, delivering, done, failed }

/// State of one export, shown by [StudioExportFlow] (round-2 mockups 8–9).
class StudioExportRun extends ChangeNotifier {
  StudioExportRun({
    required this.project,
    required this.pages,
    required this.preset,
    required this.destination,
  });
  final CalendarStudioProject project;
  final List<CalendarStudioPage> pages;
  final CalendarStudioExportPreset preset;
  final CalendarStudioExportDestination destination;

  var stage = StudioExportStage.rendering;
  var completed = 0;
  CalendarStudioExportArtifact? artifact;
  String? message;

  /// Destinations already completed (the chosen one, then any extra
  /// Share/Print/Save from the done screen).
  final delivered = <CalendarStudioExportDestination>{};

  void progress(int value) {
    completed = value;
    notifyListeners();
  }

  void delivering(CalendarStudioExportArtifact value) {
    artifact = value;
    completed = pages.length;
    stage = StudioExportStage.delivering;
    notifyListeners();
  }

  void done(CalendarStudioExportDestination destination) {
    delivered.add(destination);
    stage = StudioExportStage.done;
    message = null;
    notifyListeners();
  }

  void failed(String value) {
    stage = StudioExportStage.failed;
    message = value;
    notifyListeners();
  }

  void note(String value) {
    message = value;
    notifyListeners();
  }
}

/// Export progress and result: thumbnails fill in page by page, then a short
/// page-stack animation confirms the file and offers the other actions.
class StudioExportFlow extends StatelessWidget {
  const StudioExportFlow({
    required this.run,
    required this.onCancel,
    required this.onDeliver,
    this.dataProvider,
    this.assetStore,
    super.key,
  });
  final StudioExportRun run;
  final VoidCallback onCancel;
  final Future<void> Function(CalendarStudioExportDestination) onDeliver;
  final CalendarStudioDataProvider? dataProvider;
  final CalendarStudioAssetStore? assetStore;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: run,
    builder: (context, _) => PopScope(
      canPop:
          run.stage == StudioExportStage.done ||
          run.stage == StudioExportStage.failed,
      child: Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              child: switch (run.stage) {
                StudioExportStage.done => _done(context),
                StudioExportStage.failed => _failed(context),
                _ => _rendering(context),
              },
            ),
          ),
        ),
      ),
    ),
  );

  Widget _thumbnail(CalendarStudioPage page) => IgnorePointer(
    child: CalendarStudioScene(
      page: page,
      source: run.project.source,
      dataProvider: dataProvider,
      assetStore: assetStore,
    ),
  );

  Widget _rendering(BuildContext context) {
    final tokens = CalendarStudioTokens.of(context);
    final total = run.pages.length;
    final current = math.min(run.completed, total - 1);
    final label = run.stage == StudioExportStage.delivering
        ? 'Finishing ${run.preset.format.label}…'
        : 'Rendering ${run.pages[current].label} · ${run.preset.label} · '
              '${run.preset.dpi} dpi';
    return Column(
      key: const ValueKey('rendering'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox.square(
            dimension: 132,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(end: total == 0 ? 0 : run.completed / total),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 240),
                  builder: (_, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 12,
                    backgroundColor: tokens.surface3,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${math.min(run.completed + 1, total)}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        'of $total page${total == 1 ? '' : 's'}',
                        style: TextStyle(fontSize: 12, color: tokens.ink3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Exporting your calendar',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.ink3),
        ),
        const SizedBox(height: 18),
        // Rows of six cells (a fixed strip, so no lazy grid is needed).
        Column(
          spacing: 6,
          children: [
            for (var start = 0; start < run.pages.length; start += 6)
              Row(
                spacing: 6,
                children: [
                  for (var i = start; i < start + 6; i++)
                    Expanded(
                      child: i >= run.pages.length
                          ? const SizedBox()
                          : AspectRatio(
                              aspectRatio: run.pages[i].canvas.aspectRatio
                                  .clamp(.5, 1.5),
                              child: _PageCell(
                                key: ValueKey('export-cell-$i'),
                                semanticLabel: run.pages[i].label,
                                label: run.pages[i].label.substring(
                                  0,
                                  math.min(3, run.pages[i].label.length),
                                ),
                                state: i < run.completed
                                    ? _CellState.done
                                    : i == run.completed
                                    ? _CellState.now
                                    : _CellState.pending,
                                thumbnail: i < run.completed
                                    ? _thumbnail(run.pages[i])
                                    : null,
                              ),
                            ),
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 18),
        Center(
          child: OutlinedButton(
            onPressed: run.stage == StudioExportStage.rendering
                ? onCancel
                : null,
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  Widget _done(BuildContext context) {
    final tokens = CalendarStudioTokens.of(context);
    final artifact = run.artifact!;
    final megabytes = artifact.bytes.length / (1 << 20);
    final size = megabytes >= .1
        ? '${megabytes.toStringAsFixed(1)} MB'
        : '${(artifact.bytes.length / 1024).ceil()} KB';
    final count = run.pages.length;
    final what = switch (run.destination) {
      CalendarStudioExportDestination.save => 'Saved',
      CalendarStudioExportDestination.share => 'Shared',
      CalendarStudioExportDestination.print => 'Sent to print',
    };
    final pdf = run.preset.format.isPdf;
    Widget action(
      CalendarStudioExportDestination destination,
      String label,
      IconData icon,
    ) => Expanded(
      child: FilledButton.tonalIcon(
        onPressed: run.delivered.contains(destination)
            ? null
            : () => onDeliver(destination),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
    return Column(
      key: const ValueKey('done'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PageStack(
          pages: [for (final page in run.pages.take(3)) _thumbnail(page)],
        ),
        const SizedBox(height: 14),
        Text(
          'Exported $count page${count == 1 ? '' : 's'}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          run.message ?? what,
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.ink3),
        ),
        const SizedBox(height: 14),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            title: Text(
              artifact.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${run.preset.format.label} · $count page${count == 1 ? '' : 's'} · $size'
              '${artifact.note == null ? '' : '\n${artifact.note}'}',
            ),
            trailing: const Icon(Icons.check_circle, color: Color(0xFF1E8A57)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          spacing: 8,
          children: [
            action(
              CalendarStudioExportDestination.save,
              'Save',
              Icons.save_alt_outlined,
            ),
            action(
              CalendarStudioExportDestination.share,
              'Share',
              Icons.share_outlined,
            ),
            if (pdf)
              action(
                CalendarStudioExportDestination.print,
                'Print',
                Icons.print_outlined,
              ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const ValueKey('calendar-studio-export-done'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to editing'),
        ),
      ],
    );
  }

  Widget _failed(BuildContext context) => Column(
    key: const ValueKey('failed'),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Icon(
        Icons.error_outline,
        size: 48,
        color: CalendarStudioTokens.of(context).error,
      ),
      const SizedBox(height: 12),
      Text(
        "Couldn't export the calendar",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      if (run.message case final message?)
        Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    ],
  );
}

enum _CellState { pending, now, done }

class _PageCell extends StatefulWidget {
  const _PageCell({
    required this.label,
    required this.semanticLabel,
    required this.state,
    this.thumbnail,
    super.key,
  });
  final String label;
  final String semanticLabel;
  final _CellState state;
  final Widget? thumbnail;

  @override
  State<_PageCell> createState() => _PageCellState();
}

class _PageCellState extends State<_PageCell>
    with SingleTickerProviderStateMixin {
  late final _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _PageCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate =
        widget.state == _CellState.now &&
        !MediaQuery.disableAnimationsOf(context);
    if (animate && !_shimmer.isAnimating) {
      _shimmer.repeat();
    } else if (!animate && _shimmer.isAnimating) {
      _shimmer.stop();
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CalendarStudioTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final cell = switch (widget.state) {
      _CellState.done => KeyedSubtree(
        key: const ValueKey('done'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: widget.thumbnail,
        ),
      ),
      _CellState.now => AnimatedBuilder(
        key: const ValueKey('now'),
        animation: _shimmer,
        builder: (_, _) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: primary, width: 2),
            gradient: LinearGradient(
              begin: Alignment(-1 + _shimmer.value * 3, 0),
              end: Alignment(_shimmer.value * 3, 0),
              colors: [tokens.surface2, tokens.surface, tokens.surface2],
            ),
          ),
          child: const SizedBox.expand(),
        ),
      ),
      _CellState.pending => DecoratedBox(
        key: const ValueKey('pending'),
        decoration: BoxDecoration(
          color: tokens.surface2,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: tokens.line),
        ),
        child: const SizedBox.expand(),
      ),
    };
    return Semantics(
      label: switch (widget.state) {
        _CellState.done => '${widget.semanticLabel} rendered',
        _CellState.now => '${widget.semanticLabel} rendering',
        _CellState.pending => '${widget.semanticLabel} waiting',
      },
      excludeSemantics: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            layoutBuilder: (current, previous) =>
                Stack(fit: StackFit.expand, children: [...previous, ?current]),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: .92, end: 1.0).animate(animation),
                child: child,
              ),
            ),
            child: cell,
          ),
          if (widget.state != _CellState.done)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Three exported pages fan out, then a check lands (mockup 9). Static when
/// the platform asks for reduced motion.
class _PageStack extends StatelessWidget {
  const _PageStack({required this.pages});
  final List<Widget> pages;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: 150,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduce ? 1 : 0, end: 1),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 700),
        curve: const Cubic(.2, .8, .2, 1),
        builder: (context, t, _) => Stack(
          alignment: Alignment.center,
          children: [
            for (var i = pages.length - 1; i >= 0; i--)
              Transform.translate(
                offset: Offset((i == 0 ? 0 : (i == 1 ? -18 : 18)) * t, 0),
                child: Transform.rotate(
                  angle: (i == 0 ? 0 : (i == 1 ? -.16 : .14)) * t,
                  child: SizedBox(
                    width: 92,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: pages[i],
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 4,
              left: 120,
              child: Opacity(
                opacity: ((t - .6) / .4).clamp(0, 1),
                child: Transform.scale(
                  scale: .6 + .4 * ((t - .6) / .4).clamp(0, 1),
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFF1E8A57),
                    child: Icon(Icons.check, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
