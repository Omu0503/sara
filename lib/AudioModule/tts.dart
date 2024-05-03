import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:navapp2/consts.dart';
// import 'package:just_audio/just_audio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

final player = AudioPlayer();

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

Future<Message> llmResponse(String text, List messageHistory) async {
  final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
  final input = Message('user', text);
  final setup = Message('system',
      "You are a specialized assistant in routing and navigation. You have to give a response which should not last more than 14 seconds to 20 seconds");

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

Future<void> textToSpeech(String text, AudioPlayer player) async {
  final uri = Uri.parse('https://api.openai.com/v1/audio/speech');

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
        'response_format': 'opus'
      });

    final streamResponse = await request.send();

    switch (streamResponse.statusCode) {
      case 200:
        final tempdir = await getTemporaryDirectory();
        String filePath = '${tempdir.path}/output.opus';
        bool fileExists = await File(filePath).exists();
        IOSink fileSink = fileExists
            ? File(filePath).openWrite(mode: FileMode.write)
            : File(filePath).openWrite(mode: FileMode.append);

        // File file = File(filePath);
        // final first = await streamResponse.stream.first;
        // await file.writeAsBytes(first);

        streamResponse.stream.listen((value) {
          final data = Uint8List.fromList(value);
          fileSink.add(data);
        });

        try {
          // await player.setFilePath(filePath);
          await player.play(AssetSource(filePath));
        } catch (e) {
          print(
              '*********************************************************************audio buffering');
        }

        // player.setAudioSource(MyAudioClass(stream.stream));

        break;
      default:
        throw Exception('Failed to load audio');
    }
  } catch (e) {
    throw 'Some Error: $e';
  }
}

// class MyAudioClass extends StreamAudioSource {
//   Stream<List<int>> bytestream;

//   MyAudioClass(this.bytestream);

//   @override
//   Future<StreamAudioResponse> request([int? start, int? end]) async {
//     start ??= 0;
//     end = null;
//     return StreamAudioResponse(
//       sourceLength: null,
//       contentLength: null,
//       offset: start,
//       stream: bytestream,
//       contentType: 'audio/ogg',
//     );
//   }
// }
