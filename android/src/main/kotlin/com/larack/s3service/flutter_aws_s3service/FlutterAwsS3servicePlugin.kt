package com.larack.s3service.flutter_aws_s3service

import android.content.Context
import android.util.Log
import com.amazonaws.auth.AWSCredentials
import com.amazonaws.auth.BasicAWSCredentials
import com.amazonaws.auth.CognitoCachingCredentialsProvider
import com.amazonaws.regions.Region
import com.amazonaws.regions.Regions
import com.amazonaws.services.s3.AmazonS3Client
import com.amazonaws.services.s3.model.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlinx.coroutines.*
import java.io.File
import java.util.*

class FlutterAwsS3servicePlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var s3Client: AmazonS3Client
    private var bucketName: String? = null
    private val TAG = "AwsS3service"
    private val scope = CoroutineScope(Dispatchers.Main + Job())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "flutter_aws_s3service")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "onMethodCall ${call.method} with arguments: ${call.arguments}")
        try {
            when (call.method) {
                "initialize" -> {
                    executeInBackground(result) { initialize(call, it) }
                }

                "uploadFile" -> {
                    executeInBackground(result) { uploadFile(call, it) }
                }

                "downloadFile" -> {
                    executeInBackground(result) { downloadFile(call, it) }
                }

                "deleteFile" -> {
                    executeInBackground(result) { deleteFile(call, it) }
                }

                "listFiles" -> {
                    executeInBackground(result) { listFiles(call, it) }
                }

                "getSignedUrl" -> {
                    executeInBackground(result) { getSignedUrl(call, it) }
                }

                "getPlatformVersion" -> {
                    result.success("Android ${android.os.Build.VERSION.RELEASE}")
                }

                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error in method call: ${call.method}", e)
            result.error(
                "UNEXPECTED_ERROR",
                "An unexpected error occurred: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    private fun executeInBackground(
        result: MethodChannel.Result,
        block: suspend (MethodChannel.Result) -> Unit
    ) {
        scope.launch {
            try {
                block(result)
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    Log.e(TAG, "Background execution error: ${e.message}", e)
                    result.error(
                        "BACKGROUND_ERROR",
                        "Operation failed: ${e.message}",
                        e.stackTraceToString()
                    )
                }
            }
        }
    }

    private suspend fun initialize(call: MethodCall, result: MethodChannel.Result) =
        withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Initializing S3 service")
                val arguments = call.arguments as Map<*, *>
                val region = arguments["region"] as String
                this@FlutterAwsS3servicePlugin.bucketName = arguments["bucketName"] as String
                val accessKeyId = arguments["accessKeyId"] as? String
                val secretAccessKey = arguments["secretAccessKey"] as? String
                val identityPoolId = arguments["identityPoolId"] as? String

                Log.d(
                    TAG,
                    "Initializing with region: $region, bucket: ${this@FlutterAwsS3servicePlugin.bucketName}"
                )

                // Initialize credentials and S3 client based on available authentication method
                when {
                    // Basic AWS credentials
                    accessKeyId != null && secretAccessKey != null -> {
                        Log.d(TAG, "Initializing with AWS credentials")
                        val credentials = BasicAWSCredentials(accessKeyId, secretAccessKey)
                        s3Client = AmazonS3Client(credentials, Region.getRegion(Regions.fromName(region)))
                    }
                    // Cognito Identity Pool
                    identityPoolId != null -> {
                        Log.d(TAG, "Initializing with Cognito Identity Pool")
                        val credentialsProvider = CognitoCachingCredentialsProvider(
                            context,
                            identityPoolId,
                            Regions.fromName(region)
                        )
                        s3Client = AmazonS3Client(credentialsProvider, Region.getRegion(Regions.fromName(region)))
                    }
                    else -> {
                        Log.e(TAG, "No valid authentication method provided")
                        withContext(Dispatchers.Main) {
                            result.error(
                                "INIT_ERROR",
                                "Either AWS credentials or Identity Pool ID must be provided",
                                null
                            )
                        }
                        return@withContext
                    }
                }

                // Test connection
                s3Client.doesBucketExist(bucketName)
                Log.d(TAG, "Successfully connected to bucket: $bucketName")

                withContext(Dispatchers.Main) {
                    result.success(true)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Initialize error: ${e.message}", e)
                withContext(Dispatchers.Main) {
                    result.error(
                        "INIT_ERROR",
                        "Failed to initialize: ${e.message}",
                        e.stackTraceToString()
                    )
                }
            }
        }

    private suspend fun uploadFile(call: MethodCall, result: MethodChannel.Result) =
        withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Uploading to bucket: $bucketName")
                validateS3ClientInitialized(result) ?: return@withContext

                val filePath = call.argument<String>("filePath")
                val key = call.argument<String>("key")

                Log.d(TAG, "Uploading file: $filePath to bucket: $bucketName with key: $key")

                if (filePath == null || key == null) {
                    Log.e(TAG, "Invalid arguments. FilePath: $filePath, Key: $key")
                    withContext(Dispatchers.Main) {
                        result.error("INVALID_ARGUMENTS", "File path and key are required", null)
                    }
                    return@withContext
                }

                val file = File(filePath)
                if (!file.exists()) {
                    Log.e(TAG, "File not found: $filePath")
                    withContext(Dispatchers.Main) {
                        result.error("FILE_NOT_FOUND", "File not found: $filePath", null)
                    }
                    return@withContext
                }

                Log.d(TAG, "File exists. Size: ${file.length()} bytes")

                val request = PutObjectRequest(bucketName, key, file)
                    .withGeneralProgressListener { progressEvent ->
                        Log.d(TAG, "Upload progress: ${progressEvent.bytesTransferred} bytes")
                    }

                try {
                    Log.d(TAG, "Executing S3 upload request")
                    val putObjectResult = s3Client.putObject(request)
                    val url = s3Client.getUrl(bucketName, key)
                    Log.d(TAG, "File uploaded successfully. URL: $url")
                    withContext(Dispatchers.Main) {
                        result.success(
                            mapOf(
                                "url" to url.toString(),
                                "eTag" to putObjectResult.eTag,
                                "versionId" to (putObjectResult.versionId ?: "")
                            )
                        )
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "S3 upload error: ${e.message}", e)
                    withContext(Dispatchers.Main) {
                        result.error(
                            "S3_UPLOAD_ERROR",
                            "Failed to upload to S3: ${e.message}",
                            e.stackTraceToString()
                        )
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Upload error: ${e.message}", e)
                withContext(Dispatchers.Main) {
                    result.error(
                        "UPLOAD_ERROR",
                        "Failed to upload file: ${e.message}",
                        e.stackTraceToString()
                    )
                }
            }
        }

    private suspend fun downloadFile(call: MethodCall, result: MethodChannel.Result) =
        withContext(Dispatchers.IO) {
            try {
                validateS3ClientInitialized(result) ?: return@withContext

                val key = call.argument<String>("key")
                val localPath = call.argument<String>("localPath")

                if (key == null || localPath == null) {
                    withContext(Dispatchers.Main) {
                        result.error("INVALID_ARGUMENTS", "Key and local path are required", null)
                    }
                    return@withContext
                }

                val file = File(localPath)
                file.parentFile?.mkdirs()

                val request = GetObjectRequest(bucketName, key)
                    .withGeneralProgressListener { progressEvent ->
                        Log.d(TAG, "Download progress: ${progressEvent.bytesTransferred} bytes")
                    }

                val obj = s3Client.getObject(request)
                obj.objectContent.use { input ->
                    file.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }

                withContext(Dispatchers.Main) {
                    result.success(
                        mapOf(
                            "path" to localPath,
                            "size" to file.length(),
                            "lastModified" to file.lastModified()
                        )
                    )
                }
            } catch (e: Exception) {
                Log.e(TAG, "Download error: ${e.message}", e)
                withContext(Dispatchers.Main) {
                    result.error(
                        "DOWNLOAD_ERROR",
                        "Failed to download file: ${e.message}",
                        e.stackTraceToString()
                    )
                }
            }
        }

    private suspend fun deleteFile(call: MethodCall, result: MethodChannel.Result) =
        withContext(Dispatchers.IO) {
            try {
                validateS3ClientInitialized(result) ?: return@withContext

                val key = call.argument<String>("key")
                if (key == null) {
                    withContext(Dispatchers.Main) {
                        result.error("INVALID_ARGUMENTS", "Key is required", null)
                    }
                    return@withContext
                }

                Log.d(TAG, "Deleting file with key: $key from bucket: $bucketName")
                s3Client.deleteObject(bucketName, key)
                Log.d(TAG, "File deleted successfully")
                withContext(Dispatchers.Main) {
                    result.success(true)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Delete error: ${e.message}", e)
                withContext(Dispatchers.Main) {
                    result.error(
                        "DELETE_ERROR",
                        "Failed to delete file: ${e.message}",
                        e.stackTraceToString()
                    )
                }
            }
        }

    private suspend fun listFiles(call: MethodCall, result: MethodChannel.Result) =
        withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "Starting listFiles operation")

                if (bucketName.isNullOrEmpty()) {
                    Log.e(TAG, "Bucket name is null or empty")
                    withContext(Dispatchers.Main) {
                        result.error("BUCKET_ERROR", "Bucket name is not set", null)
                    }
                    return@withContext
                }

                val prefix = call.argument<String>("prefix")
                Log.d(TAG, "Listing files from bucket: $bucketName with prefix: $prefix")

                try {
                    val listObjectsRequest = ListObjectsRequest().apply {
                        this.bucketName = this@FlutterAwsS3servicePlugin.bucketName
                        if (!prefix.isNullOrEmpty()) {
                            this.prefix = prefix
                        }
                    }

                    val objects = s3Client.listObjects(listObjectsRequest)
                    Log.d(TAG, "Retrieved ${objects.objectSummaries.size} objects from S3")

                    val files = objects.objectSummaries.map { summary ->
                        Log.d(
                            TAG,
                            "File: ${summary.key}, Size: ${summary.size}, Modified: ${summary.lastModified}"
                        )
                        mapOf(
                            "key" to summary.key,
                            "size" to summary.size,
                            "lastModified" to summary.lastModified.time
                        )
                    }

                    Log.d(TAG, "Mapped ${files.size} files to return")
                    withContext(Dispatchers.Main) {
                        result.success(files)
                    }
                } catch (e: AmazonS3Exception) {
                    Log.e(TAG, "S3 operation error: ${e.message}", e)
                    when (e.errorCode) {
                        "AccessDenied" -> {
                            withContext(Dispatchers.Main) {
                                result.error(
                                    "PERMISSION_ERROR",
                                    "The current credentials do not have permission to list files. " +
                                    "When using Cognito Identity Pool, make sure the IAM role has s3:ListBucket permission for the bucket.",
                                    e.toString()
                                )
                            }
                        }
                        else -> {
                            withContext(Dispatchers.Main) {
                                result.error(
                                    "S3_ERROR",
                                    "S3 operation failed: ${e.message}",
                                    e.toString()
                                )
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error in listFiles: ${e.message}", e)
                withContext(Dispatchers.Main) {
                    result.error(
                        "LIST_ERROR",
                        "Failed to list files: ${e.message}",
                        e.toString()
                    )
                }
            }
        }

    private suspend fun getSignedUrl(call: MethodCall, result: MethodChannel.Result) =
        withContext(Dispatchers.IO) {
            try {
                validateS3ClientInitialized(result) ?: return@withContext

                val key = call.argument<String>("key")
                val expirationInSeconds =
                    call.argument<Int>("expirationInSeconds") ?: 3600

                if (key == null) {
                    withContext(Dispatchers.Main) {
                        result.error("INVALID_ARGUMENTS", "Key is required", null)
                    }
                    return@withContext
                }

                Log.d(TAG, "Generating signed URL for key: $key in bucket: $bucketName")
                val expiration = Date(System.currentTimeMillis() + expirationInSeconds * 1000L)
                val url = s3Client.generatePresignedUrl(bucketName, key, expiration)
                Log.d(TAG, "Generated signed URL: $url")
                withContext(Dispatchers.Main) {
                    result.success(url.toString())
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    Log.e(TAG, "URL generation error: ${e.message}", e)
                    result.error("URL_ERROR", "Failed to generate signed URL: ${e.message}", null)
                }
            }
        }

    private suspend fun validateS3ClientInitialized(result: MethodChannel.Result): MethodChannel.Result? {
        if (!::s3Client.isInitialized) {
            Log.w(TAG, "s3Client not initialized")
            withContext(Dispatchers.Main) {
                result.error("CLIENT_NOT_INITIALIZED", "AWS S3 client is not initialized", null)
            }
            return result
        }
        if (bucketName.isNullOrEmpty()) {
            Log.w(TAG, "bucketName $bucketName")
            withContext(Dispatchers.Main) {
                result.error("INVALID_BUCKET", "Bucket name is not initialized", null)
            }
            return result
        }
        return null
    }
}
