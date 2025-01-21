import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_aws_s3service/flutter_aws_s3service.dart';
import 'package:flutter_aws_s3service_example/config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const AwsS3Demo(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
    );
  }
}

class AwsS3Demo extends StatefulWidget {
  const AwsS3Demo({super.key});

  @override
  State<AwsS3Demo> createState() => _AwsS3DemoState();
}

class _AwsS3DemoState extends State<AwsS3Demo> {
  // AWS Configuration
  final String bucket = bucketName;
  final String identity = identityPoolId;
  final String region = awsRegion;

  List<String> _files = [];
  String? _lastUploadedUrl;
  String? _errorMessage;
  String _platformVersion = 'Unknown';
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _getPlatformVersion();
    _refreshFileList();
  }

  Future<void> _getPlatformVersion() async {
    String? version;
    try {
      version = await FlutterAwsS3service.platformVersion;
    } on PlatformException {
      version = 'Failed to get platform version.';
    }
    if (!mounted) return;

    setState(() {
      _platformVersion = version ?? 'Unknown';
    });
  }

  Future<void> _refreshFileList() async {
    try {
      setState(() {
        _errorMessage = null;
        _files = []; // Clear current files while loading
      });

      final files = await FlutterAwsS3service.listFiles(
        bucket,
        identity,
        '', // prefix
        region,
        region,
      );

      setState(() {
        _files = files;
        _errorMessage = null;
      });
    } catch (e) {
      print('Error listing files: $e');
      setState(() {
        _errorMessage = 'Failed to list files: ${e.toString()}';
        _files = []; // Clear files on error
      });
    }
  }

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        final file = File(result.files.single.path!);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';

        final url = await FlutterAwsS3service.upload(
          file.path,
          bucket,
          identity,
          fileName,
          region,
          region,
        );

        if (url != null) {
          setState(() {
            _lastUploadedUrl = url;
            _errorMessage = null;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('File uploaded successfully!'),
                    SelectableText(url, style: TextStyle(fontSize: 12)),
                  ],
                ),
                duration: Duration(seconds: 10),
                action: SnackBarAction(
                  label: 'Copy',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('URL copied to clipboard')),
                    );
                  },
                ),
              ),
            );
          }

          await _refreshFileList();
        } else {
          setState(() {
            _errorMessage = 'Upload failed: No URL returned';
          });
        }
      }
    } catch (e) {
      print('Error uploading file: $e');
      setState(() {
        _errorMessage = 'Failed to upload: ${e.toString()}';
      });
    }
  }

  Future<void> _deleteSelectedFiles() async {
    try {
      for (String url in _selectedItems) {
        final uri = Uri.parse(url);
        final fileName = uri.pathSegments.last;

        final result = await FlutterAwsS3service.delete(
          bucket,
          identity,
          fileName,
          region,
          region,
        );

        if (result == null || result == 'Failed') {
          throw Exception('Failed to delete $fileName');
        }
      }

      setState(() {
        _selectedItems.clear();
        _isSelectionMode = false;
      });

      await _refreshFileList();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected files deleted successfully')),
        );
      }
    } catch (e) {
      print('Error deleting files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete files: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AWS S3 Demo - $_platformVersion'),
        actions: [
          if (_files.isNotEmpty)
            IconButton(
              icon: Icon(_isSelectionMode ? Icons.close : Icons.select_all),
              onPressed: () {
                setState(() {
                  _isSelectionMode = !_isSelectionMode;
                  _selectedItems.clear();
                });
              },
            ),
          if (_isSelectionMode && _selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedFiles,
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadFile,
        tooltip: 'Upload File',
        child: const Icon(Icons.upload_file),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_files.isEmpty) {
      return const Center(child: Text('No files found'));
    }

    return RefreshIndicator(
      onRefresh: _refreshFileList,
      child: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final url = _files[index];
          final uri = Uri.parse(url);
          final fileName = uri.pathSegments.last;
          final isSelected = _selectedItems.contains(url);

          return ListTile(
            leading: Icon(Icons.file_present),
            title: Text(fileName),
            subtitle: SelectableText(url, maxLines: 1),
            selected: isSelected,
            onTap: _isSelectionMode
                ? () {
                    setState(() {
                      if (isSelected) {
                        _selectedItems.remove(url);
                      } else {
                        _selectedItems.add(url);
                      }
                    });
                  }
                : () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('URL copied to clipboard')),
                    );
                  },
            onLongPress: () {
              setState(() {
                _isSelectionMode = true;
                _selectedItems.add(url);
              });
            },
          );
        },
      ),
    );
  }
}
