import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/web_camera_helper.dart'
    if (dart.library.io) '../services/web_camera_helper_stub.dart';
import 'camera_record_screen.dart';

class RaiseComplaintScreen extends StatefulWidget {
  const RaiseComplaintScreen({super.key});

  @override
  State<RaiseComplaintScreen> createState() => _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends State<RaiseComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _againstCtrl = TextEditingController();

  ComplaintCategory? _selectedCategory;
  bool _isAnonymous = false;
  bool _submitting = false;

  final List<XFile> _attachments = [];
  final List<String> _attachmentTypes = [];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    _againstCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    try {
      XFile? img;
      if (kIsWeb) {
        img = fromCamera ? await webCapturePhoto() : await webPickPhoto();
      } else {
        final picker = ImagePicker();
        img = await picker.pickImage(
          source: fromCamera ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 80,
        );
      }
      if (img != null && mounted) {
        setState(() { _attachments.add(img!); _attachmentTypes.add('photo'); });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _pickVideo({bool fromCamera = false}) async {
    try {
      XFile? vid;
      if (kIsWeb) {
        vid = fromCamera ? await webCaptureVideo() : await webPickVideo();
      } else {
        final picker = ImagePicker();
        vid = await picker.pickVideo(
          source: fromCamera ? ImageSource.camera : ImageSource.gallery,
          maxDuration: const Duration(minutes: 10),
        );
      }
      if (vid != null && mounted) {
        setState(() { _attachments.add(vid!); _attachmentTypes.add('video'); });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _recordVideoWithCamera() async {
    try {
      final result = await Navigator.push<XFile?>(
        context,
        MaterialPageRoute(builder: (_) => const CameraRecordScreen()),
      );
      if (result != null && mounted) {
        setState(() {
          _attachments.add(result);
          _attachmentTypes.add('video');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Video recorded!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showMediaPicker() {
    // Same 4-option sheet for both web and mobile
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
            Expanded(child: _MediaOption(
              icon: Icons.camera_alt,
              label: 'Take Photo',
              color: const Color(0xFF1565C0),
              onTap: () { Navigator.pop(ctx); _pickImage(fromCamera: true); },
            )),
            const SizedBox(width: 10),
            Expanded(child: _MediaOption(
              icon: Icons.photo_library,
              label: kIsWeb ? 'Upload Photo' : 'Choose Photo',
              color: const Color(0xFF2E7D32),
              onTap: () { Navigator.pop(ctx); _pickImage(fromCamera: false); },
            )),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _MediaOption(
              icon: Icons.videocam,
              label: 'Record Video',
              color: const Color(0xFFD32F2F),
              onTap: () {
                Navigator.pop(ctx);
                if (kIsWeb) {
                  _pickVideo(fromCamera: true);
                } else {
                  _recordVideoWithCamera();
                }
              },
            )),
            const SizedBox(width: 10),
            Expanded(child: _MediaOption(
              icon: Icons.video_library,
              label: kIsWeb ? 'Upload Video' : 'Choose Video',
              color: const Color(0xFF6A1B9A),
              onTap: () { Navigator.pop(ctx); _pickVideo(fromCamera: false); },
            )),
          ]),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a complaint category'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      String categoryStr = _selectedCategory!.name;
      if (categoryStr == 'academicMisconduct') categoryStr = 'academic_misconduct';
      if (categoryStr == 'facilityIssue') categoryStr = 'facility_issue';
      if (categoryStr == 'staffConduct') categoryStr = 'staff_conduct';
      if (categoryStr == 'financialIssue') categoryStr = 'financial_issue';

      // Step 1: Submit complaint record
      final complaintData = await ApiService().submitComplaint({
        'category': categoryStr,
        'subject': _subjectCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locCtrl.text.trim(),
        'is_anonymous': _isAnonymous,
        'against_person': _againstCtrl.text.trim().isEmpty ? null : _againstCtrl.text.trim(),
        'media_count': _attachments.length,
        'media_types': List<String>.from(_attachmentTypes),
      });

      // Step 2: Upload attachments
      if (_attachments.isNotEmpty && mounted) {
        final complaintId = complaintData['id'] as String;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⬆️ Uploading ${_attachments.length} file(s)...'), duration: const Duration(seconds: 120)),
        );
        int uploaded = 0;
        for (int i = 0; i < _attachments.length; i++) {
          try {
            await ApiService().uploadComplaintMediaWeb(_attachments[i], complaintId, _attachmentTypes[i]);
            uploaded++;
          } catch (_) {}
        }
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          if (uploaded == _attachments.length) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✅ $uploaded file(s) uploaded'), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('⚠️ $uploaded/${_attachments.length} uploaded. Some failed.'), backgroundColor: Colors.orange, duration: const Duration(seconds: 3)),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 70, height: 70,
            decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: Color(0xFF1565C0), size: 44),
          ),
          const SizedBox(height: 16),
          const Text('Complaint Filed!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Your complaint has been submitted. The relevant committee will review it.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Expanded(child: Text('Track your complaint status in the Status tab.', style: TextStyle(fontSize: 12, color: Colors.grey))),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () { Navigator.pop(ctx); _resetForm(); },
              child: const Text('Done'),
            ),
          ),
        ]),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _subjectCtrl.clear();
    _descCtrl.clear();
    _locCtrl.clear();
    _againstCtrl.clear();
    setState(() {
      _selectedCategory = null;
      _isAnonymous = false;
      _attachments.clear();
      _attachmentTypes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('File a Complaint', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category
              const Text('Complaint Category *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: ComplaintCategory.values.map((cat) {
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF1565C0) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? const Color(0xFF1565C0) : Colors.grey.shade300),
                        boxShadow: selected ? [const BoxShadow(color: Color(0x331565C0), blurRadius: 6)] : [],
                      ),
                      child: Text(cat.label,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : Colors.black87)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Subject
              const Text('Subject *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectCtrl,
                decoration: _dec(hint: 'Brief title of your complaint', icon: Icons.title),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a subject' : null,
              ),
              const SizedBox(height: 16),

              // Against
              const Text('Complaint Against (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _againstCtrl,
                decoration: _dec(hint: 'Name / roll no. of person(s) involved', icon: Icons.person_search),
              ),
              const SizedBox(height: 16),

              // Location
              const Text('Location / Department *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locCtrl,
                decoration: _dec(hint: 'Where did this happen?', icon: Icons.location_on),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter location' : null,
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Full Description *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                decoration: _dec(hint: 'Describe the incident in detail...', icon: Icons.description),
                validator: (v) => (v == null || v.trim().length < 20) ? 'Please provide a detailed description (min 20 chars)' : null,
              ),
              const SizedBox(height: 20),

              // Evidence Attachments — works on web AND mobile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Evidence / Attachments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('${_attachments.length} attached', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                kIsWeb
                    ? 'Upload photos or videos from your computer as evidence (optional)'
                    : 'Attach photos or videos as evidence (optional)',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),

              if (_attachments.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachments.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == _attachments.length) return _AddAttachmentButton(onTap: _showMediaPicker);
                      final type = _attachmentTypes[i];
                      return _AttachmentThumbnail(
                        file: _attachments[i],
                        type: type,
                        onRemove: () => setState(() {
                          _attachments.removeAt(i);
                          _attachmentTypes.removeAt(i);
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ] else ...[
                GestureDetector(
                  onTap: _showMediaPicker,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey.shade500),
                      const SizedBox(height: 8),
                      Text(
                        kIsWeb ? 'Tap to upload photos or videos' : 'Tap to add photos or videos',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text('Supports: JPG, PNG, MP4', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
              ],

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
                    Text('Your identity will be protected', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ])),
                  Switch(
                    value: _isAnonymous,
                    onChanged: (v) => setState(() => _isAnonymous = v),
                    activeColor: const Color(0xFF1565C0),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  icon: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Icon(Icons.send, size: 22),
                  label: Text(_submitting ? 'Submitting...' : 'SUBMIT COMPLAINT',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    prefixIcon: Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 20, color: Colors.grey.shade600)),
    filled: true, fillColor: Colors.white,
    alignLabelWithHint: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
  );
}

class _MediaOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MediaOption({required this.icon, required this.label, required this.color, required this.onTap});

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
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _AddAttachmentButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddAttachmentButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90, height: 90,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add, size: 28, color: Colors.grey),
          SizedBox(height: 4),
          Text('Add more', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ),
    );
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  final XFile file;
  final String type;
  final VoidCallback onRemove;
  const _AttachmentThumbnail({required this.file, required this.type, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90, height: 90,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: type == 'photo'
              ? Container(
                  width: 90, height: 90,
                  color: Colors.blue.shade50,
                  child: const Icon(Icons.image, color: Colors.blue, size: 40))
              : Container(
                  width: 90, height: 90,
                  color: Colors.purple.shade50,
                  child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.videocam, color: Colors.purple, size: 30),
                    SizedBox(height: 4),
                    Text('Video', style: TextStyle(fontSize: 10, color: Colors.purple)),
                  ])),
        ),
        // File name label
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
            ),
            child: Text(
              file.name,
              style: const TextStyle(fontSize: 8, color: Colors.white),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
        if (type == 'video')
          const Positioned(bottom: 20, left: 0, right: 0,
              child: Icon(Icons.play_circle_filled, color: Colors.white, size: 24)),
      ]),
    );
  }
}
