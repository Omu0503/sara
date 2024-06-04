import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:navapp2/utlilities/themes.dart';
import 'package:web_socket_channel/io.dart';

late List<CameraDescription> _cameras;

class CamWidget extends StatefulWidget {
  const CamWidget({super.key});

  @override
  State<CamWidget> createState() => _CamWidgetState();
}

class _CamWidgetState extends State<CamWidget> {
  late CameraController camController;
  String errorDisplay = '';
  bool permissionGranted = false;
  late IOWebSocketChannel channel;

  @override
  void initState() {
    // TODO: implement initStat
    super.initState();
    // channel = IOWebSocketChannel.connect(url);
    camController = CameraController(_cameras[0], ResolutionPreset.max);
    camController.initialize().then((x) {
      if (!mounted) {
        permissionGranted = true;
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            errorDisplay = "Permission denied to access camera.";
            permissionGranted = false;
            break;
          case 'CameraAccessDeniedWithoutPrompt':
            errorDisplay =
                "Permission denied previously. To fix go to Settings > Privacy > Camera to enable";
            permissionGranted = false;
          default:
            errorDisplay = 'some Eroor';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black),
      body: permissionGranted
          ? Center(
              child: GestureDetector(
                onTap: () {
                  
                },
                child: Container(
                  height: 100,
                  width: 80,
                  child: generalText(
                    'Start Streaming',
                    fontSize: 14,
                  ),
                  color: myThemes.green,
                ),
              ),
            )
          : Center(child: generalText(errorDisplay)),
    );
  }
}
