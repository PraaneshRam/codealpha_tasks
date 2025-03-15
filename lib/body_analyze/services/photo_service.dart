
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'analysis_service.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic('dnmt97lfd', 'ml_default');
  late final FaceDetector faceDetector;

  PhotoService() {
    faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
        enableTracking: true,
        minFaceSize: 0.15, // Increased for better accuracy
        performanceMode: FaceDetectorMode.accurate, // Using accurate mode
      ),
    );
    print('✅ PhotoService initialized with face detector');
  }

  void _showMessage(BuildContext context, String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getReferenceFace() async {
    try {
      print('🔍 Fetching reference face from Firestore...');
      final snapshot =
          await FirebaseFirestore.instance
              .collection('photos')
              .orderBy('date', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        print('ℹ️ No reference face found - this will be the first photo');
        return null;
      }
      final face = snapshot.docs.first.data()['face'] as Map<String, dynamic>?;
      print('📊 Reference face data: $face');
      return face;
    } catch (e) {
      print('❌ Error fetching reference face: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _processFace(Face face) async {
    try {
      final double headAngleY = (face.headEulerAngleY ?? 0).abs();
      final double headAngleZ = (face.headEulerAngleZ ?? 0).abs();

      // Get all possible facial landmarks
      final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
      final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
      final noseBase = face.landmarks[FaceLandmarkType.noseBase]?.position;
      final bottomMouth =
          face.landmarks[FaceLandmarkType.bottomMouth]?.position;
      final leftCheek = face.landmarks[FaceLandmarkType.leftCheek]?.position;
      final rightCheek = face.landmarks[FaceLandmarkType.rightCheek]?.position;
      final leftEar = face.landmarks[FaceLandmarkType.leftEar]?.position;
      final rightEar = face.landmarks[FaceLandmarkType.rightEar]?.position;

      // Require all landmarks for better accuracy
      if (leftEye == null ||
          rightEye == null ||
          noseBase == null ||
          bottomMouth == null ||
          leftCheek == null ||
          rightCheek == null ||
          leftEar == null ||
          rightEar == null) {
        print('⚠️ Missing facial landmarks');
        return null;
      }

      final faceWidth = face.boundingBox.width;
      final faceHeight = face.boundingBox.height;

      // Calculate multiple facial feature distances and ratios
      final eyeDistance = (leftEye.x - rightEye.x).abs();
      final noseToMouthDistance = (noseBase.y - bottomMouth.y).abs();
      final cheekDistance = (leftCheek.x - rightCheek.x).abs();
      final earDistance = (leftEar.x - rightEar.x).abs();

      // Calculate vertical distances
      final leftEyeToNose = (leftEye.y - noseBase.y).abs();
      final rightEyeToNose = (rightEye.y - noseBase.y).abs();

      // Calculate diagonal distances
      final leftEyeToRightCheek = _calculateDistance(leftEye, rightCheek);
      final rightEyeToLeftCheek = _calculateDistance(rightEye, leftCheek);

      // Calculate confidence based on multiple factors
      double confidence = 0.0;

      // Head angle factor (max 0.4)
      if (headAngleY < 5 && headAngleZ < 5) {
        confidence += 0.4; // Perfect head position
      } else if (headAngleY < 10 && headAngleZ < 10) {
        confidence += 0.3; // Good head position
      } else if (headAngleY < 20 && headAngleZ < 20) {
        confidence += 0.2; // Acceptable head position
      } else {
        confidence += 0.1; // Poor head position
      }

      // Landmark quality factor (max 0.3)
      int detectedLandmarks = face.landmarks.length;
      if (detectedLandmarks >= 8) {
        confidence += 0.3; // All landmarks detected clearly
      } else if (detectedLandmarks >= 6) {
        confidence += 0.2; // Most landmarks detected
      } else {
        confidence += 0.1; // Minimal landmarks detected
      }

      // Face size factor (max 0.3)
      double relativeFaceSize = face.boundingBox.width / faceWidth;
      if (relativeFaceSize > 0.5) {
        confidence += 0.3; // Face fills good portion of frame
      } else if (relativeFaceSize > 0.3) {
        confidence += 0.2; // Medium face size
      } else {
        confidence += 0.1; // Face too small in frame
      }

      // Round to 2 decimal places
      confidence = double.parse(confidence.toStringAsFixed(2));

      return {
        'width': faceWidth,
        'height': faceHeight,
        'confidence': confidence,
        'headAngleY': headAngleY,
        'headAngleZ': headAngleZ,
        'eyeDistance': eyeDistance,
        'noseToMouthDistance': noseToMouthDistance,
        'cheekDistance': cheekDistance,
        'earDistance': earDistance,
        'leftEyeToNose': leftEyeToNose,
        'rightEyeToNose': rightEyeToNose,
        'leftEyeToRightCheek': leftEyeToRightCheek,
        'rightEyeToLeftCheek': rightEyeToLeftCheek,
        // Normalized ratios
        'eyeDistanceRatio': eyeDistance / faceWidth,
        'noseToMouthRatio': noseToMouthDistance / faceHeight,
        'cheekDistanceRatio': cheekDistance / faceWidth,
        'earDistanceRatio': earDistance / faceWidth,
        'eyeToNoseRatio': (leftEyeToNose + rightEyeToNose) / (2 * faceHeight),
        'diagonalRatio':
            (leftEyeToRightCheek + rightEyeToLeftCheek) / (2 * faceWidth),
      };
    } catch (e) {
      print('❌ Error processing face features: $e');
      return null;
    }
  }

  double _calculateDistance(Point<int> p1, Point<int> p2) {
    return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
  }

  bool _compareFaces(Map<String, dynamic> face1, Map<String, dynamic> face2) {
    try {
      print('\n🔍 Comparing faces with strict criteria:');
      print('Face 1: $face1');
      print('Face 2: $face2');

      // Stricter confidence threshold
      // const double confidenceThreshold = 0.85;
      // if ((face1['confidence'] ?? 0.0) < confidenceThreshold ||
      //     (face2['confidence'] ?? 0.0) < confidenceThreshold) {
      //   print('❌ Confidence too low');
      //   return false;
      // }

      // // Very strict head angle comparison
      // const double angleThreshold = 10.0;
      // if ((face1['headAngleY'] - face2['headAngleY']).abs() > angleThreshold ||
      //     (face1['headAngleZ'] - face2['headAngleZ']).abs() > angleThreshold) {
      //   print('❌ Head angles too different');
      //   return false;
      // }

      // Strict ratio comparisons
      const double ratioTolerance = 0.1; // 10% tolerance
      final ratiosToCompare = [
        'eyeDistanceRatio',
        'noseToMouthRatio',
        'cheekDistanceRatio',
        'earDistanceRatio',
        'eyeToNoseRatio',
        'diagonalRatio',
      ];

      for (final ratio in ratiosToCompare) {
        final ratio1 = face1[ratio] ?? 0.0;
        final ratio2 = face2[ratio] ?? 0.0;
        if ((ratio1 - ratio2).abs() > ratioTolerance) {
          print(
            '❌ $ratio too different: ${ratio1.toStringAsFixed(3)} vs ${ratio2.toStringAsFixed(3)}',
          );
          return false;
        }
      }

      // Compare overall face proportions
      const double sizeTolerance = 0.15;
      final aspectRatio1 = face1['width'] / face1['height'];
      final aspectRatio2 = face2['width'] / face2['height'];
      if ((aspectRatio1 - aspectRatio2).abs() > sizeTolerance) {
        print('❌ Face proportions too different');
        return false;
      }

      print(
        '✅ Face comparison passed - same person confirmed with high confidence',
      );
      return true;
    } catch (e) {
      print('❌ Error comparing faces: $e');
      return false;
    }
  }

  Future<Face?> _detectFace(String imagePath) async {
    try {
      print('🔍 Attempting to detect face in image: $imagePath');
      final inputImage = InputImage.fromFilePath(imagePath);
      final List<Face> faces = await faceDetector.processImage(inputImage);

      print('📊 Number of faces detected: ${faces.length}');
      if (faces.isEmpty) {
        print('⚠️ No faces detected');
        return null;
      }

      if (faces.length > 1) {
        print('⚠️ Multiple faces detected - using largest face');
      }

      final Face face = faces.reduce(
        (curr, next) =>
            curr.boundingBox.width > next.boundingBox.width ? curr : next,
      );

      // Verify face has required landmarks using correct types
      final hasRequiredLandmarks =
          face.landmarks[FaceLandmarkType.leftEye] != null &&
          face.landmarks[FaceLandmarkType.rightEye] != null &&
          face.landmarks[FaceLandmarkType.noseBase] != null &&
          face.landmarks[FaceLandmarkType.bottomMouth] != null;

      if (!hasRequiredLandmarks) {
        print('⚠️ Face missing required landmarks');
        return null;
      }

      print('✅ Valid face detected with all required landmarks');
      return face;
    } catch (e) {
      print('❌ Error detecting face: $e');
      return null;
    }
  }

  Future<bool> uploadPhoto({
    required ImageSource source,
    required BuildContext context,
  }) async {
    Face? detectedFace;
    try {
      print('\n🚀 Starting photo upload process...');
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 100,
        maxWidth: 2048,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo == null) {
        print('⚠️ No photo selected');
        _showMessage(context, 'No photo selected', true);
        return false;
      }

      _showMessage(context, 'Processing photo...', false);

      // Multiple attempts to detect face
      for (int i = 0; i < 3; i++) {
        print('🔍 Attempt ${i + 1} to detect face...');
        detectedFace = await _detectFace(photo.path);
        if (detectedFace != null) break;
        await Future.delayed(Duration(milliseconds: 500));
      }

      if (detectedFace == null) {
        _showMessage(
          context,
          'Could not detect face clearly. Please ensure:\n'
          '• Good lighting\n'
          '• Face is clearly visible\n'
          '• Looking directly at camera',
          true,
        );
        return false;
      }

      // Process face features
      final currentFace = await _processFace(detectedFace);
      if (currentFace == null) {
        _showMessage(
          context,
          'Could not process facial features clearly',
          true,
        );
        return false;
      }

      // Get and compare with reference face
      final referenceFace = await _getReferenceFace();
      if (referenceFace != null) {
        print('🔍 Comparing with reference face...');
        if (!_compareFaces(referenceFace, currentFace)) {
          _showMessage(
            context,
            'Different person detected. Please use the same person for all photos.',
            true,
          );
          return false;
        }
      }

      // Upload photo
      print('📤 Uploading photo to Cloudinary...');
      final result = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          photo.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // Analyze progress and generate message
      final analysisService = AnalysisService();
      final analysis = await analysisService.analyzeProgress(currentFace);

      // Save to Firestore
      print('💾 Saving to Firestore...');
      await FirebaseFirestore.instance.collection('photos').add({
        'url': result.secureUrl,
        'date': FieldValue.serverTimestamp(),
        'face': currentFace,
        'analysis': analysis,
      });

      // Show analysis message
      _showMessage(context, '✅ Photo uploaded!\n${analysis['message']}', false);

      return true;
    } catch (e) {
      print('❌ Error: $e');
      _showMessage(
        context,
        'Upload failed. Please try again with better lighting and face visibility.',
        true,
      );
      return false;
    } finally {
      await faceDetector.close();
    }
  }
}


/*import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'analysis_service.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic('dnmt97lfd', 'ml_default');
  late final FaceDetector faceDetector;

  PhotoService() {
    faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
        enableTracking: true,
        minFaceSize: 0.15, // Increased for better accuracy
        performanceMode: FaceDetectorMode.accurate, // Using accurate mode
      ),
    );
    print('✅ PhotoService initialized with face detector');
  }

  void _showMessage(BuildContext context, String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getReferenceFace() async {
    try {
      print('🔍 Fetching reference face from Firestore...');
      final snapshot =
          await FirebaseFirestore.instance
              .collection('photos')
              .orderBy('date', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        print('ℹ️ No reference face found - this will be the first photo');
        return null;
      }
      final face = snapshot.docs.first.data()['face'] as Map<String, dynamic>?;
      print('📊 Reference face data: $face');
      return face;
    } catch (e) {
      print('❌ Error fetching reference face: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _processFace(Face face) async {
    try {
      final double headAngleY = (face.headEulerAngleY ?? 0).abs();
      final double headAngleZ = (face.headEulerAngleZ ?? 0).abs();

      // Get all possible facial landmarks
      final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
      final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
      final noseBase = face.landmarks[FaceLandmarkType.noseBase]?.position;
      final bottomMouth =
          face.landmarks[FaceLandmarkType.bottomMouth]?.position;
      final leftCheek = face.landmarks[FaceLandmarkType.leftCheek]?.position;
      final rightCheek = face.landmarks[FaceLandmarkType.rightCheek]?.position;
      final leftEar = face.landmarks[FaceLandmarkType.leftEar]?.position;
      final rightEar = face.landmarks[FaceLandmarkType.rightEar]?.position;

      // Require all landmarks for better accuracy
      if (leftEye == null ||
          rightEye == null ||
          noseBase == null ||
          bottomMouth == null ||
          leftCheek == null ||
          rightCheek == null ||
          leftEar == null ||
          rightEar == null) {
        print('⚠️ Missing facial landmarks');
        return null;
      }

      final faceWidth = face.boundingBox.width;
      final faceHeight = face.boundingBox.height;

      // Calculate multiple facial feature distances and ratios
      final eyeDistance = (leftEye.x - rightEye.x).abs();
      final noseToMouthDistance = (noseBase.y - bottomMouth.y).abs();
      final cheekDistance = (leftCheek.x - rightCheek.x).abs();
      final earDistance = (leftEar.x - rightEar.x).abs();

      // Calculate vertical distances
      final leftEyeToNose = (leftEye.y - noseBase.y).abs();
      final rightEyeToNose = (rightEye.y - noseBase.y).abs();

      // Calculate diagonal distances
      final leftEyeToRightCheek = _calculateDistance(leftEye, rightCheek);
      final rightEyeToLeftCheek = _calculateDistance(rightEye, leftCheek);

      // Calculate confidence based on multiple factors
      double confidence = 0.0;

      // Head angle factor (max 0.4)
      if (headAngleY < 5 && headAngleZ < 5) {
        confidence += 0.4; // Perfect head position
      } else if (headAngleY < 10 && headAngleZ < 10) {
        confidence += 0.3; // Good head position
      } else if (headAngleY < 20 && headAngleZ < 20) {
        confidence += 0.2; // Acceptable head position
      } else {
        confidence += 0.1; // Poor head position
      }

      // Landmark quality factor (max 0.3)
      int detectedLandmarks = face.landmarks.length;
      if (detectedLandmarks >= 8) {
        confidence += 0.3; // All landmarks detected clearly
      } else if (detectedLandmarks >= 6) {
        confidence += 0.2; // Most landmarks detected
      } else {
        confidence += 0.1; // Minimal landmarks detected
      }

      // Face size factor (max 0.3)
      double relativeFaceSize = face.boundingBox.width / faceWidth;
      if (relativeFaceSize > 0.5) {
        confidence += 0.3; // Face fills good portion of frame
      } else if (relativeFaceSize > 0.3) {
        confidence += 0.2; // Medium face size
      } else {
        confidence += 0.1; // Face too small in frame
      }

      // Round to 2 decimal places
      confidence = double.parse(confidence.toStringAsFixed(2));

      return {
        'width': faceWidth,
        'height': faceHeight,
        'confidence': confidence,
        'headAngleY': headAngleY,
        'headAngleZ': headAngleZ,
        'eyeDistance': eyeDistance,
        'noseToMouthDistance': noseToMouthDistance,
        'cheekDistance': cheekDistance,
        'earDistance': earDistance,
        'leftEyeToNose': leftEyeToNose,
        'rightEyeToNose': rightEyeToNose,
        'leftEyeToRightCheek': leftEyeToRightCheek,
        'rightEyeToLeftCheek': rightEyeToLeftCheek,
        // Normalized ratios
        'eyeDistanceRatio': eyeDistance / faceWidth,
        'noseToMouthRatio': noseToMouthDistance / faceHeight,
        'cheekDistanceRatio': cheekDistance / faceWidth,
        'earDistanceRatio': earDistance / faceWidth,
        'eyeToNoseRatio': (leftEyeToNose + rightEyeToNose) / (2 * faceHeight),
        'diagonalRatio':
            (leftEyeToRightCheek + rightEyeToLeftCheek) / (2 * faceWidth),
      };
    } catch (e) {
      print('❌ Error processing face features: $e');
      return null;
    }
  }

  double _calculateDistance(Point<int> p1, Point<int> p2) {
    return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
  }

  bool _compareFaces(Map<String, dynamic> face1, Map<String, dynamic> face2) {
    try {
      print('\n🔍 Comparing faces with strict criteria:');
      print('Face 1: $face1');
      print('Face 2: $face2');

      // Stricter confidence threshold
      const double confidenceThreshold = 0.85;
      if ((face1['confidence'] ?? 0.0) < confidenceThreshold ||
          (face2['confidence'] ?? 0.0) < confidenceThreshold) {
        print('❌ Confidence too low');
        return false;
      }

      // Very strict head angle comparison
      const double angleThreshold = 10.0;
      if ((face1['headAngleY'] - face2['headAngleY']).abs() > angleThreshold ||
          (face1['headAngleZ'] - face2['headAngleZ']).abs() > angleThreshold) {
        print('❌ Head angles too different');
        return false;
      }

      // Strict ratio comparisons
      const double ratioTolerance = 0.1; // 10% tolerance
      final ratiosToCompare = [
        'eyeDistanceRatio',
        'noseToMouthRatio',
        'cheekDistanceRatio',
        'earDistanceRatio',
        'eyeToNoseRatio',
        'diagonalRatio',
      ];

      for (final ratio in ratiosToCompare) {
        final ratio1 = face1[ratio] ?? 0.0;
        final ratio2 = face2[ratio] ?? 0.0;
        if ((ratio1 - ratio2).abs() > ratioTolerance) {
          print(
            '❌ $ratio too different: ${ratio1.toStringAsFixed(3)} vs ${ratio2.toStringAsFixed(3)}',
          );
          return false;
        }
      }

      // Compare overall face proportions
      const double sizeTolerance = 0.15;
      final aspectRatio1 = face1['width'] / face1['height'];
      final aspectRatio2 = face2['width'] / face2['height'];
      if ((aspectRatio1 - aspectRatio2).abs() > sizeTolerance) {
        print('❌ Face proportions too different');
        return false;
      }

      print(
        '✅ Face comparison passed - same person confirmed with high confidence',
      );
      return true;
    } catch (e) {
      print('❌ Error comparing faces: $e');
      return false;
    }
  }

  Future<Face?> _detectFace(String imagePath) async {
    try {
      print('🔍 Attempting to detect face in image: $imagePath');
      final inputImage = InputImage.fromFilePath(imagePath);
      final List<Face> faces = await faceDetector.processImage(inputImage);

      print('📊 Number of faces detected: ${faces.length}');
      if (faces.isEmpty) {
        print('⚠️ No faces detected');
        return null;
      }

      if (faces.length > 1) {
        print('⚠️ Multiple faces detected - using largest face');
      }

      final Face face = faces.reduce(
        (curr, next) =>
            curr.boundingBox.width > next.boundingBox.width ? curr : next,
      );

      // Verify face has required landmarks using correct types
      final hasRequiredLandmarks =
          face.landmarks[FaceLandmarkType.leftEye] != null &&
          face.landmarks[FaceLandmarkType.rightEye] != null &&
          face.landmarks[FaceLandmarkType.noseBase] != null &&
          face.landmarks[FaceLandmarkType.bottomMouth] != null;

      if (!hasRequiredLandmarks) {
        print('⚠️ Face missing required landmarks');
        return null;
      }

      print('✅ Valid face detected with all required landmarks');
      return face;
    } catch (e) {
      print('❌ Error detecting face: $e');
      return null;
    }
  }

  Future<bool> uploadPhoto({
    required ImageSource source,
    required BuildContext context,
  }) async {
    Face? detectedFace;
    try {
      print('\n🚀 Starting photo upload process...');
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 100,
        maxWidth: 2048,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo == null) {
        print('⚠️ No photo selected');
        _showMessage(context, 'No photo selected', true);
        return false;
      }

      _showMessage(context, 'Processing photo...', false);

      // Multiple attempts to detect face
      for (int i = 0; i < 3; i++) {
        print('🔍 Attempt ${i + 1} to detect face...');
        detectedFace = await _detectFace(photo.path);
        if (detectedFace != null) break;
        await Future.delayed(Duration(milliseconds: 500));
      }

      if (detectedFace == null) {
        _showMessage(
          context,
          'Could not detect face clearly. Please ensure:\n'
          '• Good lighting\n'
          '• Face is clearly visible\n'
          '• Looking directly at camera',
          true,
        );
        return false;
      }

      // Process face features
      final currentFace = await _processFace(detectedFace);
      if (currentFace == null) {
        _showMessage(
          context,
          'Could not process facial features clearly',
          true,
        );
        return false;
      }

      // Get and compare with reference face
      final referenceFace = await _getReferenceFace();
      if (referenceFace != null) {
        print('🔍 Comparing with reference face...');
        if (!_compareFaces(referenceFace, currentFace)) {
          _showMessage(
            context,
            'Different person detected. Please use the same person for all photos.',
            true,
          );
          return false;
        }
      }

      // Upload photo
      print('📤 Uploading photo to Cloudinary...');
      final result = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          photo.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // Analyze progress and generate message
      final analysisService = AnalysisService();
      final analysis = await analysisService.analyzeProgress(currentFace);

      // Save to Firestore
      print('💾 Saving to Firestore...');
      await FirebaseFirestore.instance.collection('photos').add({
        'url': result.secureUrl,
        'date': FieldValue.serverTimestamp(),
        'face': currentFace,
        'analysis': analysis,
      });

      // Show analysis message
      _showMessage(context, '✅ Photo uploaded!\n${analysis['message']}', false);

      return true;
    } catch (e) {
      print('❌ Error: $e');
      _showMessage(
        context,
        'Upload failed. Please try again with better lighting and face visibility.',
        true,
      );
      return false;
    } finally {
      await faceDetector.close();
    }
  }
}
*/