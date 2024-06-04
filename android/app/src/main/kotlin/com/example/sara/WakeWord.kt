package com.example.utils

import android.util.Log
import android.content.Context
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel

class WakeWordDetector(context: Context) {
    private var interpreter: Interpreter? = null
    
    private val modelInputShape = intArrayOf(1, 16, 96) // Model's expected input shape
    private val modelInputSize = modelInputShape[0] * modelInputShape[1] * modelInputShape[2] // Calculate total size

    init {
        val model = loadModelFile(context, "Saraa.tflite")
        interpreter = Interpreter(model)
    }

    private fun loadModelFile(context: Context, modelPath: String): ByteBuffer {
        val fileDescriptor = context.assets.openFd(modelPath)
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        val startOffset = fileDescriptor.startOffset
        val declaredLength = fileDescriptor.declaredLength
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength).apply {
            order(ByteOrder.nativeOrder())
        }
    }

    fun detectWakeWord(audioData: FloatArray): Boolean {
        // Prepare input buffer
        val inputBuffer = ByteBuffer.allocateDirect(modelInputSize * 4).order(ByteOrder.nativeOrder())
        
        for (i in 0 until modelInputSize) {
            inputBuffer.putFloat(if (i < audioData.size) audioData[i] else 0.0f) // Normalize short to float
        }

        // Prepare output buffer
        val outputBuffer = ByteBuffer.allocateDirect(4).order(ByteOrder.nativeOrder())

        // Run inference
        interpreter?.run(inputBuffer, outputBuffer)

        // Get result
        outputBuffer.rewind()
        val prediction = outputBuffer.float
        Log.d("WakeWordDetector", "Prediction: $prediction")
        return prediction > 0.43// Adjust threshold as necessary
    }

    fun close() {
        interpreter?.close()
    }
}
