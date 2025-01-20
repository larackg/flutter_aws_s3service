import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_aws_s3service_method_channel.dart';

abstract class FlutterAwsS3servicePlatform extends PlatformInterface {
  /// Constructs a FlutterAwsS3servicePlatform.
  FlutterAwsS3servicePlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterAwsS3servicePlatform _instance =
      MethodChannelFlutterAwsS3service();

  /// The default instance of [FlutterAwsS3servicePlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterAwsS3service].
  static FlutterAwsS3servicePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterAwsS3servicePlatform] when
  /// they register themselves.
  static set instance(FlutterAwsS3servicePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initialize({
    String? identityPoolId,
    String? region,
    String? bucketName,
    String? accessKeyId,
    String? secretAccessKey,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<String> uploadFile(String filePath, String key) {
    throw UnimplementedError('uploadFile() has not been implemented.');
  }

  Future<String> downloadFile(String key, String localPath) {
    throw UnimplementedError('downloadFile() has not been implemented.');
  }

  Future<bool> deleteFile(String key) {
    throw UnimplementedError('deleteFile() has not been implemented.');
  }

  Future<List<Map<String, dynamic>>> listFiles({String? prefix}) {
    throw UnimplementedError('listFiles() has not been implemented.');
  }

  Future<String> getSignedUrl(String key, {int expirationInSeconds = 3600}) {
    throw UnimplementedError('getSignedUrl() has not been implemented.');
  }

  Future<String> getPlatformVersion() async {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }
}
