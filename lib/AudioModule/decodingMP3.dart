import 'dart:async';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/session.dart';


Stream<double> extractAmplitudeData(String filePath) async* {
  
  

  // Command to extract audio amplitude data
  String command = "-i $filePath -filter:a volumedetect -f null /dev/null";

  FFmpegKit.execute(command).then((session) async* {

    final returnCode = await session.getReturnCode();
    print('Return code: ${returnCode?.getValue()}');
    if (ReturnCode.isSuccess(returnCode)) {
    // Parse the FFmpeg output to get the amplitude data
    String? output = await session.getOutput();
    print('Output of ffmpeg: $output');
    output ?? '';
    if(output!.isNotEmpty) {
      RegExp regExp = RegExp(r"max_volume: ([\-0-9.]+) dB");
    final matches = regExp.allMatches(output);
    for (var match in matches) {
      double amplitude = double.parse(match.group(1)!);
      
      yield amplitude;
    }
    }
    else {
      throw("No amplitude data found");
    }
    
  }
  else if (ReturnCode.isCancel(returnCode)) {

    // CANCEL
    final logs = await session.getLogsAsString();
    print('Canceled: ${logs}');

  } else {
    final logs = await session.getLogsAsString();
    print('Error: $logs');
    // ERROR

  }

  });
  
  

  
}
