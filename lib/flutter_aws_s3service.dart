import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FlutterAwsS3service {
  static const MethodChannel _channel = MethodChannel('flutter_aws_s3service');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
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
    List<String> files = new List.empty(growable: true);
    try {
      List<dynamic> keys = await (_channel.invokeMethod('listFiles', params)
          as FutureOr<List<dynamic>>);
      for (String key in keys as Iterable<String>) {
        files.add("https://s3-$region.amazonaws.com/$bucket/$key");
      }
    } on PlatformException catch (e) {
      debugPrint(e.toString());
    }
    return files;
  }
}
