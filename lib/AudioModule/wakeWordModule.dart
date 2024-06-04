import 'package:flutter/services.dart';

class WakeWordService {
  static const platform = MethodChannel('com.example.saraa');
  double _predictionVal = 0;

  double get predictionVal => _predictionVal;


  Future<void> startListening() async {
    try {
      final String result = await platform.invokeMethod('startWakeWordDetection');
      print(result); // "Wake word detection started"
    } on PlatformException catch (e) {
      throw("Failed to start wake word detection: '${e.message}'.");
    }
  }

  Future<void> stopListening() async {
    try {
      final String result = await platform.invokeMethod('stopWakeWordDetection');
      print(result); // "Wake word detection stopped"
    } on PlatformException catch (e) {
      throw("Failed to stop wake word detection: '${e.message}'.");
    }
  }

  Future<void> dispose() async {
    final response = await platform.invokeMethod('destroy');
    print("*************************  $response");
  }

  // Future<void> logPrediciton() async {
  //   final prediction = await platform.invokeMethod('logPrediction');
  //   print("Prediction: $prediction");
  // }

  WakeWordService(void Function() onDetect)  {
    
    platform.setMethodCallHandler((call) async {
      if (call.method == 'logPrediction'){
        print('Prediction: ${call.arguments}');
        _predictionVal = double.parse(call.arguments);
      }
      if (call.method == "wakeWordDetected") {
        print("Wake word detected!");
        // Start speech recognition here
        stopListening();
        onDetect();

      }
    });
    
  }
}
