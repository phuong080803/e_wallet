import 'dart:math';
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Service for face recognition using Google ML Kit
/// Handles face detection, feature extraction, and similarity comparison
class FaceRecognitionService {
  final FaceDetector _faceDetector;

  FaceRecognitionService()
      : _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableLandmarks: true,
            enableContours: true,
            enableClassification: true,
            minFaceSize: 0.1,
          ),
        );

  /// Detect faces in an image file and extract features for embedding
  /// Returns a list of face embeddings (feature vectors)
  Future<List<List<double>>> detectFacesAndExtractFeatures(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);

      final embeddings = <List<double>>[];

      for (final face in faces) {
        final embedding = _extractFaceFeatures(face);
        if (embedding.isNotEmpty) {
          embeddings.add(embedding);
        }
      }

      return embeddings;
    } catch (e) {
      print('❌ Error detecting faces: $e');
      return [];
    }
  }

  /// Extract face features from a detected face
  /// Creates a feature vector from bounding box, landmarks, and other face properties
  List<double> _extractFaceFeatures(Face face) {
    final features = <double>[];

    // Bounding box features
    final boundingBox = face.boundingBox;
    features.add(boundingBox.left.toDouble());
    features.add(boundingBox.top.toDouble());
    features.add(boundingBox.right.toDouble());
    features.add(boundingBox.bottom.toDouble());
    features.add(boundingBox.width.toDouble());
    features.add(boundingBox.height.toDouble());

    // Rotation angles
    if (face.headEulerAngleY != null) features.add(face.headEulerAngleY!);
    if (face.headEulerAngleZ != null) features.add(face.headEulerAngleZ!);

    // Eye open probabilities
    if (face.leftEyeOpenProbability != null) features.add(face.leftEyeOpenProbability!);
    if (face.rightEyeOpenProbability != null) features.add(face.rightEyeOpenProbability!);

    // Smile probability
    if (face.smilingProbability != null) features.add(face.smilingProbability!);

    // Landmark positions (if available)
    if (face.landmarks[FaceLandmarkType.leftEye] != null) {
      final leftEye = face.landmarks[FaceLandmarkType.leftEye]!.position;
      features.add(leftEye.x.toDouble());
      features.add(leftEye.y.toDouble());
    }

    if (face.landmarks[FaceLandmarkType.rightEye] != null) {
      final rightEye = face.landmarks[FaceLandmarkType.rightEye]!.position;
      features.add(rightEye.x.toDouble());
      features.add(rightEye.y.toDouble());
    }

    if (face.landmarks[FaceLandmarkType.noseBase] != null) {
      final noseBase = face.landmarks[FaceLandmarkType.noseBase]!.position;
      features.add(noseBase.x.toDouble());
      features.add(noseBase.y.toDouble());
    }

    if (face.landmarks[FaceLandmarkType.leftMouth] != null) {
      final leftMouth = face.landmarks[FaceLandmarkType.leftMouth]!.position;
      features.add(leftMouth.x.toDouble());
      features.add(leftMouth.y.toDouble());
    }

    if (face.landmarks[FaceLandmarkType.rightMouth] != null) {
      final rightMouth = face.landmarks[FaceLandmarkType.rightMouth]!.position;
      features.add(rightMouth.x.toDouble());
      features.add(rightMouth.y.toDouble());
    }

    // Normalize features to [0, 1] range for better comparison
    return _normalizeFeatures(features);
  }

  /// Normalize feature values to [0, 1] range
  List<double> _normalizeFeatures(List<double> features) {
    if (features.isEmpty) return features;

    final minVal = features.reduce(min);
    final maxVal = features.reduce(max);
    final range = maxVal - minVal;

    if (range == 0) return features.map((f) => 0.5).toList();

    return features.map((f) => (f - minVal) / range).toList();
  }

  /// Calculate cosine similarity between two feature vectors
  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Feature vectors must have the same length');
    }

    if (a.isEmpty) return 0.0;

    // Calculate dot product
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    normA = sqrt(normA);
    normB = sqrt(normB);

    if (normA == 0 || normB == 0) return 0.0;

    return dotProduct / (normA * normB);
  }

  /// Compare a captured face with a stored embedding
  /// Returns true if similarity >= threshold (0.85)
  bool compareFaces(List<double> capturedEmbedding, List<double> storedEmbedding, {double threshold = 0.85}) {
    final similarity = cosineSimilarity(capturedEmbedding, storedEmbedding);
    return similarity >= threshold;
  }

  /// Clean up resources
  void dispose() {
    _faceDetector.close();
  }
}
