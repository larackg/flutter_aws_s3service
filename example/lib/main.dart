import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_aws_s3service/flutter_aws_s3service.dart';
import 'package:flutter_aws_s3service_example/config.dart';
import 'package:path_provider/path_provider.dart';

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
  final _s3service = FlutterAwsS3service();
  bool _isInitialized = false;
  List<Map<String, dynamic>> _files = [];
  String? _lastUploadedUrl;
  String? _errorMessage;
  String _tips = "";
  bool _isSelectionMode = false;
  Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _initializeS3();
    _getPlatformVersion();
  }

  Future<void> _initializeS3() async {
    try {
      await _s3service.initialize(
        region: region,
        bucketName: bucketName,
        identityPoolId: identityPoolId,
        // accessKeyId: accessKeyId,
        // secretAccessKey: secretAccessKey,
      );
      setState(() {
        _isInitialized = true;
        _errorMessage = null;
      });
      await _refreshFileList();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: ${e.toString()}';
      });
    }
  }

  Future<void> _getPlatformVersion() async {
    try {
      String tip = await _s3service.getPlatformVersion();
      setState(() {
        _tips = tip;
      });
    } catch (e) {
      setState(() {
        _tips = 'Failed to getPlatformVersion';
      });
    }
  }

  Future<void> _refreshFileList() async {
    try {
      setState(() {
        _errorMessage = null;
        _files = []; // Clear current files while loading
      });

      final files = await _s3service.listFiles();
      if (files.isEmpty) {
        setState(() {
          _errorMessage = 'No files found in S3 bucket';
        });
        return;
      }

      setState(() {
        _files = files;
        _errorMessage = null;
      });
    } catch (e) {
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
        final key =
            'uploads/${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';

        final url = await _s3service.uploadFile(file.path, key);
        setState(() {
          _lastUploadedUrl = url;
          _errorMessage = null;
        });

        // Show toast with the uploaded URL
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
                    SnackBar(
                      content: Text('URL copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          );
        }

        await _refreshFileList();
      } else {}
    } catch (e) {
      debugPrint('Error uploading file: $e');
      setState(() {
        _errorMessage = 'Failed to upload: ${e.toString()}';
      });

      // Show error toast
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadFile(String key) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localPath = '${directory.path}/${key.split('/').last}';

      await _s3service.downloadFile(key, localPath);
      setState(() {
        _errorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File downloaded to: $localPath')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to download: ${e.toString()}';
      });
    }
  }

  Future<void> _deleteFile(String key) async {
    try {
      await _s3service.deleteFile(key);
      setState(() {
        _errorMessage = null;
      });
      await _refreshFileList();
    } catch (e) {
      debugPrint('Error deleting file: $e');
      setState(() {
        _errorMessage = 'Failed to delete: ${e.toString()}';
      });
    }
  }

  Future<void> _getSignedUrl(String key) async {
    try {
      final url = await _s3service.getSignedUrl(key);
      debugPrint('Got signed URL: $url');
      setState(() {
        _lastUploadedUrl = url;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('Error getting signed URL: $e');
      setState(() {
        _errorMessage = 'Failed to get signed URL: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedItems.length} selected')
            : const Text('AWS S3 Demo'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedItems.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                setState(() {
                  if (_selectedItems.length == _files.length) {
                    _selectedItems.clear();
                  } else {
                    _selectedItems =
                        _files.map((f) => f['key'] as String).toSet();
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedItems.isEmpty
                  ? null
                  : () async {
                      for (var key in _selectedItems) {
                        await _deleteFile(key);
                      }
                      setState(() {
                        _isSelectionMode = false;
                        _selectedItems.clear();
                      });
                    },
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isInitialized ? _refreshFileList : null,
            ),
        ],
      ),
      body: _isInitialized
          ? Column(
              children: [
                Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.all(5),
                  child: Text("PlatformVersion: $_tips",
                      style: const TextStyle(color: Colors.red)),
                ),
                if (_errorMessage != null)
                  Container(
                    color: Colors.red.shade100,
                    padding: const EdgeInsets.all(8),
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                if (_lastUploadedUrl != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Last uploaded URL: $_lastUploadedUrl'),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _files.length,
                    itemBuilder: (context, index) {
                      final file = _files[index];
                      final key = file['key'] as String;
                      final isSelected = _selectedItems.contains(key);

                      return ListTile(
                        leading: _isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedItems.add(key);
                                    } else {
                                      _selectedItems.remove(key);
                                    }
                                  });
                                },
                              )
                            : const Icon(Icons.insert_drive_file),
                        title: Text(key.split('/').last),
                        subtitle: Text(
                            'Size: ${((file['size'] as int) / 1024).toStringAsFixed(2)} KB'),
                        onLongPress: () {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedItems.add(key);
                          });
                        },
                        onTap: _isSelectionMode
                            ? () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedItems.remove(key);
                                  } else {
                                    _selectedItems.add(key);
                                  }
                                });
                              }
                            : () => _getSignedUrl(key),
                      );
                    },
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              onPressed: _uploadFile,
              child: const Icon(Icons.file_upload),
            )
          : null,
    );
  }
}
