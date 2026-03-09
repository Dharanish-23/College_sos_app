import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/web_camera_helper.dart'
    if (dart.library.io) '../services/web_camera_helper_stub.dart';
import 'camera_record_screen.dart';

class RaiseSOSScreen extends StatefulWidget {
  const RaiseSOSScreen({super.key});

  @override
  State<RaiseSOSScreen> createState() => _RaiseSOSScreenState();
}

class _RaiseSOSScreenState extends State<RaiseSOSScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();

  SOSCategory? _selectedCategory;
  bool _isAnonymous = false;
  bool _submitting = false;
  XFile? _selectedVideo;

  @override
  void dispose() {
    _descCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  /// Opens a bottom sheet with 4 evidence options.
  void _showVideoPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Add Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            kIsWeb ? 'Use your camera or choose files' : 'Use your camera or choose from gallery',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _SOSMediaOption(
              icon: Icons.camera_alt,
              label: 'Take Photo',
              color: const Color(0xFF1565C0),
              onTap: () async {
                Navigator.pop(ctx);
                XFile? img;
                if (kIsWeb) {
                  img = await webCapturePhoto();
                } else {
                  img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
                }
                if (img != null && mounted) {
                  setState(() => _selectedVideo = img);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Photo captured!'), backgroundColor: Colors.green),
                  );
                }
              },
            )),
            const SizedBox(width: 10),
            Expanded(child: _SOSMediaOption(
              icon: Icons.photo_library,
              label: kIsWeb ? 'Upload Photo' : 'Choose Photo',
              color: const Color(0xFF2E7D32),
              onTap: () async {
                Navigator.pop(ctx);
                XFile? img;
                if (kIsWeb) {
                  img = await webPickPhoto();
                } else {
                  img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
                }
                if (img != null && mounted) {
                  setState(() => _selectedVideo = img);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Photo selected: ${img.name}'), backgroundColor: Colors.green),
                  );
                }
              },
            )),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _SOSMediaOption(
              icon: Icons.videocam,
              label: 'Record Video',
              color: const Color(0xFFD32F2F),
              onTap: () async {
                Navigator.pop(ctx);
                if (kIsWeb) {
                  final vid = await webCaptureVideo();
                  if (vid != null && mounted) {
                    setState(() => _selectedVideo = vid);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Video recorded!'), backgroundColor: Colors.green),
                    );
                  }
                } else {
                  // Mobile: use live camera screen
                  try {
                    final result = await Navigator.push<XFile?>(
                      context,
                      MaterialPageRoute(builder: (_) => const CameraRecordScreen()),
                    );
                    if (result != null && mounted) {
                      setState(() => _selectedVideo = result);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Video recorded!'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Camera error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            )),
            const SizedBox(width: 10),
            Expanded(child: _SOSMediaOption(
              icon: Icons.video_library,
              label: kIsWeb ? 'Upload Video' : 'Choose Video',
              color: const Color(0xFF6A1B9A),
              onTap: () async {
                Navigator.pop(ctx);
                XFile? vid;
                if (kIsWeb) {
                  vid = await webPickVideo();
                } else {
                  vid = await ImagePicker().pickVideo(source: ImageSource.gallery);
                }
                if (vid != null && mounted) {
                  setState(() => _selectedVideo = vid);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Video selected: ${vid.name}'), backgroundColor: Colors.green),
                  );
                }
              },
            )),
          ]),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  // Keep _pickVideo for legacy — now unused but harmless
  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      XFile? video;
      if (kIsWeb) {
        video = await webPickVideo();
      } else {
        video = await picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 5),
        );
      }
      if (video != null && mounted) {
        setState(() => _selectedVideo = video);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Video selected: ${video.name}'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an emergency category'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber, color: Colors.red),
          SizedBox(width: 8),
          Expanded(child: Text('Confirm SOS Alert', style: TextStyle(fontSize: 16))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${_selectedCategory!.label}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Location: ${_locCtrl.text}'),
            const SizedBox(height: 10),
            const Text('This will immediately alert Campus Security. Only send in a genuine emergency.',
                style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('YES, SEND SOS'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _submitting = true);
    try {
      final categoryStr = _selectedCategory!.name == 'mentalHealth' ? 'mental_health' : _selectedCategory!.name;

      // Step 1: Submit SOS record
      final sosData = await ApiService().submitSOS({
        'category': categoryStr,
        'description': _descCtrl.text.trim(),
        'location': _locCtrl.text.trim(),
        'is_anonymous': _isAnonymous,
        'has_video': _selectedVideo != null,
      });

      // Step 2: Upload video if selected
      if (_selectedVideo != null && mounted) {
        final sosId = sosData['id'] as String;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⬆️ Uploading video evidence...'), duration: Duration(seconds: 120)),
        );
        try {
          await ApiService().uploadSOSVideoWeb(_selectedVideo!, sosId);
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Video uploaded!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
            );
          }
        } catch (uploadErr) {
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('⚠️ SOS sent but video upload failed: $uploadErr'), backgroundColor: Colors.orange, duration: const Duration(seconds: 4)),
            );
          }
        }
      }

      if (!mounted) return;
      setState(() => _submitting = false);
      _showSuccessSheet();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70, height: 70,
              decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Color(0xFFD32F2F), size: 44),
            ),
            const SizedBox(height: 16),
            const Text('SOS Alert Sent!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Campus Security has been notified and is on the way. Stay calm and stay safe.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(child: Text('Track your SOS status in the Status tab.', style: TextStyle(fontSize: 12, color: Colors.grey))),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () { Navigator.pop(ctx); _resetForm(); },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _descCtrl.clear();
    _locCtrl.clear();
    setState(() {
      _selectedCategory = null;
      _isAnonymous = false;
      _selectedVideo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        title: const Text('Raise SOS Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: const Row(children: [
                  Icon(Icons.warning_amber, color: Color(0xFFD32F2F)),
                  SizedBox(width: 10),
                  Expanded(child: Text('Only use SOS for genuine emergencies. Campus security will be alerted immediately.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFB71C1C)))),
                ]),
              ),
              const SizedBox(height: 20),

              // Category
              const Text('Select Emergency Type *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.85),
                itemCount: SOSCategory.values.length,
                itemBuilder: (ctx, i) {
                  final cat = SOSCategory.values[i];
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: selected ? cat.color : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? cat.color : Colors.grey.shade200, width: selected ? 2 : 1),
                        boxShadow: selected ? [BoxShadow(color: cat.color.withOpacity(0.35), blurRadius: 8)] : [],
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(cat.label,
                            textAlign: TextAlign.center, maxLines: 2,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : Colors.black87)),
                      ]),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Location
              const Text('Your Current Location *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locCtrl,
                decoration: _dec(hint: 'e.g. CS Lab 3, Block D', icon: Icons.location_on),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your location' : null,
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Brief Description *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: _dec(hint: 'Describe what is happening...', icon: Icons.description),
                validator: (v) => (v == null || v.trim().length < 10) ? 'Please describe the emergency (min 10 chars)' : null,
              ),
              const SizedBox(height: 20),

              // Evidence Video — works on both web and mobile
              const Text('Evidence Video (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                kIsWeb
                    ? 'Upload a video file as evidence.'
                    : 'Record or upload a video as evidence. Max 5 minutes.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _selectedVideo != null ? Colors.green.shade300 : Colors.grey.shade200),
                ),
                child: Column(children: [
                  if (_selectedVideo != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          const Icon(Icons.videocam, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_selectedVideo!.name,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _selectedVideo = null),
                          ),
                        ]),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                        side: const BorderSide(color: Color(0xFFD32F2F)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      icon: const Icon(Icons.add_photo_alternate, size: 20),
                      label: Text(_selectedVideo == null ? 'Add Evidence' : 'Change Evidence'),
                      onPressed: _showVideoPicker,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // Anonymous toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200)),
                child: Row(children: [
                  const Icon(Icons.person_off_outlined, color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Submit Anonymously', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('Your name will be hidden from the report', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ])),
                  Switch(
                    value: _isAnonymous,
                    onChanged: (v) => setState(() => _isAnonymous = v),
                    activeColor: const Color(0xFFD32F2F),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  icon: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Icon(Icons.sos, size: 24),
                  label: Text(_submitting ? 'Sending Alert...' : 'SEND SOS ALERT',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  onPressed: _submitting ? null : _submit,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec({required String hint, required IconData icon}) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
    prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
  );
}

class _SOSMediaOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SOSMediaOption({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Column(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
