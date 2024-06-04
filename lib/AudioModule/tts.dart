import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:navapp2/AudioModule/audioPlayer.dart';
import 'package:navapp2/AudioModule/decodingMP3.dart';
import 'package:navapp2/consts.dart';
import 'package:just_audio/just_audio.dart';
// import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:siri_wave/siri_wave.dart';

// final player = AudioPlayer();

class Message {
  String role;
  String message;

  Message(this.role, this.message);

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(json["choices"][0]["message"]["role"],
        json["choices"][0]["message"]["content"]);
  }

  toJson() => {"role": role, "content": message};
}

Future<Message> llmResponse(String text, List messageHistory,List <Map<String, dynamic>> routes, List< dynamic> contextualInfo, List< dynamic> roadsInfo, List<dynamic> currentLocation) async {
  final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
  final input = Message('user', text);
  final setup = Message('system',
      '''You are a specialized assistant in routing and navigation who is sweet and fun to talk to. You have to give a response which should not last more than 14 seconds to 20 seconds long. 
      You are provided with several json responses from different APIs. The first response id from the google maps routes api. The response will containe the remaining legs fro the user till
      the destination. The second response is from the places_nearby API, which bascially tells what all is close to the user from 500 meter range.
      The third response is from the roads nearby api, which tells how many roads are there between the users current location and the upcoming turn.
      These roads are indexed from closes to farthest and such information helps users avoid taking wrong turns. Here are the responses:
      1. ${routes.toString()},
      2. ${contextualInfo.toString()},

      3. ${roadsInfo.toString()},
      Help the user using these infos provided. The current location of the drive now in [Lat,Long] is ${currentLocation.toString()}
      ''');

  if (messageHistory.isEmpty) messageHistory.insert(0, setup.toJson());
  messageHistory.add(input.toJson());
  try {
    final response = await http.post(uri,
        headers: {
          "Authorization": "Bearer $openaiAPIkey",
          "Content-Type": "application/json",
        },
        body: jsonEncode(
            {"messages": messageHistory, "model": "gpt-3.5-turbo", "max_tokens" : 100}));

    switch (response.statusCode) {
      case 200:
        final output = jsonDecode(response.body);
        return Message.fromJson(output);

      default:
        return Message('system',
            'API error: ${response.statusCode}, ${response.reasonPhrase} ');
    }
  } catch (e) {
    throw e;
  }
}

Future<void> textToSpeech(String text, {required void Function() afterAudioPlayed,required void Function() beforeAudioPlayed, IOS9SiriWaveformController? waveformController}) async {
  final uri = Uri.parse('https://api.openai.com/v1/audio/speech');
  final myPlayer = MyAudioPlayer();

  try {
    final request = http.Request('POST', uri)
      ..headers.addAll({
        'Authorization': 'Bearer $openaiAPIkey',
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode({
        'model': 'tts-1',
        'voice': 'nova',
        'input': text,
        'response_format': Platform.isAndroid? 'opus' : 'mp3',
        'speed': 1
      });

    final streamResponse = await request.send();

    switch (streamResponse.statusCode) {
      case 200:
        print("received response for tts from openAI....");
        // final streamAudioSource = AudioStreamSource();
        
        final tempdir = await getTemporaryDirectory();
        String filePath = Platform.isAndroid? '${tempdir.path}/output.opus' : '${tempdir.path}/output.mp3';
        
        bool fileExists = await File(filePath).exists();
        IOSink fileSink = fileExists
            ? File(filePath).openWrite(mode: FileMode.write)
            : File(filePath).openWrite(mode: FileMode.append);

        // if (fileExists) {
        //   await File(filePath).delete();
        // }

        
        // IOSink fileSink = File(filePath).openWrite();
        bool isFirstChunk = true;

        // File file = File(filePath);
        // final first = await streamResponse.stream.first;
        // await file.writeAsBytes(first);

        print('sending audio bytes in chunks.....'); 
        streamResponse.stream.listen((value) async {
          final data = Uint8List.fromList(value);
          fileSink.add(data);

          // streamAudioSource.addBytes(value);

          
          

          //  if (isFirstChunk) {
          //     isFirstChunk = false;
          //     try {
                
                
            
                
          //     } catch (e) {
          //       print('Error playing audio: $e');
          //       print('File exists: ${File(filePath).existsSync()}');
          //     }
          //   }
            
            
        },


        
        onDone: () async {
          await fileSink.close();
          print('Audio file saved at $filePath');
          final amplitudeStream = extractAmplitudeData(filePath);
          print('got amplitude Stream');
          amplitudeStream.listen((event) {
            print('amplitude: $event');
            waveformController?.amplitude = event;
          });

          await myPlayer.assignAudioAndPlay(filePath);
      
          
          
          final playerStream = MyAudioPlayer.audioplayer!.playerStateStream;
                    playerStream.listen((event) async {
                      print("audioStatus: ${event.processingState}");
                      if (event.processingState == ProcessingState.ready){
                        print("audio ready");
                        beforeAudioPlayed();
                        
                      }
                      if (event.processingState == ProcessingState.completed && event.processingState != ProcessingState.idle) {
                         
                         print("played audio completely");
                         afterAudioPlayed();
                        
                        
                      }
                    });  
            
            
          },
          onError: (error) {
            print('Stream error: $error');
          },
          cancelOnError: true,
        );
        
        

        // try {
        //   await player.setFilePath(filePath);
        //   await player.play();
        // } catch (e) {
        //   throw e;
        // }

        // player.setAudioSource(MyAudioClass(stream.stream));

        
      default:
        throw Exception('Failed to load audio');
    }
  } catch (e) {
    throw 'Some Error: $e';
  }

  
}


class AudioStreamSource extends StreamAudioSource {
  final StreamController<List<int>> _streamController = StreamController();
  int totalBytes = 0;
  int startingByte = 0;
  AudioStreamSource();

  void addBytes(List<int> bytes) {
    totalBytes += bytes.length;
    _streamController.add(bytes);
  }

  void close() {
    _streamController.close();
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    // TODO: implement request
   
    start ??= 0;
    end ??= totalBytes;
    return StreamAudioResponse(
      sourceLength: await _streamController.stream.length,
      contentLength: totalBytes,
      offset: start,
      stream: _streamController.stream,
      contentType: Platform.isAndroid? 'audio/opus' : 'audio/mpeg',
    );
  }

  


}
