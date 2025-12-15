import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/widget_preview_generator.dart';

class WidgetPreviewScreen extends StatefulWidget {
  const WidgetPreviewScreen({super.key});

  @override
  State<WidgetPreviewScreen> createState() => _WidgetPreviewScreenState();
}

class _WidgetPreviewScreenState extends State<WidgetPreviewScreen> {
  final _generator = WidgetPreviewGenerator();
  Map<String, String> _previewPaths = {};
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Previews'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isGenerating ? null : () => _generatePreviews(context),
            tooltip: 'Regenerate Previews',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _previewPaths.isEmpty ? null : _copyToAndroid,
            tooltip: 'Copy to Android',
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _previewPaths.isEmpty ? null : _copyToShareable,
            tooltip: 'Save to Downloads',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _previewPaths.isEmpty
          ? FloatingActionButton.extended(
              onPressed: _isGenerating
                  ? null
                  : () => _generatePreviews(context),
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.image),
              label: Text(
                _isGenerating ? 'Generating...' : 'Generate Previews',
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildError();
    }

    if (_isGenerating) {
      return _buildGenerating();
    }

    if (_previewPaths.isEmpty) {
      return _buildEmpty();
    }

    return _buildPreviewGrid();
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No previews generated yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to generate widget previews',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGenerating() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Generating widget previews...', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error Generating Previews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewGrid() {
    final widgetTypes = [
      WidgetTypeInfo(
        key: 'compact',
        name: 'Compact Date',
        description: '2x1 or 2x2',
        size: '250x110 dp',
      ),
      WidgetTypeInfo(
        key: 'full_calendar',
        name: 'Full Calendar',
        description: '4x2 or 4x3',
        size: '450x250 dp',
      ),
      WidgetTypeInfo(
        key: 'moon_phase',
        name: 'Moon Phase',
        description: '2x2',
        size: '180x180 dp',
      ),
      WidgetTypeInfo(
        key: 'myanmar_month',
        name: 'Myanmar Month',
        description: '4x4',
        size: '450x450 dp',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Success message
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Previews Generated Successfully',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to copy to Android resources',
                      style: TextStyle(fontSize: 14, color: Colors.green[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Preview cards
        ...widgetTypes.map((widget) {
          final previewPath = _previewPaths[widget.key];
          return _PreviewCard(
            widget: widget,
            previewPath: previewPath,
            onViewFullscreen: () => _viewFullscreen(previewPath!),
          );
        }),
      ],
    );
  }

  Future<void> _generatePreviews(BuildContext context) async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final previews = await _generator.generateAllPreviews(context);

      setState(() {
        _previewPaths = previews;
        _isGenerating = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All previews generated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = e.toString();
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Copy previews to a shareable location
  Future<Map<String, String>> copyPreviewsToShareable(
    Map<String, String> previews,
  ) async {
    try {
      debugPrint('📋 Preparing previews for sharing...');

      final Map<String, String> shareablePaths = {};

      // Get external storage directory (accessible to user)
      Directory? externalDir;

      if (Platform.isAndroid) {
        // Use Downloads directory on Android
        externalDir = Directory('/storage/emulated/0/Download/widget_previews');
      } else if (Platform.isIOS) {
        // Use Documents directory on iOS
        externalDir = await getApplicationDocumentsDirectory();
      }

      if (externalDir == null) {
        throw Exception('Could not find shareable directory');
      }

      // Create directory if it doesn't exist
      if (!await externalDir.exists()) {
        await externalDir.create(recursive: true);
      }

      for (final entry in previews.entries) {
        final sourceFile = File(entry.value);
        if (!await sourceFile.exists()) {
          debugPrint('⚠️ Preview file not found: ${entry.value}');
          continue;
        }

        // Copy to shareable location
        final destPath = '${externalDir.path}/${entry.key}.png';
        final destFile = await sourceFile.copy(destPath);

        shareablePaths[entry.key] = destFile.path;
        debugPrint('✅ Copied ${entry.key} to ${destFile.path}');
      }

      debugPrint(
        '✅ All previews copied to shareable location: ${externalDir.path}',
      );
      return shareablePaths;
    } catch (e) {
      debugPrint('❌ Error copying previews: $e');
      rethrow;
    }
  }

  Future<void> _copyToAndroid() async {
    try {
      await _generator.copyPreviewsToAndroid(_previewPaths);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Previews copied to Android resources'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error copying: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyToShareable() async {
    try {
      final shareablePaths = await _generator.copyPreviewsToShareable(
        _previewPaths,
      );

      final firstPath = shareablePaths.values.first;
      final directory = firstPath.substring(0, firstPath.lastIndexOf('/'));

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Previews Ready'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Previews have been saved to:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    directory,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'To use these previews:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Open your project folder\n'
                  '2. Navigate to android/app/src/main/res/drawable/\n'
                  '3. Copy the PNG files from the location above\n'
                  '4. Paste them into the drawable folder',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              if (Platform.isAndroid)
                ElevatedButton.icon(
                  onPressed: () async {
                    // Open file manager at the location
                    await Clipboard.setData(ClipboardData(text: directory));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📋 Path copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Path'),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewFullscreen(String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenPreview(imagePath: imagePath),
      ),
    );
  }
}

class WidgetTypeInfo {
  final String key;
  final String name;
  final String description;
  final String size;

  WidgetTypeInfo({
    required this.key,
    required this.name,
    required this.description,
    required this.size,
  });
}

class _PreviewCard extends StatelessWidget {
  final WidgetTypeInfo widget;
  final String? previewPath;
  final VoidCallback onViewFullscreen;

  const _PreviewCard({
    required this.widget,
    required this.previewPath,
    required this.onViewFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.widgets, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.description} • ${widget.size}',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: previewPath != null ? onViewFullscreen : null,
                  tooltip: 'View Fullscreen',
                ),
              ],
            ),
          ),

          // Preview Image
          if (previewPath != null)
            InkWell(
              onTap: onViewFullscreen,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 300),
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Center(
                  child: Image.file(File(previewPath!), fit: BoxFit.contain),
                ),
              ),
            )
          else
            Container(
              height: 100,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),

          // Footer with path
          if (previewPath != null)
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      previewPath!.split('/').last,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: previewPath!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Path copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    tooltip: 'Copy Path',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FullscreenPreview extends StatelessWidget {
  final String imagePath;

  const _FullscreenPreview({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          imagePath.split('/').last,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(child: Image.file(File(imagePath))),
      ),
    );
  }
}
