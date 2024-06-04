import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image/image.dart' as imglib;

class MyCam {
  final CameraController camController;
  WebSocketChannel? _channel;

  MyCam(this.camController){
    startStreaming();
  }

  void startStreaming() {
    // Establish the WebSocket connection
    _channel = WebSocketChannel.connect(Uri.parse("ws://20.92.228.75:8000/ws"));

    camController.startImageStream((image) {
      print("***********************************${image.format}");
      final bytes = _convertToBytes(image);

      if (bytes != null) {
        _sendFramesToServer(bytes);
      }
    });
  }

  Map<String, dynamic>? _convertToBytes(CameraImage frame) {
    if (frame.format.group == ImageFormatGroup.yuv420) {
      Plane yPlane = frame.planes[0];

      if (yPlane.bytesPerRow == frame.width) {
        return {'type': 'YUV420', 'encoding': yPlane.bytes};
      } else {
        List<int> yBytes = [];
        for (int i = 0; i < frame.height; i++) {
          int rowStart = i * yPlane.bytesPerRow;
          yBytes.addAll(yPlane.bytes.sublist(rowStart, rowStart + frame.width));
        }
        return {'type': 'YUV420', 'encoding': Uint8List.fromList(yBytes)};
      }
    }

    if (frame.format.group == ImageFormatGroup.bgra8888) {
      Plane plane = frame.planes[0];

      imglib.Image image = imglib.Image.fromBytes(
        width: frame.width,
        height: frame.height,
        bytes: plane.bytes.buffer,
        format: imglib.Format.uint8,
      );

      Uint8List compressedImage =
          Uint8List.fromList(imglib.encodeJpg(image, quality: 85));

      return {'type': 'BGRA8888', 'encoding': compressedImage};
    }

    return null;
  }

  void _sendFramesToServer(Map<String, dynamic> frameBytes) {
    if (_channel != null && _channel!.sink != null) {
      // Convert the frameBytes map to a JSON string
      String jsonFrame = jsonEncode(frameBytes);
      // Send the JSON string to the server via WebSocket
      _channel!.sink.add(jsonFrame);
    }
  }

  void stopStreaming() {
    // Close the WebSocket connection
    _channel?.sink.close();
    // Stop the camera stream
    camController.stopImageStream();
  }
}
