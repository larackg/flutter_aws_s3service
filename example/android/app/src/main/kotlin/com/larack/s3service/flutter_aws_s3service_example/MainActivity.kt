package com.larack.s3service.flutter_aws_s3service_example

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    val tag = "MainActivity"
    private val TAG = "AwsS3service"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(tag, "onCreate")
        Log.d(TAG, "MainActivity created")
    }

    override fun onBackPressed() {
        super.onBackPressed()
        Log.d(tag, "onBackPressed")
    }
}
