import UIKit
import AVFoundation
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var wakeWordDetector: WakeWordDetector?
  private var audioEngine: AVAudioEngine?
  private var inputNode: AVAudioInputNode?
  var flutterChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      GMSServices.provideAPIKey("AIzaSyBD0_Obb3gHlBdJ9MIAig5dWoFnmdWg7uk")
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.example.saraa", binaryMessenger: controller.binaryMessenger)
      
    wakeWordDetector = WakeWordDetector(channel: channel)
    setupAudioSession()
    
    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      switch call.method {
      case "startWakeWordDetection":
        self.startWakeWordDetection(result: result)
      case "stopWakeWordDetection":
        self.stopWakeWordDetection(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    stopWakeWordDetection()
    wakeWordDetector = nil
    audioEngine = nil
    if let wakeWordDetector = wakeWordDetector {
      wakeWordDetector.cleanup()
    }
    super.applicationWillTerminate(application)
  }

  private func startWakeWordDetection(result: FlutterResult) {
    setupAudioSession()
    audioEngine = AVAudioEngine()
    guard let audioEngine = audioEngine else {
      result(FlutterError(code: "AUDIO_ENGINE_INIT_FAILED", message: "Failed to initialize audio engine", details: nil))
      return
    }
    inputNode = audioEngine.inputNode

    let bus = 0

    // Use the hardware sample rate
    let hardwareSampleRate = AVAudioSession.sharedInstance().sampleRate
    guard let inputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: hardwareSampleRate, channels: 1, interleaved: false) else {
      print("Failed to create input format")
      return
    }

    audioEngine.inputNode.installTap(onBus: bus, bufferSize: 1024, format: inputFormat) { buffer, time in
      self.processAudioBuffer(buffer: buffer)
    }

    do {
      try audioEngine.start()
      result("Wake word detection started")
    } catch {
      print("Failed to start audio engine: \(error)")
      result(FlutterError(code: "AUDIO_ENGINE_START_FAILED", message: "Failed to start audio engine", details: error.localizedDescription))
    }

    print("Input format: \(String(describing: inputNode?.inputFormat(forBus: bus)))")
  }

  func setupAudioSession() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      // Set category to allow recording and playback
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .duckOthers])

      // Set preferred sample rate
      let preferredSampleRate: Double = 16000.0
      

      // Activate the audio session
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        try audioSession.setPreferredSampleRate(preferredSampleRate)

      // Print current sample rate to verify
      print("Current sample rate: \(audioSession.sampleRate)")

      // Check if the preferred sample rate was set correctly
      guard audioSession.sampleRate == preferredSampleRate else {
        print("Preferred sample rate not supported. Current sample rate: \(audioSession.sampleRate)")
        return
      }

    } catch {
      print("Failed to set up audio session: \(error)")
    }
  }

  private func stopWakeWordDetection(result: FlutterResult? = nil) {
    audioEngine?.stop()
    
    inputNode?.removeTap(onBus: 0)
    result?("Wake word detection stopped")
  }

  private func processAudioBuffer(buffer: AVAudioPCMBuffer) {
    guard let wakeWordDetector = wakeWordDetector else { return }

    guard let channelData = buffer.floatChannelData?[0] else {
      return
    }

    var channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
//    channelDataArray = highPassFilter(audioData: channelDataArray, sampleRate: buffer.format.sampleRate)

    if wakeWordDetector.detectWakeWord(audioData: channelDataArray) {
      DispatchQueue.main.async {
        // Notify Flutter about wake word detection
        if let controller = self.window?.rootViewController as? FlutterViewController {
          let channel = FlutterMethodChannel(name: "com.example.saraa", binaryMessenger: controller.binaryMessenger)
          channel.invokeMethod("wakeWordDetected", arguments: nil)
        }
      }
    }
  }
    
    private func highPassFilter(audioData: [Float], sampleRate: Double) -> [Float] {
        let lowCutoffFrequency: Float = 300.0  // Lower bound of human speech frequency
            let highCutoffFrequency: Float = 3000.0 // Upper bound of human speech frequency
            let dt = 1.0 / Float(sampleRate)
            
            // High-pass filter
            let RC_high = 1.0 / (lowCutoffFrequency * 2.0 * Float.pi)
            let alpha_high = dt / (RC_high + dt)
            var highPassedData = [Float](repeating: 0.0, count: audioData.count)
            highPassedData[0] = audioData[0]
            for i in 1..<audioData.count {
                highPassedData[i] = alpha_high * (highPassedData[i - 1] + audioData[i] - audioData[i - 1])
            }
            
            // Low-pass filter
            let RC_low = 1.0 / (highCutoffFrequency * 2.0 * Float.pi)
            let alpha_low = RC_low / (RC_low + dt)
            var bandPassedData = [Float](repeating: 0.0, count: audioData.count)
            bandPassedData[0] = highPassedData[0]
            for i in 1..<highPassedData.count {
                bandPassedData[i] = bandPassedData[i - 1] + alpha_low * (highPassedData[i] - bandPassedData[i - 1])
            }
            
            return bandPassedData
    }

  private func normalizeAudioData(audioData: [Float]) -> [Float] {
    return audioData.map { $0 / 32767.0 }
  }
}
