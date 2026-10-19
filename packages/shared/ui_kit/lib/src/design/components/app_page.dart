import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// A page with a large title that shrinks into the bar on scroll.
///
/// Clear: an iOS large-title bar on the grouped background, with a back
/// label and accent-coloured actions. Material: a large top app bar.
/// Pass [children] for a padded list (spaced like grouped settings) or
/// [slivers] for anything else.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    this.children,
    this.slivers,
    this.actions = const [],
    this.previousTitle,
    this.floatingActionButton,
    this.largeTitle = true,
    this.spacing = 22,
  }) : assert(children != null || slivers != null);

  final String title;
  final List<Widget>? children;
  final List<Widget>? slivers;
  final List<Widget> actions;

  /// The back label in Clear ("Settings"); Material shows an arrow only.
  final String? previousTitle;
  final Widget? floatingActionButton;
  final bool largeTitle;

  /// Space between [children].
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final header = t.isClear ? _clearBar(context, t) : _materialBar(context);
    return Scaffold(
      backgroundColor: t.background,
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
        slivers: [
          header,
          if (children != null)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, t.isClear ? 8 : 4, 16, 32),
              sliver: SliverList.list(
                children: [
                  for (final (i, child) in children!.indexed) ...[
                    if (i > 0) SizedBox(height: spacing),
                    child,
                  ],
                ],
              ),
            ),
          ...?slivers,
        ],
      ),
    );
  }

  Widget _clearBar(BuildContext context, AppTokens t) {
    final trailing = actions.isEmpty
        ? null
        : IconTheme.merge(
            data: IconThemeData(color: t.accent, size: 24),
            child: Row(mainAxisSize: MainAxisSize.min, children: actions),
          );
    final border = Border(bottom: BorderSide(color: t.separator, width: .5));
    if (!largeTitle) {
      return SliverPersistentHeader(
        pinned: true,
        delegate: _BarDelegate(
          CupertinoNavigationBar(
            middle: Text(title),
            previousPageTitle: previousTitle,
            trailing: trailing,
            backgroundColor: t.bar,
            border: border,
            transitionBetweenRoutes: false,
          ),
          MediaQuery.paddingOf(context).top + kMinInteractiveDimensionCupertino,
        ),
      );
    }
    return CupertinoSliverNavigationBar(
      largeTitle: Text(title),
      previousPageTitle: previousTitle,
      trailing: trailing,
      backgroundColor: t.bar,
      border: border,
      transitionBetweenRoutes: false,
      stretch: true,
    );
  }

  /// One pinned row: the title sits beside the back button instead of
  /// below an empty toolbar, so pages start right under the status bar.
  /// Top-level pages ([largeTitle]) get a bigger title.
  Widget _materialBar(BuildContext context) => SliverAppBar(
    pinned: true,
    toolbarHeight: largeTitle ? 64 : kToolbarHeight,
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: largeTitle ? Theme.of(context).textTheme.headlineSmall : null,
    ),
    actions: actions,
  );
}

class _BarDelegate extends SliverPersistentHeaderDelegate {
  _BarDelegate(this.bar, this.height);
  final Widget bar;
  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) => bar;

  @override
  bool shouldRebuild(_BarDelegate old) =>
      old.bar != bar || old.height != height;
}
