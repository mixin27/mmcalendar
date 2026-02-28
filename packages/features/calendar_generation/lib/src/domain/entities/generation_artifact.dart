import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class GenerationArtifact extends Equatable {
  const GenerationArtifact({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;

  @override
  List<Object?> get props => [fileName, mimeType, bytes];
}
