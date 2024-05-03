import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
// import 'package:just_audio/just_audio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:navapp2/AudioModule/tts.dart';
import 'package:navapp2/utlilities/themes.dart';
import 'package:speech_to_text/speech_to_text.dart';

class STT extends StatefulWidget {
  const STT({super.key});

  @override
  State<STT> createState() => _STTState();
}

class _STTState extends State<STT> {
  late SpeechToText speech;
  late AudioPlayer player;
  bool isInitialized = false;
  List messageHistory = [];
  Timer? responseTime;
  ValueNotifier<String> outputText = ValueNotifier('');
  ValueNotifier<double> audioSize = ValueNotifier(0);
  ValueNotifier<bool> doneSpeaking = ValueNotifier(true);
  ValueNotifier<String> timeRecorded = ValueNotifier('00:00:00');

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    player = AudioPlayer();
    initstt();
  }

  void initstt() async {
    speech = SpeechToText();
    
    isInitialized = await speech.initialize(debugLogging: true, onError: (errorNotification) => throw(errorNotification.errorMsg), onStatus: (status) => log("status: $status"));
    setState(() {});
  }

  void onComplete() {
    speech.cancel().then((value) => doneSpeaking.value = true);
  }
  
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    print("disposed");
    // speech.stop();
    // speech.cancel();

  }

  
  @override
  Widget build(BuildContext context) {
    log("$isInitialized");
    return Scaffold(
      appBar: AppBar(
        backgroundColor: myThemes.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder<String>(
                  valueListenable: timeRecorded,
                  builder: (context, time, snapshot) {
                    return generalText(
                      'Response Time: $time',
                      color: myThemes.black,
                    );
                  }),
              ValueListenableBuilder<bool>(
                  valueListenable: doneSpeaking,
                  builder: (context, done, child) {
                    return done
                        ? IconButton(
                            icon: Icon(Icons.mic),
                            iconSize: 32,
                            onPressed: () async {
                              log('you are gay');
                              // speech.listen();
                              // await player.stop();
                              await Future.delayed(const Duration(milliseconds: 2000));
                              speech.listen(
                                listenOptions: SpeechListenOptions(autoPunctuation: true),
                                listenFor: const Duration(seconds: 10),
                                
                                onResult: (result) async {
                                  outputText.value = result.recognizedWords;
                                  if (speech.isNotListening) {
                                    responseTime = Timer.periodic(
                                        Duration(milliseconds: 10), (timer) {
                                      timeRecorded.value =
                                          Duration(milliseconds: timer.tick)
                                              .toString();
                                    });
                                    onComplete();
                                    final aiOutput = await llmResponse(
                                        outputText.value, messageHistory);
                                    if (aiOutput.role.toLowerCase() ==
                                        'system') {
                                      outputText.value =
                                          'Error ${aiOutput.message}';
                                      responseTime?.cancel();
                                      return;
                                    }
                                    messageHistory.add(aiOutput.toJson());
                                    textToSpeech(aiOutput.message, player).then(
                                        (value) => responseTime?.cancel());

                                    // await player.play();
                                  }
                                },
                                onSoundLevelChange: (level) {
                                  audioSize.value = level;
                                },
                              );
                              log(speech.lastSoundLevel.toString());
                              doneSpeaking.value = false;
                            },
                          )
                        : ValueListenableBuilder(
                            valueListenable: audioSize,
                            builder: (context, size, child) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color.fromARGB(255, 155, 211, 188)),
                                width: size*10+70,
                                height: size*10+70,
                              );
                            });
                  }),
              const SizedBox(
                height: 20,
              ),
              ValueListenableBuilder(
                valueListenable: outputText,
                builder: (context, text, child) => generalText(
                  text,
                  fontSize: 14,
                  color: myThemes.black,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class VaryingAudioWt extends StatelessWidget {
  VaryingAudioWt({super.key, required this.size, required this.factor});

  double size;
  double factor;
  

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 1000),
      curve: Curves.linear,
      width: 20,
      height: size * 30 * factor,
      color: const Color.fromARGB(255, 76, 75, 75),
    );

    
  }
}
