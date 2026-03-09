import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CameraRecordScreen extends StatefulWidget {
  const CameraRecordScreen({super.key});

  @override
  State<CameraRecordScreen> createState() => _CameraRecordScreenState();
}

class _CameraRecordScreenState extends State<CameraRecordScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;

  bool _isInitializing = true;
  bool _isRecording = false;
  bool _isSwitching = false;
  String? _errorMsg;

  // Timer
  int _elapsedSeconds = 0;
  Timer? _timer;
  static const int _maxSeconds = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initController(_cameras[_cameraIndex]);
    }
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMsg = 'No cameras found on this device.';
          _isInitializing = false;
        });
        return;
      }
      // Prefer back camera first
      final backIdx = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back);
      _cameraIndex = backIdx >= 0 ? backIdx : 0;
      await _initController(_cameras[_cameraIndex]);
    } catch (e) {
      setState(() {
        _errorMsg = 'Camera error: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _initController(CameraDescription camera) async {
    setState(() => _isInitializing = true);
    final ctrl = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = ctrl;
    try {
      await ctrl.initialize();
      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Failed to initialize camera: $e';
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isSwitching || _isRecording) return;
    setState(() => _isSwitching = true);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    await _initController(_cameras[_cameraIndex]);
    setState(() => _isSwitching = false);
  }

  Future<void> _startRecording() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _isRecording) return;
    try {
      await ctrl.startVideoRecording();
      _elapsedSeconds = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() => _elapsedSeconds++);
        if (_elapsedSeconds >= _maxSeconds) _stopRecording();
      });
      setState(() => _isRecording = true);
    } catch (e) {
      _showError('Could not start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    final ctrl = _controller;
    if (ctrl == null || !_isRecording) return;
    _timer?.cancel();
    try {
      final xfile = await ctrl.stopVideoRecording();
      setState(() => _isRecording = false);
      if (mounted) Navigator.pop(context, xfile);
    } catch (e) {
      setState(() => _isRecording = false);
      _showError('Could not save video: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  String get _timerLabel {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _remainingLabel {
    final rem = _maxSeconds - _elapsedSeconds;
    final m = rem ~/ 60;
    final s = rem % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            Text(_errorMsg!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back', style: TextStyle(color: Colors.redAccent)),
            ),
          ]),
        ),
      );
    }

    if (_isInitializing || _controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Initializing camera...', style: TextStyle(color: Colors.white70)),
        ]),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        CameraPreview(_controller!),

        // Top bar
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                // Close
                IconButton(
                  onPressed: _isRecording ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
                const Spacer(),
                // Timer
                if (_isRecording)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(_timerLabel,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ]),
                  ),
                const Spacer(),
                // Switch camera
                IconButton(
                  onPressed: (_cameras.length < 2 || _isRecording || _isSwitching) ? null : _switchCamera,
                  icon: Icon(Icons.flip_camera_android,
                      color: (_isRecording || _cameras.length < 2) ? Colors.white38 : Colors.white, size: 28),
                ),
              ],
            ),
          ),
        ),

        // Bottom bar
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Max duration hint
              if (_isRecording)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Remaining: $_remainingLabel',
                      style: const TextStyle(color: Colors.white60, fontSize: 13)),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Max recording time: 5 minutes',
                      style: TextStyle(color: Colors.white60, fontSize: 13)),
                ),

              // Record button
              GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: _isRecording ? Colors.red : Colors.white.withOpacity(0.15),
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: _isRecording ? 28 : 54,
                      height: _isRecording ? 28 : 54,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(_isRecording ? 6 : 100),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Text(
                _isRecording ? 'Tap to stop' : 'Tap to record',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
