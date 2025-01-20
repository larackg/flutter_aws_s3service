import 'flutter_aws_s3service_platform_interface.dart';

class FlutterAwsS3service {
  /// Initialize AWS S3 with credentials
  /// Either use [identityPoolId] with [region] and [bucketName]
  /// Or use [accessKeyId], [secretAccessKey], [region], and [bucketName]
  Future<void> initialize({
    String? identityPoolId,
    String? region,
    String? bucketName,
    String? accessKeyId,
    String? secretAccessKey,
  }) {
    return FlutterAwsS3servicePlatform.instance.initialize(
      identityPoolId: identityPoolId,
      region: region,
      bucketName: bucketName,
      accessKeyId: accessKeyId,
      secretAccessKey: secretAccessKey,
    );
  }

  /// Upload a file to S3
  /// [filePath] is the local path to the file
  /// [key] is the S3 object key (path in bucket)
  /// Returns the URL of the uploaded file
  Future<String> uploadFile(String filePath, String key) {
    return FlutterAwsS3servicePlatform.instance.uploadFile(filePath, key);
  }

  /// Download a file from S3
  /// [key] is the S3 object key
  /// [localPath] is where to save the file locally
  /// Returns the local path of the downloaded file
  Future<String> downloadFile(String key, String localPath) {
    return FlutterAwsS3servicePlatform.instance.downloadFile(key, localPath);
  }

  /// Delete a file from S3
  /// [key] is the S3 object key
  /// Returns true if deletion was successful
  Future<bool> deleteFile(String key) {
    return FlutterAwsS3servicePlatform.instance.deleteFile(key);
  }

  /// List files in the S3 bucket
  /// Optional [prefix] to filter files by prefix
  /// Returns a list of file metadata
  Future<List<Map<String, dynamic>>> listFiles({String? prefix}) {
    return FlutterAwsS3servicePlatform.instance.listFiles(prefix: prefix);
  }

  /// Get a signed URL for a file
  /// [key] is the S3 object key
  /// [expirationInSeconds] is how long the URL should be valid (default 1 hour)
  /// Returns the signed URL
  Future<String> getSignedUrl(String key, {int expirationInSeconds = 3600}) {
    return FlutterAwsS3servicePlatform.instance.getSignedUrl(
      key,
      expirationInSeconds: expirationInSeconds,
    );
  }

  Future<String> getPlatformVersion() async {
    return FlutterAwsS3servicePlatform.instance.getPlatformVersion();
  }
}
