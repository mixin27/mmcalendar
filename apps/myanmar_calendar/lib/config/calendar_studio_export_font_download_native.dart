import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where the web app serves `/export-fonts/`; unset builds export text in
/// Studio's variable fonts as images.
const _baseUrl = String.fromEnvironment('STUDIO_EXPORT_FONTS_URL');

/// Fetches a generated export font once and keeps it in app support.
Future<Uint8List?> downloadCalendarStudioExportFont(String fileName) async {
  final root = await getApplicationSupportDirectory();
  final file = File(
    p.join(root.path, 'calendar_studio', 'export_fonts', fileName),
  );
  if (await file.exists()) return file.readAsBytes();
  if (_baseUrl.isEmpty) return null;
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse(_baseUrl).resolve('export-fonts/$fileName'),
    );
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) return null;
    final bytes = await _consolidate(response);
    await file.parent.create(recursive: true);
    // Written whole, then renamed, so a cut-off download never sticks.
    final partial = File('${file.path}.part');
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(file.path);
    return bytes;
  } catch (_) {
    return null;
  } finally {
    client.close();
  }
}

Future<Uint8List> _consolidate(Stream<List<int>> response) async {
  final builder = BytesBuilder(copy: false);
  await response.forEach(builder.add);
  return builder.takeBytes();
}
