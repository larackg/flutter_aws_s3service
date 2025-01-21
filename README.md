# flutter_aws_s3service

AWS S3 service operations plugin. This package provides a simple interface for
common S3 operations like uploading, downloading, and managing files in AWS S3 buckets.

    package: com.larack.s3service.flutter_aws_s3service 
    pluginClass: FlutterAwsS3servicePlugin

## Environment

> 1. iOS
     target: 12.0
> 2. Android
     gradle: 8.3.2, jdk: 17, kotlin: 1.8.22

## Usage

```yaml
dependencies:
  flutter_aws_s3service: '^0.0.2'
```

### Example

``` dart
import 'package:flutter_aws_s3service/flutter_aws_s3service.dart';
import 'package:flutter_aws_s3service/aws_region.dart';

//this method only supports image upload. 
String uploadedImageUrl = await FlutterAwsS3service.uploadImage(
          image_path, bucket_name, identity_pool_id);

//Use the below code to specify the region and sub region for image upload
//Also this method allows to upload all file type including images and pdf etc.
//We recommend to use this method always. 
String uploadedImageUrl = await FlutterAwsS3service.upload(
            image_path,
            bucket_name,
            identity_pool_id,
            s3_image_name,
            AwsRegion.US_EAST_1,
            AwsRegion.AP_SOUTHEAST_1)
            
//use below code to delete an image
 String result = FlutterAwsS3service.delete(
            bucket_name,
            identity_pool_id,
            s3_image_name,
            AwsRegion.US_EAST_1,
            AwsRegion.AP_SOUTHEAST_1)
            
//use below code to list files
 List<String> files = await FlutterAwsS3service.listFiles(
            bucket_name,
            identity_pool_id,
            PREFIX,
            AwsRegion.US_EAST_1,
            AwsRegion.AP_SOUTHEAST_1)

```

## Installation

### Android & iOS

Run this command with Flutter:

```
flutter pub add flutter_aws_s3service
```

This will add a line like this to your package's pubspec.yaml (and run an implicit flutter pub get):

```yaml
dependencies:
  flutter_aws_s3service: '^0.0.2'
```

Now in your Dart code, you can use:

```
import 'package:flutter_aws_s3service/flutter_aws_s3service.dart';
```

### Authors

```
This plugin is created by chatgpt.
```

## Development

### Create project

Run this command with Flutter:

```bash
flutter create -t plugin --platforms android,ios --org com.larack.s3service flutter_aws_s3service
```

### Publish

Run this command with Shell:

```bash
flutter pub publish --dry-run
flutter pub publish
```
