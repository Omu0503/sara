package com.example.saraa

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.utils.WakeWordDetector

class MainActivity : FlutterActivity() {
    private lateinit var wakeWordDetector: WakeWordDetector
    private var audioRecord: AudioRecord? = null
    private val sampleRate = 16000
    private val bufferSize = AudioRecord.getMinBufferSize(sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
    private val buffer = ShortArray(bufferSize)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        wakeWordDetector = WakeWordDetector(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.saraa").setMethodCallHandler { call, result ->
            when (call.method) {
                "startWakeWordDetection" -> {
                    startListening(flutterEngine)
                    result.success("Wake word detection started")
                }
                "stopWakeWordDetection" -> {
                    stopListening()
                    result.success("Wake word detection stopped")
                }
                "destroy" -> {
                    destroy()
                    result.success("Wake word session destroyed")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startListening(flutterEngine: FlutterEngine):Boolean {
        audioRecord = AudioRecord(MediaRecorder.AudioSource.MIC, sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, bufferSize)
        audioRecord?.startRecording()

        Thread {
            while (audioRecord?.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                val readSize = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                if (readSize > 0) {
                    val normalizedBuffer = normalizeAudioData(buffer, readSize)
                    val isWakeWordDetected = wakeWordDetector.detectWakeWord(normalizedBuffer)
                    
                    if (isWakeWordDetected) {
                        runOnUiThread {
                            // Notify Flutter about wake word detection
                            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.saraa").invokeMethod("wakeWordDetected", null)
                        }
                    }
                    return isWakeWordDetected
                }
            }
        }.start()
    }

    private fun stopListening() {
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        wakeWordDetector.close() // Clean up the interpreter
    }

    override fun onDestroy() {
        super.onDestroy()
        stopListening() // Ensure resources are cleaned up
    }

    private fun normalizeAudioData(buffer: ShortArray, readSize: Int): FloatArray {
        val normalizedBuffer = FloatArray(readSize)
        for (i in 0 until readSize) {
            normalizedBuffer[i] = buffer[i] / 32767.0f // Normalize short to float [-1.0, 1.0]
        }
        return normalizedBuffer
    }
}
