import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:web_socket_channel/io.dart';
import 'package:image/image.dart' as imglib;

class MyCam {
  final CameraController camController;
  MyCam(this.camController);

  void startStreaming() {
    camController.startImageStream((image) {
      print("***********************************${image.format}");
      final bytes = _convertToBytes(image);

      _sendFramesToServer(bytes);
    });
  }

  Map<String, dynamic> _convertToBytes(CameraImage frame) {
    if (frame.format.group == ImageFormatGroup.yuv420) {
      // The Y plane is the first plane in the planes array for YUV420 format
      Plane yPlane = frame.planes[0];

      // Check if the plane's bytesPerRow is equal to the width of the image
      // If it is, we can take the data as is
      if (yPlane.bytesPerRow == frame.width) {
        return {'type': 'YUV420', 'encoding': yPlane.bytes};
      } else {
        // If bytesPerRow is not equal to the width, we need to remove any padding
        // This can happen due to byte alignment in the memory
        List<int> yBytes = [];
        for (int i = 0; i < yPlane.height!.toInt(); i++) {
          int rowStart = i * yPlane.bytesPerRow;
          yBytes.addAll(yPlane.bytes.sublist(rowStart, rowStart + frame.width));
        }
        return {'type': 'YUV420', 'encoding': Uint8List.fromList(yBytes)};
      }
    }
    if (frame.format.group == ImageFormatGroup.bgra8888) {
      Plane plane = frame.planes[0];

      // Convert the plane data to an image
      imglib.Image image = imglib.Image.fromBytes(
        width: frame.width,
        height: frame.height,
        bytes: plane.bytes.buffer,
        format: imglib.Format.uint8,
      );

      // Optionally, you can compress the image to reduce the size
      Uint8List compressedImage =
          Uint8List.fromList(imglib.encodeJpg(image, quality: 85));

      return {'type': 'BGRA8888', 'encoding': compressedImage};
    }

    return {'type': 'Unknown'};
  }

  void _sendFramesToServer(Map<String, dynamic> frameBytes) {
    
  }
}
