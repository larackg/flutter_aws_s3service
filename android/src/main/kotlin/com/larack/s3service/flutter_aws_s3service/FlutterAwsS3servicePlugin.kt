package com.larack.s3service.flutter_aws_s3service

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry.Registrar
import org.jetbrains.annotations.NotNull
import java.io.File
import java.io.UnsupportedEncodingException

class FlutterAwsS3servicePlugin : FlutterPlugin, MethodCallHandler {

    private var awsHelper: AwsHelper? = null
    private var awsRegionHelper: AwsRegionHelper? = null

    private lateinit var context: Context
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "flutter_aws_s3service")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_aws_s3service")
            val instance = FlutterAwsS3servicePlugin()
            instance.context =
                registrar.context() ?: throw IllegalArgumentException("Context is null")
            channel.setMethodCallHandler(instance)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath")
        val bucket = call.argument<String>("bucket")
        val identity = call.argument<String>("identity")
        val fileName = call.argument<String>("imageName")
        val region = call.argument<String>("region")
        val subRegion = call.argument<String>("subRegion")
        val prefix = call.argument<String>("prefix")

        println("onMethodCall: ${call.method}")
        when (call.method) {
            "uploadImageToAmazon" -> {
                val file = File(filePath)
                try {
                    awsHelper = AwsHelper(context, object : AwsHelper.OnUploadCompleteListener {
                        override fun onFailed() {
                            println("\n❌ upload failed")
                            result.success("Failed")
                        }

                        override fun onUploadComplete(@NotNull imageUrl: String) {
                            println("\n✅ upload complete: $imageUrl")
                            result.success(imageUrl)
                        }
                    }, bucket!!, identity!!)
                    awsHelper!!.uploadImage(file)
                } catch (e: UnsupportedEncodingException) {
                    e.printStackTrace()
                }
            }

            "uploadImage" -> {
                val file = File(filePath)
                try {
                    awsRegionHelper =
                        AwsRegionHelper(context, bucket!!, identity!!, region!!, subRegion!!)
                    awsRegionHelper!!.uploadImage(
                        file,
                        fileName!!,
                        object : AwsRegionHelper.OnUploadCompleteListener {
                            override fun onFailed() {
                                println("\n❌ upload failed")
                                result.success("Failed")
                            }

                            override fun onUploadComplete(@NotNull imageUrl: String) {
                                println("\n✅ upload complete: $imageUrl")
                                result.success(imageUrl)
                            }
                        })
                } catch (e: UnsupportedEncodingException) {
                    e.printStackTrace()
                }
            }

            "deleteImage" -> {
                try {
                    awsRegionHelper =
                        AwsRegionHelper(context, bucket!!, identity!!, region!!, subRegion!!)
                    awsRegionHelper!!.deleteImage(
                        fileName!!,
                        object : AwsRegionHelper.OnUploadCompleteListener {
                            override fun onFailed() {
                                println("\n❌ delete failed")
                                result.success("Failed")
                            }

                            override fun onUploadComplete(@NotNull imageUrl: String) {
                                println("\n✅ delete complete: $imageUrl")
                                result.success(imageUrl)
                            }
                        })
                } catch (e: UnsupportedEncodingException) {
                    e.printStackTrace()
                }
            }

            "listFiles" -> {
                try {
                    awsRegionHelper =
                        AwsRegionHelper(context, bucket!!, identity!!, region!!, subRegion!!)
                    awsRegionHelper!!.listFiles(
                        prefix,
                        object : AwsRegionHelper.OnListFilesCompleteListener {
                            override fun onListFiles(files: List<String>) {
                                println("\n✅ list complete: $files")
                                result.success(files)
                            }
                        })
                } catch (e: UnsupportedEncodingException) {
                    e.printStackTrace()
                }
            }

            "getPlatformVersion" -> {
                val version = "0.0.2"
                println("getPlatformVersion: $version")
                result.success(version)
            }

            else -> result.notImplemented()
        }
    }
}