import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import '../services/api_service.dart';

class CCTVVideoAnalyzerScreen extends StatefulWidget {
  const CCTVVideoAnalyzerScreen({super.key});

  @override
  State<CCTVVideoAnalyzerScreen> createState() =>
      _CCTVVideoAnalyzerScreenState();
}

class _CCTVVideoAnalyzerScreenState extends State<CCTVVideoAnalyzerScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  bool _showResults = false;
  XFile? _selectedVideo;
  Map<String, dynamic>? _detectionResults;
  late AnimationController _animationController;

  final List<String> _processingSteps = [
    'Uploading video...',
    'Extracting frames...',
    'Running YOLO detection...',
    'Analyzing persons...',
    'Generating report...',
  ];
  int _processingStep = 0;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = video;
        _showResults = false;
        _detectionResults = null;
      });
    }
  }

  Future<void> _analyzeVideo() async {
    if (_selectedVideo == null) return;

    setState(() {
      _isProcessing = true;
      _showResults = false;
      _detectionResults = null;
      _processingStep = 0;
    });

    // Animate processing steps while API call runs
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1800), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_processingStep < _processingSteps.length - 1) {
          _processingStep++;
        }
      });
    });

    try {
      // Real YOLO analysis via backend
      final result = await ApiService().analyzeCCTVVideo(_selectedVideo!);
      _stepTimer?.cancel();

      if (mounted) {
        setState(() {
          _detectionResults = result;
          _isProcessing = false;
          _showResults = true;
        });
      }
    } catch (e) {
      _stepTimer?.cancel();
      if (mounted) {
        setState(() => _isProcessing = false);

        // Show a helpful message if it's a codec/format issue
        final msg = e.toString();
        final isCodecError = msg.contains('could not be analyzed') ||
            msg.contains('Could not open') ||
            msg.contains('codec') ||
            msg.contains('H.265') ||
            msg.contains('HEVC');

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 8),
                const Text('Analysis Failed'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isCodecError
                    ? 'This video format could not be read by the analyzer.'
                    : 'The analysis request failed.'),
                if (isCodecError) ...[  
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text(
                      '💡 Tip: Drone videos are often H.265/HEVC. '
                      'Please re-encode to H.264 MP4 using a tool like '
                      'HandBrake or FFmpeg, then try again.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(msg, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _createAlert() async {
    if (_detectionResults == null || _detectionResults!['incident_detected'] != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await ApiService().simulateCCTVAlert({
        'camera_id': 'CAM-010',
        'camera_location': 'Analyzed Footage',
        'incident_type': 'fighting',
        'description':
            'YOLO Detection: Physical altercation detected. '
            '${_detectionResults!['persons_detected']} person(s) detected '
            'with ${((_detectionResults!['confidence'] as num) * 100).toStringAsFixed(0)}% confidence '
            'across ${_detectionResults!['frames_analyzed']} frames.',
        'confidence_score': _detectionResults!['confidence'],
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ CCTV Alert created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedVideo = null;
          _showResults = false;
          _detectionResults = null;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating alert: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CCTV Video Analyzer'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 20),
            _buildUploadSection(),
            if (_isProcessing) ...[
              const SizedBox(height: 30),
              _buildProcessingAnimation(),
            ],
            if (_showResults && _detectionResults != null) ...[
              const SizedBox(height: 30),
              _buildResultsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[700], size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOLOv8 Person Detection',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Analyzes CCTV footage using AI — detects persons to identify physical altercations',
                    style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              _selectedVideo == null ? Icons.video_library : Icons.check_circle,
              size: 64,
              color: _selectedVideo == null ? Colors.grey : Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedVideo == null ? 'No video selected' : 'Video ready for analysis',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            if (_selectedVideo != null) ...[
              const SizedBox(height: 6),
              Text(
                _selectedVideo!.name,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _pickVideo,
                  icon: const Icon(Icons.upload_file),
                  label: Text(_selectedVideo == null ? 'Select Video' : 'Change Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                if (_selectedVideo != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _analyzeVideo,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Analyze'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingAnimation() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            RotationTransition(
              turns: _animationController,
              child: Icon(Icons.settings, size: 64, color: Colors.red[700]),
            ),
            const SizedBox(height: 20),
            const Text(
              'Analyzing Video...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'YOLOv8 is scanning frames for persons',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: (_processingStep + 1) / _processingSteps.length,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red[700]!),
            ),
            const SizedBox(height: 12),
            Text(
              _processingSteps[_processingStep],
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              'Step ${_processingStep + 1} of ${_processingSteps.length}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    final result = _detectionResults!;
    final incidentDetected = result['incident_detected'] == true;
    final verdict = result['verdict'] as String? ?? (incidentDetected ? 'Physical Altercation Detected' : 'No Physical Altercation Detected');
    final confidence = ((result['confidence'] as num?) ?? 0.0).toDouble();
    final persons = (result['persons_detected'] as num?)?.toInt() ?? 0;
    final frames = (result['frames_analyzed'] as num?)?.toInt() ?? 0;
    final personFrames = (result['person_frames'] as num?)?.toInt() ?? 0;
    final duration = ((result['duration_seconds'] as num?) ?? 0.0).toDouble();
    final severity = result['severity'] as String? ?? 'none';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main verdict card
        Card(
          color: incidentDetected ? Colors.red[50] : Colors.green[50],
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  incidentDetected ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                  size: 72,
                  color: incidentDetected ? Colors.red[700] : Colors.green[700],
                ),
                const SizedBox(height: 12),
                Text(
                  verdict,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: incidentDetected ? Colors.red[900] : Colors.green[900],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: incidentDetected ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    incidentDetected
                        ? '⚠️  Immediate action recommended'
                        : '✅  No persons of concern detected',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: incidentDetected ? Colors.red[800] : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Detection stats
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Detection Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _statRow('Persons Detected', '$persons', Icons.person, Colors.deepOrange),
                _statRow('Frames with Persons', '$personFrames / $frames', Icons.video_library, Colors.purple),
                _statRow('Confidence Score', '${(confidence * 100).toStringAsFixed(0)}%', Icons.percent, Colors.blue),
                _statRow('Video Duration', '${duration.toStringAsFixed(1)}s', Icons.timer, Colors.teal),
                _statRow(
                  'Severity',
                  severity.toUpperCase(),
                  Icons.priority_high,
                  _severityColor(severity),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // How it works note
        Card(
          color: Colors.grey[50],
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.smart_toy_outlined, color: Colors.grey[600], size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'YOLOv8 nano model scanned $frames sampled frames (1 fps). '
                    'Person detections with ≥40% confidence were counted.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        if (incidentDetected)
          ElevatedButton.icon(
            onPressed: _createAlert,
            icon: const Icon(Icons.add_alert),
            label: const Text('Create CCTV Alert from This'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.replay),
            label: const Text('Analyze Another Video'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
      ],
    );
  }

  Widget _statRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey))),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.amber;
      default: return Colors.green;
    }
  }
}
