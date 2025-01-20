#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_aws_s3service'
  s.version          = '0.0.2'
  s.summary          = 'AWS S3 service operations plugin.'
  s.description      = <<-DESC
AWS S3 service operations plugin. This package provides a simple interface for
common S3 operations like uploading, downloading, and managing files in AWS S3 buckets.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Fam Properties' => 'no-reply@famproperties.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'AWSS3'
  s.dependency 'AWSCore'
  s.dependency 'AWSCognito'

  s.ios.deployment_target = '12.0'
end

