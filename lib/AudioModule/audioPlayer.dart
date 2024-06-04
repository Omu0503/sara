import 'package:just_audio/just_audio.dart';

class MyAudioPlayer {
   static AudioPlayer? audioplayer;

  Future<void> assignAudioAndPlay(String filePath) async {
    if(audioplayer == null) throw('it is null');
    await audioplayer!.setFilePath(filePath, preload: true);

    await audioplayer!.play();
  }

  void setAudioPlayerNull () {
    audioplayer = null;
  }

  MyAudioPlayer(){
    audioplayer = AudioPlayer();
  }

}