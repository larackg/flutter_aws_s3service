import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FlutterAwsS3service {
  static const MethodChannel _channel = MethodChannel('flutter_aws_s3service');

  static Future<String> get platformVersion async {
    return await _channel.invokeMethod('getPlatformVersion');
  }

  static Future<String?> uploadImage(
      String filepath, String bucket, String identity) async {
    final Map<String, dynamic> params = <String, dynamic>{
      'filePath': filepath,
      'bucket': bucket,
      'identity': identity,
    };
    final String? imagePath =
        await _channel.invokeMethod('uploadImageToAmazon', params);
    return imagePath;
  }

  static Future<String?> upload(String filepath, String bucket, String identity,
      String imageName, String region, String subRegion) async {
    final Map<String, dynamic> params = <String, dynamic>{
      'filePath': filepath,
      'bucket': bucket,
      'identity': identity,
      'imageName': imageName,
      'region': region,
      'subRegion': subRegion
    };
    final String? imagePath =
        await _channel.invokeMethod('uploadImage', params);
    return imagePath;
  }

  static Future<String?> delete(String bucket, String identity,
      String imageName, String region, String subRegion) async {
    final Map<String, dynamic> params = <String, dynamic>{
      'bucket': bucket,
      'identity': identity,
      'imageName': imageName,
      'region': region,
      'subRegion': subRegion
    };
    final String? imagePath =
        await _channel.invokeMethod('deleteImage', params);
    return imagePath;
  }

  static Future<List<String>> listFiles(String bucket, String identity,
      String prefix, String region, String subRegion) async {
    final Map<String, dynamic> params = <String, dynamic>{
      'bucket': bucket,
      'identity': identity,
      'prefix': prefix,
      'region': region,
      'subRegion': subRegion
    };
    List<String> files = [];
    try {
      final dynamic result = await _channel.invokeMethod('listFiles', params);
      if (result is List) {
        for (final dynamic key in result) {
          if (key is String) {
            files.add("https://s3-$region.amazonaws.com/$bucket/$key");
          }
        }
      }
    } on PlatformException catch (e) {
      debugPrint(e.toString());
    }
    return files;
  }
}
