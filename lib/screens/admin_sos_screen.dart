import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class AdminSOSScreen extends StatefulWidget {
  const AdminSOSScreen({super.key});
  @override
  State<AdminSOSScreen> createState() => _AdminSOSScreenState();
}

class _AdminSOSScreenState extends State<AdminSOSScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _filterStatus;
  String? _error;

  final _statuses = [
    'All', 'submitted', 'under_review', 'in_progress', 'resolved', 'rejected'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService().adminGetAllSOS(
        status: (_filterStatus != null && _filterStatus != 'All') ? _filterStatus : null,
      );
      setState(() { _items = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        automaticallyImplyLeading: false,
        title: Text(
          'SOS Alerts (${_items.length})',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _statuses.length,
              itemBuilder: (ctx, i) {
                final s = _statuses[i];
                final sel = (_filterStatus == null && s == 'All') ||
                    _filterStatus == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_fmtStatus(s)),
                    selected: sel,
                    onSelected: (_) {
                      setState(() => _filterStatus = s == 'All' ? null : s);
                      _load();
                    },
                    selectedColor: Colors.white,
                    labelStyle: TextStyle(
                      color: sel ? const Color(0xFFD32F2F) : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.white24,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : _items.isEmpty
                  ? const _EmptyView(
                      icon: Icons.sos,
                      message: 'No SOS alerts found',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFFD32F2F),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) =>
                            _SOSAdminCard(item: _items[i], onUpdated: _load),
                      ),
                    ),
    );
  }
}

// ── SOS Card ──────────────────────────────────────────────────────────────────

class _SOSAdminCard extends StatelessWidget {
  final Map item;
  final VoidCallback onUpdated;
  const _SOSAdminCard({required this.item, required this.onUpdated});

  @override
  Widget build(BuildContext context) {
    final status = item['status'] ?? '';
    final hasVideo = item['has_video'] == true;
    final videoUrl = item['video_url'] as String?;
    final thumbUrl = item['video_thumbnail_url'] as String?;
    final duration = item['video_duration'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withOpacity(0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Text(_categoryEmoji(item['category']),
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fmtLabel(item['category']),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '${item['student_name']} · ${item['roll_number']}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ]),
              ),
              _StatusBadge(status: status),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info rows
                  _InfoRow(icon: Icons.location_on, text: item['location'] ?? ''),
                  const SizedBox(height: 4),
                  _InfoRow(
                      icon: Icons.notes,
                      text: item['description'] ?? '',
                      maxLines: 2),
                  if (item['department'] != null) ...[
                    const SizedBox(height: 4),
                    _InfoRow(
                        icon: Icons.school, text: item['department']),
                  ],
                  if (item['is_anonymous'] == true) ...[
                    const SizedBox(height: 4),
                    const Row(children: [
                      Icon(Icons.person_off, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Anonymous submission',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey)),
                    ]),
                  ],

                  // ── Video Evidence Block ─────────────────────────────────
                  if (hasVideo) ...[
                    const SizedBox(height: 12),
                    _VideoEvidenceBlock(
                      videoUrl: videoUrl,
                      thumbnailUrl: thumbUrl,
                      duration: duration,
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Row(children: [
                        Icon(Icons.videocam_off,
                            size: 14, color: Colors.grey),
                        SizedBox(width: 6),
                        Text('No video evidence attached',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ]),
                    ),
                  ],

                  // ── Timeline last entry ─────────────────────────────────
                  if ((item['timeline'] as List?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.history, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          (item['timeline'] as List).last['message'] ?? '',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                          maxLines: 2,
                        ),
                      ),
                    ]),
                  ],

                  const SizedBox(height: 12),
                  // ── Submitted time + Update button ───────────────────────
                  Row(children: [
                    const Icon(Icons.access_time,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _fmtTime(item['created_at']),
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                        side: const BorderSide(color: Color(0xFFD32F2F)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.update, size: 16),
                      label: const Text('Update Status',
                          style: TextStyle(fontSize: 12)),
                      onPressed: () =>
                          _showUpdateDialog(context),
                    ),
                  ]),
                ]),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context) {
    final msgCtrl = TextEditingController();
    String selectedStatus = item['status'] ?? 'under_review';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setS) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.update, color: Color(0xFFD32F2F)),
                  const SizedBox(width: 10),
                  const Text('Update SOS Status',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                Text(
                  '${_fmtLabel(item['category'])} · ${item['student_name']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text('New Status',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'under_review',
                    'in_progress',
                    'resolved',
                    'rejected',
                  ].map((s) {
                    final sel = selectedStatus == s;
                    return ChoiceChip(
                      label: Text(
                        _fmtStatus(s),
                        style: TextStyle(
                          fontSize: 12,
                          color: sel ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: sel,
                      selectedColor: _statusColor(s),
                      onSelected: (_) =>
                          setS(() => selectedStatus = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Update Message for Student',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: msgCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Describe what action is being taken...',
                    hintStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFFD32F2F), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (msgCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Please add an update message')),
                        );
                        return;
                      }
                      try {
                        await ApiService().updateSOSStatus(
                            item['id'],
                            selectedStatus,
                            msgCtrl.text.trim());
                        Navigator.pop(ctx);
                        onUpdated();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Status updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Save Update',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Video Evidence Block ──────────────────────────────────────────────────────

class _VideoEvidenceBlock extends StatelessWidget {
  final String? videoUrl;
  final String? thumbnailUrl;
  final dynamic duration;

  const _VideoEvidenceBlock({
    this.videoUrl,
    this.thumbnailUrl,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    if (videoUrl == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade200)),
        child: const Row(children: [
          Icon(Icons.hourglass_empty, color: Colors.orange, size: 18),
          SizedBox(width: 8),
          Text('Video uploading…',
              style: TextStyle(fontSize: 12, color: Colors.orange)),
        ]),
      );
    }

    final durationStr = duration != null
        ? '${(duration as num).toStringAsFixed(0)}s'
        : '';

    return GestureDetector(
      onTap: () => _openVideo(context, videoUrl!),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Thumbnail or gradient background
              if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: Image.network(
                    thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackThumb(),
                  ),
                )
              else
                _fallbackThumb(),

              // Dark overlay
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.25),
                      Colors.black.withOpacity(0.65),
                    ],
                  ),
                ),
              ),

              // Play button
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26, blurRadius: 10)
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Color(0xFFD32F2F), size: 36),
              ),

              // Labels
              Positioned(
                bottom: 10,
                left: 12,
                right: 12,
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(children: [
                      Icon(Icons.videocam,
                          size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Evidence Video',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const Spacer(),
                  if (durationStr.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(durationStr,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white)),
                    ),
                ]),
              ),

              // "Tap to watch" label top-right
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(children: [
                    Icon(Icons.open_in_browser,
                        size: 11, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Tap to watch',
                        style: TextStyle(
                            fontSize: 10, color: Colors.white)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackThumb() => Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFB71C1C).withOpacity(0.8),
              const Color(0xFF6A1B9A).withOpacity(0.8)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.videocam,
            size: 48, color: Colors.white54),
      );
}

Future<void> _openVideo(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cannot open video: $url'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

String _categoryEmoji(String? cat) {
  const map = {
    'ragging': '🚫', 'harassment': '🛡️', 'medical': '🏥',
    'fire': '🔥', 'mental_health': '🧠', 'accident': '🤕',
    'theft': '🔓',
  };
  return map[cat] ?? '🆘';
}

String _fmtLabel(String? s) {
  if (s == null) return '';
  return s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String _fmtStatus(String s) => _fmtLabel(s);

String _fmtTime(String? iso) {
  if (iso == null) return '';
  try {
    return DateFormat('dd MMM yyyy, hh:mm a')
        .format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return '';
  }
}

Color _statusColor(String? s) {
  switch (s) {
    case 'submitted':    return const Color(0xFF1565C0);
    case 'under_review': return const Color(0xFFF57F17);
    case 'in_progress':  return const Color(0xFF6A1B9A);
    case 'resolved':     return const Color(0xFF2E7D32);
    case 'rejected':     return const Color(0xFFD32F2F);
    default:             return Colors.grey;
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor(status).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: _statusColor(status).withOpacity(0.4)),
        ),
        child: Text(
          _fmtStatus(status),
          style: TextStyle(
              fontSize: 10,
              color: _statusColor(status),
              fontWeight: FontWeight.bold),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;
  const _InfoRow(
      {required this.icon, required this.text, this.maxLines = 1});
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade700),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry')),
          ],
        ),
      );
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(message,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      );
}
