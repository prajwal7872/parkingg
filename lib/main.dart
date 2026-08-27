import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:parking/auth/api_endpoints.dart';
import 'package:parking/auth/auth_service.dart';
import 'package:parking/auth/loginpage.dart';
import 'package:parking/database/background_sync.dart';
import 'package:parking/home/screens/root_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();

  final savedBaseUrl = await SecureStorage.getBaseUrl();
  if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
    ApiEndpoints.baseUrl = savedBaseUrl;
  }
  String? token = await storage.read(key: "access_token");
  SyncService().startAutoSync();
  await CameraManager().initialize();
  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const AppShell() : const LoginScreen(),
    );
  }
}

class CameraManager {
  static final CameraManager _instance = CameraManager._internal();
  factory CameraManager() => _instance;
  CameraManager._internal();
  List<CameraDescription>? _cameras;
  CameraController? _controller;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(_cameras![0], ResolutionPreset.medium);
        await _controller!.initialize();
        _isInitialized = true;
      }
    } catch (_) {}
  }

  CameraController? get controller => _controller;
  List<CameraDescription>? get cameras => _cameras;
  bool get isInitialized => _isInitialized;

  void dispose() {
    _controller?.dispose();
    _controller = null;
    _cameras = null;
    _isInitialized = false;
  }
}
