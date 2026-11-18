import 'package:shared_core/shared_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

class PrivacyPolicyPage extends StatelessWidget {
  final String title;
  final String message;

  const PrivacyPolicyPage({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: title,
      previousTitle: 'About',
      largeTitle: false,
      slivers: [
        SliverFillRemaining(
          child: MarkdownRender(data: AppConstants.privacyPolicyMarkdown),
        ),
      ],
    );
  }
}
