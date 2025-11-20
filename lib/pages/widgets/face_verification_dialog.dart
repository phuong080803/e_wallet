import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:e_wallet/styles/constrant.dart';

class FaceVerificationDialog extends StatefulWidget {
  const FaceVerificationDialog({Key? key}) : super(key: key);

  @override
  _FaceVerificationDialogState createState() => _FaceVerificationDialogState();
}

class _FaceVerificationDialogState extends State<FaceVerificationDialog> {
  CameraController? _cameraController;
  late final FaceDetector _faceDetector;
  bool _isInit = false;
  bool _processing = false;
  bool _faceOk = false;
  String _status = 'Đưa khuôn mặt vào khung';

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableContours: false,
      enableTracking: false,
      performanceMode: FaceDetectorMode.fast,
    ));
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);
      _cameraController = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_processCameraImage);
      setState(() => _isInit = true);
    } catch (e) {
      setState(() {
        _status = 'Không thể mở camera: $e';
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_processing) return;
    _processing = true;
    try {
      // Handle different image formats for ML Kit
      Uint8List bytes;
      if (image.format.raw == 35) { // NV21 format (common on Android)
        final yBuffer = image.planes[0].bytes;
        final uvBuffer = image.planes[1].bytes;
        bytes = Uint8List(yBuffer.length + uvBuffer.length);
        bytes.setRange(0, yBuffer.length, yBuffer);
        bytes.setRange(yBuffer.length, bytes.length, uvBuffer);
      } else {
        // For other formats, combine all planes
        int totalSize = 0;
        for (final plane in image.planes) {
          totalSize += plane.bytes.length;
        }
        bytes = Uint8List(totalSize);
        int offset = 0;
        for (final plane in image.planes) {
          bytes.setRange(offset, offset + plane.bytes.length, plane.bytes);
          offset += plane.bytes.length;
        }
      }

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final camera = _cameraController!;
      final imageRotation = InputImageRotationValue.fromRawValue(camera.description.sensorOrientation) ?? InputImageRotation.rotation0deg;
      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;

      if (faces.isEmpty) {
        setState(() {
          _faceOk = false;
          _status = 'Không thấy khuôn mặt. Vui lòng đưa mặt vào khung.';
        });
      } else {
        final face = faces.first;
        // Basic checks: face sufficiently large and near-frontal
        final eulerY = face.headEulerAngleY ?? 0.0; // left(-)/right(+)
        final eulerZ = face.headEulerAngleZ ?? 0.0; // tilt
        final bbox = face.boundingBox;
        final largeEnough = bbox.width > imageSize.width * 0.25 && bbox.height > imageSize.height * 0.25;
        final frontal = eulerY.abs() < 12 && eulerZ.abs() < 12;

        setState(() {
          _faceOk = largeEnough && frontal;
          _status = _faceOk ? 'OK - Giữ nguyên trong giây lát rồi bấm Xác thực' : 'Căn chỉnh mặt chính diện, giữ máy ổn định';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Lỗi xử lý camera: $e';
          _faceOk = false;
        });
      }
    } finally {
      _processing = false;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if running on web platform where ML Kit is not supported
    if (kIsWeb) {
      return Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.face_retouching_off,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Không khả dụng trên web',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[800]),
                ),
                const SizedBox(height: 12),
                Text(
                  'Xác thực khuôn mặt chỉ khả dụng trên thiết bị di động.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(result: false),
                        child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: false),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        child: const Text('Đóng'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Xác thực khuôn mặt',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[800]),
              ),
              const SizedBox(height: 12),
              Container(
                width: 260,
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: _isInit && _cameraController != null && _cameraController!.value.isInitialized
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_cameraController!),
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 200,
                              height: 260,
                              decoration: BoxDecoration(
                                border: Border.all(color: _faceOk ? Colors.green : Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text('Đang mở camera...', style: TextStyle(color: Colors.white70)),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(color: _faceOk ? Colors.green[700] : Colors.grey[700], fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(result: false),
                      child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _faceOk ? () => Get.back(result: true) : null,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      child: const Text('Xác thực'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
