import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_aws_s3service_platform_interface.dart';

/// An implementation of [FlutterAwsS3servicePlatform] that uses method channels.
class MethodChannelFlutterAwsS3service extends FlutterAwsS3servicePlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_aws_s3service');

  @override
  Future<void> initialize({
    String? identityPoolId,
    String? region,
    String? bucketName,
    String? accessKeyId,
    String? secretAccessKey,
  }) async {
    final Map<String, dynamic> arguments = {
      'identityPoolId': identityPoolId,
      'region': region,
      'bucketName': bucketName,
      'accessKeyId': accessKeyId,
      'secretAccessKey': secretAccessKey,
    };
    await methodChannel.invokeMethod<void>('initialize', arguments);
  }

  @override
  Future<String> uploadFile(String filePath, String key) async {
    final result = await methodChannel.invokeMethod<String>('uploadFile', {
      'filePath': filePath,
      'key': key,
    });
    return result ?? '';
  }

  @override
  Future<String> downloadFile(String key, String localPath) async {
    final result = await methodChannel.invokeMethod<String>('downloadFile', {
      'key': key,
      'localPath': localPath,
    });
    return result ?? '';
  }

  @override
  Future<bool> deleteFile(String key) async {
    final result = await methodChannel.invokeMethod<bool>('deleteFile', {
      'key': key,
    });
    return result ?? false;
  }

  @override
  Future<List<Map<String, dynamic>>> listFiles({String? prefix}) async {
    final result =
        await methodChannel.invokeMethod<List<dynamic>>('listFiles', {
      'prefix': prefix,
    });
    return (result ?? [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  @override
  Future<String> getSignedUrl(String key,
      {int expirationInSeconds = 3600}) async {
    final result = await methodChannel.invokeMethod<String>('getSignedUrl', {
      'key': key,
      'expirationInSeconds': expirationInSeconds,
    });
    return result ?? '';
  }

  @override
  Future<String> getPlatformVersion() async {
    final result =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return result ?? '';
  }
}
