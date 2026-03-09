import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/cctv_alert.dart';
import 'package:image_picker/image_picker.dart';
import 'cctv_video_analyzer_screen.dart';

class AdminCCTVScreen extends StatefulWidget {
  const AdminCCTVScreen({super.key});

  @override
  State<AdminCCTVScreen> createState() => _AdminCCTVScreenState();
}

class _AdminCCTVScreenState extends State<AdminCCTVScreen> {
  List<CCTVAlert> _alerts = [];
  bool _loading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getCCTVAlerts(
        status: _filterStatus == 'all' ? null : _filterStatus,
      );
      setState(() {
        _alerts = (data as List).map((e) => CCTVAlert.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading alerts: $e')),
        );
      }
    }
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    try {
      await ApiService().acknowledgeCCTVAlert(alertId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert acknowledged')),
      );
      _loadAlerts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _updateStatus(String alertId) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _StatusUpdateDialog(),
    );

    if (result != null) {
      try {
        await ApiService().updateCCTVAlertStatus(
          alertId,
          result['status']!,
          result['message']!,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated')),
        );
        _loadAlerts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _uploadVideo(String alertId) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading video...')),
        );
        await ApiService().uploadCCTVVideo(alertId, video.path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully')),
        );
        _loadAlerts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _simulateAlert() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _SimulateAlertDialog(),
    );

    if (result != null) {
      try {
        await ApiService().simulateCCTVAlert(result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert simulated successfully')),
        );
        _loadAlerts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CCTV Monitoring'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.video_library),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const CCTVVideoAnalyzerScreen()),
              );
            },
            tooltip: 'Analyze Video',
          ),
          IconButton(
            icon: const Icon(Icons.add_alert),
            onPressed: _simulateAlert,
            tooltip: 'Simulate Alert',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _alerts.isEmpty
                    ? const Center(child: Text('No CCTV alerts'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _alerts.length,
                        itemBuilder: (ctx, i) => _buildAlertCard(_alerts[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('All', 'all'),
            _filterChip('New', 'submitted'),
            _filterChip('Under Review', 'under_review'),
            _filterChip('In Progress', 'in_progress'),
            _filterChip('Resolved', 'resolved'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _filterStatus = value);
          _loadAlerts();
        },
        selectedColor: Colors.red[100],
      ),
    );
  }

  Widget _buildAlertCard(CCTVAlert alert) {
    final color = _getStatusColor(alert.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border(left: BorderSide(color: color, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getIncidentIcon(alert.incidentType),
                        color: color, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.incidentTypeDisplay,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        alert.statusDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.videocam, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      alert.cameraId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        alert.cameraLocation,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  alert.description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(alert.detectedAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text(
                        'Confidence: ${(alert.confidenceScore * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (alert.videoUrl != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () => _launchVideo(alert.videoUrl!),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    image: alert.videoThumbnailUrl != null
                        ? DecorationImage(
                            image: NetworkImage(alert.videoThumbnailUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: const Center(
                    child: Icon(Icons.play_circle_outline,
                        size: 48, color: Colors.white),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (alert.status == 'submitted')
                  ElevatedButton.icon(
                    onPressed: () => _acknowledgeAlert(alert.id),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Acknowledge'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () => _updateStatus(alert.id),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Update Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (alert.videoUrl == null)
                  ElevatedButton.icon(
                    onPressed: () => _uploadVideo(alert.id),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Upload Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _showTimeline(alert),
                  icon: const Icon(Icons.timeline, size: 18),
                  label: const Text('Timeline'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.red;
      case 'under_review':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getIncidentIcon(String type) {
    switch (type) {
      case 'fighting':
        return Icons.warning;
      case 'large_crowd':
        return Icons.groups;
      case 'suspicious_activity':
        return Icons.visibility;
      case 'vandalism':
        return Icons.broken_image;
      case 'unauthorized_entry':
        return Icons.no_encryption;
      default:
        return Icons.info;
    }
  }

  void _launchVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showTimeline(CCTVAlert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alert Timeline',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: alert.timeline.length,
                  itemBuilder: (ctx, i) {
                    final update = alert.timeline[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(update.status),
                        child: const Icon(Icons.check, color: Colors.white),
                      ),
                      title: Text(update.message),
                      subtitle: Text(
                        '${DateFormat('MMM dd, HH:mm').format(update.updatedAt)}\nBy: ${update.updatedBy ?? "System"}',
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusUpdateDialog extends StatefulWidget {
  @override
  State<_StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<_StatusUpdateDialog> {
  String _status = 'in_progress';
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'under_review', child: Text('Under Review')),
              DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
              DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
              DropdownMenuItem(value: 'closed', child: Text('Closed')),
            ],
            onChanged: (v) => setState(() => _status = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_messageController.text.isNotEmpty) {
              Navigator.pop(context, {
                'status': _status,
                'message': _messageController.text,
              });
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class _SimulateAlertDialog extends StatefulWidget {
  @override
  State<_SimulateAlertDialog> createState() => _SimulateAlertDialogState();
}

class _SimulateAlertDialogState extends State<_SimulateAlertDialog> {
  String _cameraId = 'CAM-010';
  String _location = 'Academic Block 2';
  String _incidentType = 'fighting';
  final _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Simulate CCTV Alert'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _cameraId,
              decoration: const InputDecoration(labelText: 'Camera ID'),
              items: List.generate(
                10,
                (i) => DropdownMenuItem(
                  value: 'CAM-${(i + 1).toString().padLeft(3, '0')}',
                  child: Text('CAM-${(i + 1).toString().padLeft(3, '0')}'),
                ),
              ),
              onChanged: (v) => setState(() => _cameraId = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: _location),
              decoration: const InputDecoration(labelText: 'Location'),
              onChanged: (v) => _location = v,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _incidentType,
              decoration: const InputDecoration(labelText: 'Incident Type'),
              items: const [
                DropdownMenuItem(value: 'fighting', child: Text('Fighting')),
                DropdownMenuItem(value: 'large_crowd', child: Text('Large Crowd')),
                DropdownMenuItem(value: 'suspicious_activity', child: Text('Suspicious Activity')),
                DropdownMenuItem(value: 'vandalism', child: Text('Vandalism')),
                DropdownMenuItem(value: 'unauthorized_entry', child: Text('Unauthorized Entry')),
              ],
              onChanged: (v) => setState(() => _incidentType = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_descController.text.isNotEmpty) {
              Navigator.pop(context, {
                'camera_id': _cameraId,
                'camera_location': _location,
                'incident_type': _incidentType,
                'description': _descController.text,
                'confidence_score': 0.85,
              });
            }
          },
          child: const Text('Simulate'),
        ),
      ],
    );
  }
}
