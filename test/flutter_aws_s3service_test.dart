import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aws_s3service/flutter_aws_s3service.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_aws_s3service');
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getPlatformVersion':
            return '42';
          case 'uploadImageToAmazon':
            return 'https://example.com/test.jpg';
          case 'uploadImage':
            return 'https://example.com/uploaded.jpg';
          case 'deleteImage':
            return 'success';
          case 'listFiles':
            return <dynamic>['file1.jpg', 'file2.jpg'];
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await FlutterAwsS3service.platformVersion, '42');
  });

  test('uploadImage', () async {
    final result = await FlutterAwsS3service.uploadImage(
      'test.jpg',
      'test-bucket',
      'test-identity'
    );
    expect(result, 'https://example.com/test.jpg');
  });

  test('upload', () async {
    final result = await FlutterAwsS3service.upload(
      'test.jpg',
      'test-bucket',
      'test-identity',
      'test-image.jpg',
      'us-east-1',
      'sub-region'
    );
    expect(result, 'https://example.com/uploaded.jpg');
  });

  test('delete', () async {
    final result = await FlutterAwsS3service.delete(
      'test-bucket',
      'test-identity',
      'test-image.jpg',
      'us-east-1',
      'sub-region'
    );
    expect(result, 'success');
  });

  test('listFiles', () async {
    final result = await FlutterAwsS3service.listFiles(
      'test-bucket',
      'test-identity',
      'prefix',
      'us-east-1',
      'sub-region'
    );
    expect(result, [
      'https://s3-us-east-1.amazonaws.com/test-bucket/file1.jpg',
      'https://s3-us-east-1.amazonaws.com/test-bucket/file2.jpg'
    ]);
  });
}
