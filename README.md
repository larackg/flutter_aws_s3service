# flutter_aws_s3service

A Flutter package for AWS S3 service operations. This package provides a simple interface for common
S3 operations like uploading, downloading, and managing files in AWS S3 buckets.

log tag：AwsS3service

## 1. Features

- Initialize AWS S3 service with identity pool or access keys
- Upload files to S3 buckets
- Download files from S3 buckets
- List files in S3 buckets
- Delete files from S3 buckets
- Cross-platform support (iOS, Android)

## 2. Getting started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_aws_s3service: ^0.0.1
```

## 3. Usage

### Initialize the S3 service

You can initialize the service using either identity pool ID or access keys:

```dart

final s3service = FlutterAwsS3service();

// Initialize with identity pool ID
await s3service.initialize(region: 'YOUR_REGION', bucketName: 'YOUR_BUCKET_NAME', identityPoolId: 'YOUR_IDENTITY_POOL_ID');

// Or initialize with access keys
await s3service.initialize(
region: 'YOUR_REGION',
bucketName: 'YOUR_BUCKET_NAME',
accessKeyId: 'YOUR_ACCESS_KEY_ID',
secretAccessKey: 'YOUR_SECRET_ACCESS_KEY',
);
```

### Upload a file

```dart
// Upload a file and get the URL
final url = await s3service.uploadFile(filePath, // Local file path
key // S3 object key (path in bucket)
);
```

### List files in bucket

```dart
// Get list of files from S3 bucket
final files = await s3service.listFiles();
// Returns List<Map<String, dynamic>> containing file information
```

### Download a file

```dart
// Download a file from S3
await s3service.downloadFile(key, // S3 object key
localPath // Local path to save the file
);
```

### Delete files

```dart
// Delete a single file
await s3service.deleteFile(key);

// Delete multiple files
await s3service.deleteFiles(keys);
```

## 4. Example

Check out the [example](example) folder for a complete demo application showing how to:

- Initialize the S3 service
- Upload files with progress tracking
- List files in the bucket
- Download files
- Delete files
- Handle errors

## 5. Additional information

For more information about AWS S3, visit the [AWS S3 documentation](https://docs.aws.amazon.com/s3).

## 6. Development

### Create project

1. Create plugin project:

```bash
flutter create -t plugin --platforms android,ios --org com.larack.s3service flutter_aws_s3service
```

### 7. Publish

```bash
flutter pub publish --dry-run
flutter pub publish
```
