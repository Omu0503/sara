import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpeechScreen2 extends StatefulWidget {
  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen2> {
  static const platform = MethodChannel('com.example.app/speech');
  String _speechText = 'Press the button to start speaking';

  Future<void> _startListening() async {
    print('Im gay');
    String speechResult = 'Failed to get speech input';
    try {
      final String result = await platform.invokeMethod('getSpeech');
      speechResult = result;
    } on PlatformException catch (e) {
      speechResult = "Failed to get speech: '${e.message}'.";
    }
    setState(() {
      _speechText = speechResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Native Speech to Text'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_speechText, textAlign: TextAlign.center),
            ),
            ElevatedButton(
              onPressed: _startListening,
              child: Text('Start Listening'),
            ),
          ],
        ),
      ),
    );
  }
}
