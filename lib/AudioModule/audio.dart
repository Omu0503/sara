import 'dart:async';
import 'dart:developer';
import 'dart:math';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:navapp2/AudioModule/audioPlayer.dart';
// import 'package:audioplayers/audioplayers.dart';
import 'package:navapp2/AudioModule/tts.dart';
import 'package:navapp2/AudioModule/wakeWordModule.dart';
import 'package:navapp2/screens/home.dart';
import 'package:navapp2/utlilities/APIcalls.dart';
import 'package:navapp2/utlilities/GeolocationAlgo.dart';
import 'package:navapp2/utlilities/themes.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:siri_wave/siri_wave.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../Models/PlaceProviders.dart';
import '../utlilities/activationProvider.dart';
import 'activationCircle.dart';

class STT extends StatefulWidget {
  const STT({super.key});

  

  @override
  State<STT> createState() => _STTState();
}

class _STTState extends State<STT> {
  late SpeechToText speech;
  
  bool isInitialized = false;
  List messageHistory = [];
  bool isListening = false;
  bool isProcessing = false;
  late WakeWordService wakeWord;
  Timer? responseTime;
  ValueNotifier<String> outputText = ValueNotifier('');
  ValueNotifier<double> audioSize = ValueNotifier(0);
  ValueNotifier<bool> doneSpeaking = ValueNotifier(true);
  ValueNotifier<String> timeRecorded = ValueNotifier('00:00:00');
  ValueNotifier<bool> isAiSpeaking = ValueNotifier(false);

  late IOS9SiriWaveformController waveformController;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    wakeWord = WakeWordService(startListening);
    wakeWord.startListening();
    waveformController = IOS9SiriWaveformController(speed: 0.5);
    initstt();
    
  }

  void initstt() async {
    speech = SpeechToText();
    var dummyText = '';
    
    isInitialized = await speech.initialize(
      debugLogging: true, 
      onError: (errorNotification) async {
        print('Error: $errorNotification');
        await speech.cancel();
        isSystemActivated.value = false;
        wakeWord.startListening();
      }, 
      onStatus: (status) async {
      
       print("status: $status");
       
       if ( status == 'done') {
        isListening = false;
        onComplete();
        if (!isProcessing) {
        if(dummyText != outputText.value)
        {
        dummyText = outputText.value;        
        print('IS processing?: $isProcessing');
        
          isProcessing = true; // Set flag to true
          await processQuery();
           
        
        }
        else{
          print('dummyText: ${dummyText}');
          print('outputText: ${outputText.value}');
        print("exiting because no words were heard or dummyText = outputText");
        print('Disposing audioPlayer.....');
        await MyAudioPlayer.audioplayer?.dispose();
        print('Canceling speech.....');
        await speech.cancel();

        isListening=false;
        isAiSpeaking.value =false;
        isProcessing = false;
        isSystemActivated.value = false;
        wakeWord.startListening();
        }}
        
        
      }

      if (status == 'notListening'){
        await speech.stop();
        isProcessing = false;
        isAiSpeaking.value = false;
        isListening=false;
        isSystemActivated.value = false;
        wakeWord.startListening();


      }
    });
    
    // setState(() {});
  }

  void onComplete() {
    speech.stop().then((value) => doneSpeaking.value = true);
    
  }

  Future<void> processQuery() async {
    
                    
                    print(outputText.value);
                    // if (outputText.value.isEmpty){
                    //   await speech.stop();
                    //   isProcessing = false;
                    //   return;
                    // }
                    
                    responseTime = Timer.periodic(
                        const Duration(milliseconds: 10), (timer) {
                      timeRecorded.value =
                          Duration(milliseconds: timer.tick)
                              .toString();
                    });
                    
                    final currentcoords = Provider.of<Places>(context, listen: false).currentLocCoords;
                    print('User\'s current location is ${currentcoords[0].toString()} : ${currentcoords[1].toString()}');
                    final currentLoc = LatLng(currentcoords[0], currentcoords[1]);
                    // final exitLoc = legs[0].end;
                    // final resultsFromApis = await Future.wait([APIcalls.fetchNearbyPlaces(currentLoc), APIcalls.getNearestRoads(currentLoc, exitLoc)]);
                    final placesNearby = await  APIcalls.fetchNearbyPlaces(currentLoc);
                    // final roadsNeaby = await APIcalls.getNearestRoads(currentLoc, LatLng(0.0, 0.0));
                    print('Places Nearby: ${placesNearby}');
                    // print('roads Nearby: ${roadsNeaby}');
                    
                    final aiOutput = await llmResponse(
                        outputText.value, messageHistory,
                        legs.map((e) => e.toJson()).toList(),
                        // placesNearby,
                        // roadsNeaby,
                        [],
                        [],
                        [currentcoords[0],currentcoords[1]]
                        
                        );

                    if (aiOutput.role.toLowerCase() ==
                        'system') {
                      outputText.value =
                          'Error ${aiOutput.message}';
                      responseTime?.cancel();
                      throw();
                    }
                    print("ai response: ${aiOutput.message}");
                   
                    messageHistory.add(aiOutput.toJson());
                    isAiSpeaking.value = true;
                    final amplitudeStream = await textToSpeech(aiOutput.message,
                    waveformController: waveformController, 
                    afterAudioPlayed: (){
                      
                       
                        isAiSpeaking.value = false;
                        isProcessing = false;
                        Future.delayed(100.ms, ()=> startListening(isListeningAgain: true));
                    },
                    beforeAudioPlayed: () {
                      
                      
                      responseTime?.cancel();
                    },
                    );
                    
                        print('Response took ${responseTime!.tick/100} seconds');
                    
                   
                    
                                
                  
  }

  void startListening({bool isListeningAgain = false})  {
    
    if (!isInitialized) {
    print("Speech to Text is not initialized. Cannot start listening.");
    startListening();
    return;
  }
    if (isListening) {
    print("Already listening, not starting a new session.");
    return;
  }
    isSystemActivated.value = true;   //over here it programatically says that the system is activated for the code to understand
    print("**************** HUH GAYYYYYYYYYYYYYYYY");
    isListening = true;    //over here it is assigned if it is listening or not
    final predictedScale = (wakeWord.predictionVal*100).round();
    print("Predicted Scale: $predictedScale");
    double pauseTime = predictedScale*0.3 - 15;
    if (predictedScale>70) pauseTime = 10;
    print('Pause time: ${pauseTime.seconds}');
    speech.listen(
                
                listenOptions: SpeechListenOptions(
                
                   listenMode: ListenMode.search,
                   autoPunctuation: true, cancelOnError: true,
                    ),
                listenFor:  const Duration(seconds: 10),
                pauseFor: isListeningAgain? const Duration(seconds: 7) : pauseTime.seconds,
                onResult: (result) async {
                  print('Hi, im not wokring');
                 
                  if(isListening)outputText.value = result.recognizedWords;
                },
                // onSoundLevelChange: (level) {
                //   audioSize.value = level;
                // },
              );
              
              
  }
  
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    print("disposed");
    wakeWord.dispose();
    speech.cancel();

  }

  
  @override
  Widget build(BuildContext context) {
    print("isInitialized: $isInitialized");
    return ValueListenableBuilder(
      valueListenable: isAiSpeaking,
      builder: (context, isAi, child) {
        return !isAi ? 
        CustomShimmer(
          size: 250,
          color: const Color.fromARGB(255, 221, 220, 220),
          duration: 1.seconds,
          curve: Curves.fastOutSlowIn,
        )
        // Container(
          
        //   decoration: BoxDecoration(
        //     shape: BoxShape.circle,
        //     color: myThemes.green,
        //   ),
        //   height: 200,
        //   width: 200,
        // )
        // .animate(
        //      autoPlay: false,
             
             
        //      )
        //      .scaleXY(duration: 500.ms, begin: 0, end: 1, curve: Curves.easeInOut)
             :
               SiriWaveform.ios9(
                controller: IOS9SiriWaveformController(),
                options: const IOS9SiriWaveformOptions(height: 360, width: 50),
               );
      }
    );
  }
}



class WaveformPainter extends CustomPainter {
  final List<int> samples;

  WaveformPainter(this.samples);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final middleY = size.height / 2;

    for (int i = 0; i < 9; i++) {
      final x = i * size.width / samples.length;
      final y = middleY - samples[i] * size.height / 2 / 100;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class CustomWaveform extends StatelessWidget {
  final List<int> samples;

  CustomWaveform({required this.samples});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WaveformPainter(samples),
      child: Container(),
    );
  }
}
