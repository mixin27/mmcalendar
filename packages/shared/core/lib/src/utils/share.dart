import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

Future<void> share({
  String? title,
  String? content,
  String? subject,
  List<XFile>? files,

  /// The names [files] get in the share sheet; on phones a file made from
  /// bytes is otherwise unnamed.
  List<String>? fileNameOverrides,
  Uri? uri,
}) async {
  final params = ShareParams(
    title: title,
    text: content,
    subject: subject,
    files: files,
    fileNameOverrides: fileNameOverrides,
    uri: uri,
  );
  final result = await SharePlus.instance.share(params);
  if (result.status == ShareResultStatus.dismissed) {
    debugPrint('Did you not like the pictures?');
  }
}
