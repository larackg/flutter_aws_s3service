import Flutter
import UIKit
import AWSS3
import AWSCore

public class SwiftFlutterAwsS3servicePlugin: NSObject, FlutterPlugin {

   var region1:AWSRegionType = AWSRegionType.USEast1
   var subRegion1:AWSRegionType = AWSRegionType.EUWest1

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_aws_s3service", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterAwsS3servicePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
         if(call.method.elementsEqual("uploadImage")){
              uploadImageForRegion(call,result: result)
          }else if(call.method.elementsEqual("deleteImage")){
              deleteImage(call,result: result)
          }else if(call.method.elementsEqual("listFiles")){
              listFiles(call,result: result)
          }
      }

      public func nameGenerator() -> String{
          let date = Date()
          let formatter = DateFormatter()
          formatter.dateFormat = "ddMMyyyy"
          let result = formatter.string(from: date)
          return "IMG" + result + String(Int64(date.timeIntervalSince1970 * 1000)) + "jpeg"
      }

      func uploadImageForRegion(_ call: FlutterMethodCall, result: @escaping FlutterResult){
                let arguments = call.arguments as? NSDictionary
                let imagePath = arguments!["filePath"] as? String
                let bucket = arguments!["bucket"] as? String
                let identity = arguments!["identity"] as? String
                let fileName = arguments!["imageName"] as? String
                let region = arguments!["region"] as? String
                let subRegion = arguments!["subRegion"] as? String

                let contentTypeParam = arguments!["contentType"] as? String

                print("region" + region!)

                print("subregion " + subRegion!)
                if(region != nil && subRegion != nil){
                    initRegions(region: region!, subRegion: subRegion!)
                }

              let credentialsProvider = AWSCognitoCredentialsProvider(
                  regionType: region1,
                  identityPoolId: identity!)
              let configuration = AWSServiceConfiguration(
                  region: subRegion1,
                  credentialsProvider: credentialsProvider)
              AWSServiceManager.default().defaultServiceConfiguration = configuration


                let transferUtility = AWSS3TransferUtility.default()
                let expression = AWSS3TransferUtilityUploadExpression()
                expression.progressBlock = { _, progress in
                    DispatchQueue.main.async {
                        result(["progress": progress.fractionCompleted])
                    }
                }

                guard let safeFileName = fileName, let safeBucket = bucket else {
                    result(FlutterError(code: "INVALID_ARGS",
                                      message: "fileName and bucket must not be nil",
                                      details: nil))
                    return
                }

                transferUtility.uploadFile(
                    URL(fileURLWithPath: imagePath ?? ""),
                    bucket: safeBucket,
                    key: safeFileName,
                    contentType: contentTypeParam ?? "image/jpeg",
                    expression: expression
                ) { task, error in
                    if let error = error {
                        result(FlutterError(code: "UPLOAD_ERROR",
                                      message: error.localizedDescription,
                                      details: nil))
                    } else {
                        let uploadedUrl = AWSS3.default().configuration.endpoint.url.description + "/\(safeBucket)/\(safeFileName)"
                        print("✅ Upload succeeded (\(uploadedUrl))")
                        result(["status": "completed", "url": uploadedUrl])
                    }
                }
            }

      func deleteImage(_ call: FlutterMethodCall, result: @escaping FlutterResult){
          let arguments = call.arguments as? NSDictionary
          let bucket = arguments!["bucket"] as? String
          let identity = arguments!["identity"] as? String
          let fileName = arguments!["imageName"] as? String
          let region = arguments!["region"] as? String
          let subRegion = arguments!["subRegion"] as? String

          if(region != nil && subRegion != nil){
              initRegions(region: region!, subRegion: subRegion!)
          }

          let credentialsProvider = AWSCognitoCredentialsProvider(
              regionType: region1,
              identityPoolId: identity!)
          let configuration = AWSServiceConfiguration(
              region: subRegion1,
              credentialsProvider: credentialsProvider)
          AWSServiceManager.default().defaultServiceConfiguration = configuration

          AWSS3.register(with: configuration!, forKey: "defaultKey")
          let s3 = AWSS3.s3(forKey: "defaultKey")
          let deleteObjectRequest = AWSS3DeleteObjectRequest()
          deleteObjectRequest?.bucket = bucket // bucket name
          deleteObjectRequest?.key = fileName // File name
          s3.deleteObject(deleteObjectRequest!).continueWith { (task:AWSTask) -> AnyObject? in
              if let error = task.error {
                  print("Error occurred: \(error)")
                  result("Error occurred: \(error)")
                  return nil
              }
              print("image deleted successfully.")
              result("image deleted successfully.")
              return nil
          }

      }

      func listFiles(_ call: FlutterMethodCall, result: @escaping FlutterResult){
          let arguments = call.arguments as? NSDictionary
          let bucket = arguments!["bucket"] as? String
          let identity = arguments!["identity"] as? String
          let filePrefix = arguments!["prefix"] as? String
          let region = arguments!["region"] as? String
          let subRegion = arguments!["subRegion"] as? String


          if(region != nil && subRegion != nil){
              initRegions(region: region!, subRegion: subRegion!)
          }

          let credentialsProvider = AWSCognitoCredentialsProvider(
              regionType: AWSRegionType.regionTypeForString(regionString: region!),
              identityPoolId: identity!)
          let configuration = AWSServiceConfiguration(
              region: AWSRegionType.regionTypeForString(regionString: subRegion!),
              credentialsProvider: credentialsProvider)
          AWSServiceManager.default().defaultServiceConfiguration = configuration

          AWSS3.register(with: configuration!, forKey: "defaultKey")

          let s3 = AWSS3.s3(forKey: "defaultKey")
          let listRequest = AWSS3ListObjectsRequest()
          listRequest?.bucket = bucket // bucket name
          listRequest?.prefix = filePrefix // File prefix

          s3.listObjects(listRequest!).continueWith { (task:AWSTask) -> AnyObject? in
              if let error = task.error {
                  print("Error occurred: \(error)")
                  result("Error occurred: \(error)")
                  return nil
              }

              let keys = task.result?.contents!.map({ $0.key })
              result(keys)
              return nil
          }

      }

      public func initRegions(region:String,subRegion:String){
          region1 = getRegion(name: region)
          subRegion1 = getRegion(name: subRegion)
      }

      public func getRegion( name:String ) -> AWSRegionType{

          if(name == "US_EAST_1"){
              return AWSRegionType.USEast1
          }else if(name == "AP_SOUTHEAST_1"){
              return AWSRegionType.APSoutheast1
          }else if(name == "US_EAST_2"){
              return AWSRegionType.USEast2
          }else if(name == "EU_WEST_1"){
              return AWSRegionType.EUWest1
          }else if(name == "CA_CENTRAL_1"){
              return AWSRegionType.CACentral1
          }else if(name == "CN_NORTH_1"){
              return AWSRegionType.CNNorth1
          } else if(name == "CN_NORTHWEST_1"){
              return AWSRegionType.CNNorthWest1
          }else if(name == "EU_CENTRAL_1"){
              return AWSRegionType.EUCentral1
          } else if(name == "EU_WEST_2"){
              return AWSRegionType.EUWest2
          }else if(name == "EU_WEST_3"){
              return AWSRegionType.EUWest3
          } else if(name == "SA_EAST_1"){
              return AWSRegionType.SAEast1
          } else if(name == "US_WEST_1"){
              return AWSRegionType.USWest1
          }else if(name == "US_WEST_2"){
              return AWSRegionType.USWest2
          } else if(name == "AP_NORTHEAST_1"){
              return AWSRegionType.APNortheast1
          } else if(name == "AP_NORTHEAST_2"){
              return AWSRegionType.APNortheast2
          } else if(name == "AP_SOUTHEAST_1"){
              return AWSRegionType.APSoutheast1
          }else if(name == "AP_SOUTHEAST_2"){
              return AWSRegionType.APSoutheast2
          } else if(name == "AP_SOUTH_1"){
              return AWSRegionType.APSouth1
          }else if(name == "ME_SOUTH_1"){
            return AWSRegionType.MESouth1
          }

          return AWSRegionType.Unknown
      }
}
