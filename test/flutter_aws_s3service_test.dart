import 'package:flutter_aws_s3service/flutter_aws_s3service.dart';
import 'package:flutter_aws_s3service/flutter_aws_s3service_method_channel.dart';
import 'package:flutter_aws_s3service/flutter_aws_s3service_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterAwsS3servicePlatform
    with MockPlatformInterfaceMixin
    implements FlutterAwsS3servicePlatform {
  final _s3service = FlutterAwsS3service();

  MockFlutterAwsS3servicePlatform() {
    _s3service.initialize(
        // region: region,
        // bucketName: bucketName,
        // accessKeyId: accessKeyId,
        // secretAccessKey: secretAccessKey,
        );
  }

  @override
  Future<String> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> deleteFile(String key) {
    return _s3service.deleteFile(key);
  }

  @override
  Future<String> downloadFile(String key, String localPath) {
    return _s3service.downloadFile(key, localPath);
  }

  @override
  Future<String> getSignedUrl(String key, {int expirationInSeconds = 3600}) {
    return _s3service.getSignedUrl(key);
  }

  @override
  Future<void> initialize(
      {String? identityPoolId,
      String? region,
      String? bucketName,
      String? accessKeyId,
      String? secretAccessKey}) {
    // TODO: implement initialize
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> listFiles({String? prefix}) {
    // TODO: implement listFiles
    throw UnimplementedError();
  }

  @override
  Future<String> uploadFile(String filePath, String key) {
    // TODO: implement uploadFile
    throw UnimplementedError();
  }
}

void main() {
  final FlutterAwsS3servicePlatform initialPlatform =
      FlutterAwsS3servicePlatform.instance;

  test('$MethodChannelFlutterAwsS3service is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterAwsS3service>());
  });

  test('getPlatformVersion', () async {
    FlutterAwsS3service flutterAwsS3servicePlugin = FlutterAwsS3service();
    MockFlutterAwsS3servicePlatform fakePlatform =
        MockFlutterAwsS3servicePlatform();
    FlutterAwsS3servicePlatform.instance = fakePlatform;

    expect(await flutterAwsS3servicePlugin.getPlatformVersion(), '42');
  });
}
