
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:path/path.dart' as path;

class CameraScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  // String latitude;
  // String longitude;
  // final VoidCallback onAttendanceMarked;
  const CameraScreen({super.key, 
    required this.employeeId,
    required this.employeeName, required String userName,
    // required this.latitude,
    // required this.longitude,
    // required this.onAttendanceMarked,
  });

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  XFile? _image;
  bool _isLoading = false;
  bool _isCaptured = false;
  bool _isRecognized = false;
  bool _recognitionFinished = false;
  final FlutterTts _flutterTts = FlutterTts();
   late String latitude;
  late String longitude;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    latitude = "0.0";
    longitude = "0.0";
    _checkGpsAndInitialize();
    _initializeTts();
    WakelockPlus.enable();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  /// **Check if GPS is Enabled and Get Location**
  /// **Check if GPS is Enabled and Get Location**
  Future<void> _checkGpsAndInitialize() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("⚠️ Location permission denied");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please allow location access in settings!'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("🚨 Location permission permanently denied");
      return;
    }

    bool isGpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      _showEnableGpsPopup();
      return;
    }

    // 🌟 Fetch location multiple times to ensure accuracy
    Position? position;
    for (int i = 0; i < 3; i++) {
      position = await _getCurrentLocation();
      if (position != null) break;
      await Future.delayed(Duration(seconds: 2)); // Small delay for retries
    }

    if (position != null) {
      setState(() {
        latitude = position!.latitude.toString();
        longitude = position.longitude.toString();
      });
    } else {
      print("❌ Failed to fetch location");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS not detected. Move outside for better signal.'), backgroundColor: Colors.orange),
      );
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // Use high accuracy
        timeLimit: Duration(seconds: 7), // Increase timeout
      );
    } catch (e) {
      print("❌ Error getting location: $e");
      return null;
    }
  }


  /// **Show Popup to Enable GPS**
  void _showEnableGpsPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.red),
            SizedBox(width: 10),
            Text("Enable GPS"),
          ],
        ),
        content: Text(
          "Your GPS is turned off. This app requires location access to function properly. Please turn it on.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Geolocator.openLocationSettings();
              Navigator.of(context).pop();
            },
            child: Text("Turn On GPS"),
          ),
          TextButton(
            onPressed: () {
              _exitApp();
            },
            child: Text("Exit App", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// **Exit App If Location Not Found**
  void _exitApp() {
    Navigator.pop(context);
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  /// **Initialize Camera**
  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      try {
        final cameras = await availableCameras();
        final frontCamera = cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _cameraController!.setFocusMode(FocusMode.auto);
          });
        }

        _takePicture();
      } catch (e) {
        print('Error initializing camera: $e');
      }
    } else {
      print('Camera permission denied');
    }
  }

  Future<void> _takePicture() async {
    if (_isCaptured) return;

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print('Camera is not initialized');
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      final compressedImage = await _compressImage(image);

      setState(() {
        _image = compressedImage;
        _isCaptured = true;
      });

      await _sendDataToBackend();
        } catch (e) {
      print('Error capturing image: $e');
    }
  }

  Future<void> _speak(String message) async {
    await _flutterTts.speak(message);
  }

  Future<void> _sendDataToBackend() async {
    setState(() {
      _isLoading = true;
    });

    // ⏳ Ensure valid location before sending data
    if (latitude == "0.0" || longitude == "0.0") {
      print("⚠️ Invalid coordinates: $latitude, $longitude. Retrying location fetch...");
      Position? position = await _getCurrentLocation();
      if (position != null) {
        latitude = position.latitude.toString();
        longitude = position.longitude.toString();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS error! Move outside and retry.'), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.64.151.226:8000/api/mobile/recognize/'),
      );
      request.fields['emp_id'] = widget.employeeId;
      request.fields['name'] = widget.employeeName;
      request.fields['latitude'] = latitude;
      request.fields['longitude'] = longitude;

      var multipartFile = http.MultipartFile(
        'captured_image',
        http.ByteStream.fromBytes(await _image!.readAsBytes()),
        await _image!.length(),
        filename: path.basename(_image!.path),
      );
      request.files.add(multipartFile);

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        setState(() {
          _isRecognized = true;
          _recognitionFinished = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Attendance marked successfully'), backgroundColor: Colors.green),
        );

        await _speak('Attendance marked successfully');
        // widget.onAttendanceMarked();
        Navigator.of(context).pop(true);
      } else {
        var data = json.decode(responseBody);
        setState(() {
          _isRecognized = false;
          _recognitionFinished = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to send data'), backgroundColor: Colors.red),
        );

        await _speak('Failed to send data');
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      setState(() {
        _isRecognized = false;
        _recognitionFinished = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🚨 Network error: $e'), backgroundColor: Colors.red),
      );

      await _speak('Face Not Matched');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Future<void> _sendDataToBackend() async {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   try {
  //     var request = http.MultipartRequest(
  //       'POST',
  //       Uri.parse('http://125.17.238.158:5000/recognize'),
  //     );
  //     request.fields['emp_id'] = widget.employeeId;
  //     request.fields['name'] = widget.employeeName;
  //     request.fields['latitude'] = widget.latitude;
  //     request.fields['longitude'] = widget.longitude;
  //
  //     var multipartFile = http.MultipartFile(
  //       'captured_image',
  //       http.ByteStream.fromBytes(await _image!.readAsBytes()),
  //       await _image!.length(),
  //       filename: path.basename(_image!.path),
  //     );
  //     request.files.add(multipartFile);
  //
  //     var response = await request.send();
  //     var responseBody = await response.stream.bytesToString();
  //
  //     if (response.statusCode == 200) {
  //       setState(() {
  //         _isRecognized = true;
  //         _recognitionFinished = true;
  //       });
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Attendance marked successfully'), backgroundColor: Colors.green),
  //       );
  //
  //       await _speak('Attendance marked successfully');
  //       Navigator.of(context).pop();
  //     } else {
  //       var data = json.decode(responseBody);
  //       setState(() {
  //         _isRecognized = false;
  //         _recognitionFinished = true;
  //       });
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(  content: Text(data['error'] ?? 'Failed to send data'), backgroundColor: Colors.red),
  //       );
  //
  //       await _speak('Failed to send data');
  //       Navigator.of(context).pop();
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _isRecognized = false;
  //       _recognitionFinished = true;
  //     });
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red),
  //     );
  //
  //     await _speak('Face Not Matched');
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  Future<XFile> _compressImage(XFile image) async {
    final imageBytes = await image.readAsBytes();
    final compressedBytes = await FlutterImageCompress.compressWithList(imageBytes, minWidth: 640, minHeight: 480, quality: 50);
    return XFile.fromData(Uint8List.fromList(compressedBytes), path: image.path);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _cameraController == null || !_cameraController!.value.isInitialized
            ? Center(child: CircularProgressIndicator())
            : Stack(
          fit: StackFit.expand, // Expands preview to full screen
          children: [
            RotatedBox(
              quarterTurns: 0, // Adjust rotation if needed
              child: CameraPreview(_cameraController!),
            ),
      
      
          ],
        ),
      ),
    );
  }
}
