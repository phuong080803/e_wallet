import 'dart:typed_data';
import 'dart:ui';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:e_wallet/styles/constrant.dart';
import 'package:e_wallet/services/face_recognition_service.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({Key? key}) : super(key: key);

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> with WidgetsBindingObserver {
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final _supabase = Supabase.instance.client;

  // Camera + ML Kit
  CameraController? _cameraController;
  late final FaceDetector _faceDetector;
  bool _isInit = false;
  bool _processing = false;
  DateTime _lastProcessTime = DateTime.now();

  // Guided steps: 0=nhìn thẳng, 1=quay trái, 2=quay phải
  int _step = 0;
  bool _poseOk = false;
  String _status = 'Bước 1/3: Nhìn thẳng vào camera';
  final List<String> _stepTips = const [
    'Nhìn thẳng vào camera, giữ yên',
    'Quay mặt sang TRÁI (giữ yên)',
    'Quay mặt sang PHẢI (giữ yên)',
  ];
  final List<double> _yawThreshold = const [12.0, -15.0, 15.0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Chỉ khởi tạo ML Kit trên mobile platforms
    if (!kIsWeb) {
      _faceDetector = FaceDetector(options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableContours: false,
        enableTracking: false,
        performanceMode: FaceDetectorMode.accurate,
      ));
    }
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _retryCamera() async {
    setState(() => _isInit = false);
    _cameraController?.dispose();
    _cameraController = null;
    await _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Pause camera when app is not active to save memory
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _cameraController?.stopImageStream();
    } else if (state == AppLifecycleState.resumed && _cameraController != null) {
      if (_cameraController!.value.isInitialized) {
        _cameraController!.startImageStream(_processImage);
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      // Check permissions first
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        setState(() => _status = 'Cần cấp quyền truy cập camera');
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _status = 'Không tìm thấy camera');
        return;
      }

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Use low resolution for better performance
      _cameraController = CameraController(
        front,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      // Set frame rate for better performance
      await _cameraController!.setFlashMode(FlashMode.off);

      if (mounted) {
        await _cameraController!.startImageStream(_processImage);
        setState(() => _isInit = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Không thể mở camera: ${e.toString().split('\n').first}');
      }
      debugPrint('❌ Camera initialization error: $e');
    }
  }

  Future<bool> _requestCameraPermission() async {
    try {
      // For now, assume permission is granted
      // In a real app, you'd use permission_handler package
      return true;
    } catch (e) {
      debugPrint('❌ Permission error: $e');
      return false;
    }
  }

  Widget _buildCameraErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 48, color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            _status.contains('quyền') ? 'Cần cấp quyền camera' : 'Không thể truy cập camera',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _status.split(': ').last,
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _retryCamera,
            icon: Icon(Icons.refresh),
            label: Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: k_blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processImage(CameraImage image) async {
    // Throttle processing to avoid overwhelming the system
    final now = DateTime.now();
    if (now.difference(_lastProcessTime) < const Duration(milliseconds: 200)) {
      return;
    }
    _lastProcessTime = now;

    if (_processing || _cameraController == null || !mounted) return;
    _processing = true;

    try {
      final inputImage = _convertCameraImage(image, _cameraController!.description);

      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;

      if (faces.isEmpty) {
        setState(() {
          _poseOk = false;
          _status = 'Không thấy khuôn mặt. ' + _stepTips[_step];
        });
      } else {
        final f = faces.first;
        final yaw = f.headEulerAngleY ?? 0.0;
        final roll = f.headEulerAngleZ ?? 0.0;
        final bbox = f.boundingBox;
        final largeEnough = bbox.width > image.width * 0.25 && bbox.height > image.height * 0.25;

        bool ok = false;
        if (_step == 0) {
          ok = yaw.abs() < 12 && roll.abs() < 12 && largeEnough;
        } else if (_step == 1) {
          ok = yaw < _yawThreshold[1] && roll.abs() < 15 && largeEnough; // turn left
        } else {
          ok = yaw > _yawThreshold[2] && roll.abs() < 15 && largeEnough; // turn right
        }

        setState(() {
          _poseOk = ok;
          _status = (_poseOk ? '✅ ' : '❌ ') + 'Bước ${_step + 1}/3: ' + _stepTips[_step];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = '⚠️ Lỗi camera: ${e.toString().split('\n').first}');
      }
      debugPrint('❌ Camera processing error: $e');
    } finally {
      _processing = false;
    }
  }

  // Convert CameraImage to InputImage using the official MLKit approach
  InputImage _convertCameraImage(CameraImage image, CameraDescription camera) {
      // Tính tổng kích thước của tất cả planes
    int totalSize = 0;
    for (final Plane plane in image.planes) {
      totalSize += plane.bytes.length;
    }

    // Tạo Uint8List với kích thước tổng
    final Uint8List bytes = Uint8List(totalSize);
    int offset = 0;

    // Copy từng plane vào bytes
    for (final Plane plane in image.planes) {
      bytes.setRange(offset, offset + plane.bytes.length, plane.bytes);
      offset += plane.bytes.length;
    }

    // Kích thước ảnh
    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    // Lấy hướng xoay của camera
    final InputImageRotation rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.rotation0deg;

    // Lấy định dạng ảnh
    final InputImageFormat format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    // Tạo InputImage từ bytes
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  // Fix rotation for front camera (camera trước thường bị mirror)
  InputImageRotation _fixRotation(CameraDescription camera) {
    var rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation)
        ?? InputImageRotation.rotation0deg;
    if (camera.lensDirection == CameraLensDirection.front) {
      // Một số thiết bị cần đảo ngược xoay
      if (rotation == InputImageRotation.rotation90deg) return InputImageRotation.rotation270deg;
      if (rotation == InputImageRotation.rotation270deg) return InputImageRotation.rotation90deg;
    }
    return rotation;
  }

  Future<void> _nextOrEnroll() async {
    if (!_poseOk) return;
    if (_step < 2) {
      setState(() {
        _step += 1;
        _poseOk = false;
        _status = 'Bước ${_step + 1}/3: ' + _stepTips[_step];
      });
      return;
    }

    // Completed 3 steps -> enroll face
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _status = 'Vui lòng đăng nhập lại');
        return;
      }

      setState(() => _status = 'Đang xử lý đăng ký khuôn mặt...');

      final metadata = user.userMetadata ?? {};
      final newMetadata = Map<String, dynamic>.from(metadata);

      // Generate a simple face embedding (demo - in real app this would come from ML model)
      final faceEmbedding = List<double>.generate(128, (i) => (i * 0.01 + 0.1));

      newMetadata['face_embedding'] = faceEmbedding;
      newMetadata['face_enrolled_at'] = DateTime.now().toIso8601String();
      newMetadata['face_enrollment_version'] = '1.0';

      await _supabase.auth.updateUser(UserAttributes(data: newMetadata));

      setState(() => _status = 'Đăng ký khuôn mặt thành công!');

      // Wait a moment then close
      await Future.delayed(const Duration(seconds: 1));
      Get.back(result: true);
      Get.snackbar('Thành công', 'Khuôn mặt đã được đăng ký thành công');
    } catch (e) {
      setState(() => _status = 'Lỗi đăng ký khuôn mặt: $e');
      Get.snackbar('Lỗi', 'Không thể đăng ký khuôn mặt. Vui lòng thử lại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if running on web platform where ML Kit is not supported
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Đăng ký khuôn mặt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: k_blue,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Icon(
                Icons.face_retouching_off,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Không khả dụng trên web',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: k_blue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Đăng ký khuôn mặt chỉ khả dụng trên thiết bị di động. Vui lòng sử dụng ứng dụng trên điện thoại hoặc máy tính bảng để đăng ký khuôn mặt.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: k_blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Quay lại', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký khuôn mặt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: k_blue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              Text(
                'Đăng ký khuôn mặt',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: k_blue,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Để bảo mật giao dịch giá trị cao, hãy đăng ký khuôn mặt của bạn. Với giao dịch ≥ 20,000,000 VND, hệ thống sẽ yêu cầu xác thực sinh trắc học (khuôn mặt hoặc vân tay) trước khi tiếp tục.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Các bước:', style: TextStyle(fontWeight: FontWeight.bold, color: k_blue)),
                    const SizedBox(height: 8),
                    Text('1) Nhìn thẳng  •  2) Quay trái  •  3) Quay phải', style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (_step + 1) / 3,
                      backgroundColor: Colors.blue.shade100,
                      color: k_blue,
                      minHeight: 6,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                height: 340,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: _isInit && _cameraController != null && _cameraController!.value.isInitialized
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_cameraController!),
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 240,
                              height: 300,
                              decoration: BoxDecoration(
                                border: Border.all(color: _poseOk ? Colors.green : Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _status.contains('Không thể mở camera')
                        ? _buildCameraErrorWidget()
                        : const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),

              const SizedBox(height: 16),
              Text(_status, textAlign: TextAlign.center, style: TextStyle(color: _poseOk ? Colors.green[700] : Colors.grey.shade700)),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _poseOk ? _nextOrEnroll : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: k_blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_step < 2 ? 'Tiếp tục' : 'Hoàn tất', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Để sau',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
