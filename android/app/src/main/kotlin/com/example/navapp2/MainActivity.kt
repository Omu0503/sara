package com.example.navapp2

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
   

    
}

// import io.flutter.embedding.android.FlutterActivity
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.MethodChannel

// class MainActivity: FlutterActivity() {
//     private val CHANNEL = "com.example.navapp2/native"

//     override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//         super.configureFlutterEngine(flutterEngine)

//         MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
//             call, result ->
//             if (call.method == "encodeYUV420") {
//                 val uvPS = call.arguments("uvRowStride") as Int
//                 val uvRS = call.arguments("uvPixelStride") as Int
//                 val height = call.argument<Int>("height")!!
//                 val width = call.argument<Int>("width")!!
//                 val encoded = encodeYUV420(uvPS, uvRS, height, width /* width */, /* height */)
//                 result.success(encoded)
//             }
//         }
//     }

//     private fun encodeYUV420(uvPixelStride: Int, uvRowStride: Int, width: Int, height: Int): ByteArray {
//         // Conversion logic here

//         return byteArrayOf() // Placeholder for the converted RGB data
//     }
// }

