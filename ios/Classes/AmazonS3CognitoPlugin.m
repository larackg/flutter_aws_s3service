#import "FlutterAwsS3servicePlugin.h"
#import <flutter_aws_s3service/flutter_aws_s3service-Swift.h>

@implementation FlutterAwsS3servicePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterAwsS3servicePlugin registerWithRegistrar:registrar];
}
@end
