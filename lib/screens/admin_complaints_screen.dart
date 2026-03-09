import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});
  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
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
      final data = await ApiService().adminGetAllComplaints(
        status: (_filterStatus != null && _filterStatus != 'All')
            ? _filterStatus
            : null,
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
        backgroundColor: const Color(0xFF1565C0),
        automaticallyImplyLeading: false,
        title: Text(
          'Complaints (${_items.length})',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _statuses.length,
              itemBuilder: (ctx, i) {
                final s = _statuses[i];
                final sel = (_filterStatus == null && s == 'All') ||
                    _filterStatus == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_fmt(s)),
                    selected: sel,
                    onSelected: (_) {
                      setState(() =>
                          _filterStatus = s == 'All' ? null : s);
                      _load();
                    },
                    selectedColor: Colors.white,
                    labelStyle: TextStyle(
                        color: sel
                            ? const Color(0xFF1565C0)
                            : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
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
              child:
                  CircularProgressIndicator(color: Color(0xFF1565C0)))
          : _error != null
              ? Center(child: Text(_error!))
              : _items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.report_off,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No complaints found',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFF1565C0),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) => _ComplaintAdminCard(
                            item: _items[i], onUpdated: _load),
                      ),
                    ),
    );
  }
}

// ── Complaint Card ─────────────────────────────────────────────────────────────

class _ComplaintAdminCard extends StatelessWidget {
  final Map item;
  final VoidCallback onUpdated;
  const _ComplaintAdminCard(
      {required this.item, required this.onUpdated});

  @override
  Widget build(BuildContext context) {
    final status = item['status'] ?? '';
    // Prefer media_items (rich) → fall back to media_urls (legacy)
    final mediaItems = List<Map>.from(item['media_items'] ?? []);
    final mediaUrls = List<String>.from(item['media_urls'] ?? []);
    final mediaTypes = List<String>.from(item['media_types'] ?? []);
    final mediaCount = item['media_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: [
        // ── Header ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.07),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            const Icon(Icons.report,
                color: Color(0xFF1565C0), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['subject'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                        '${item['student_name']} · ${item['roll_number']}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ]),
            ),
            _StatusBadge(status: status),
          ]),
        ),

        // ── Body ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                    icon: Icons.category,
                    text: _fmt(item['category'])),
                const SizedBox(height: 4),
                _InfoRow(
                    icon: Icons.location_on,
                    text: item['location'] ?? ''),
                const SizedBox(height: 4),
                _InfoRow(
                    icon: Icons.notes,
                    text: item['description'] ?? '',
                    maxLines: 2),
                if (item['department'] != null) ...[
                  const SizedBox(height: 4),
                  _InfoRow(
                      icon: Icons.school,
                      text: item['department']),
                ],
                if (item['against_person'] != null &&
                    (item['against_person'] as String).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _InfoRow(
                    icon: Icons.person_search,
                    text:
                        'Against: ${item['against_person']}',
                  ),
                ],
                if (item['is_anonymous'] == true) ...[
                  const SizedBox(height: 4),
                  const Row(children: [
                    Icon(Icons.person_off,
                        size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('Anonymous submission',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ]),
                ],

                // ── Media Evidence Grid ──────────────────────────────
                if (mediaCount > 0) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.attach_file,
                        size: 14, color: Colors.teal),
                    const SizedBox(width: 6),
                    Text(
                      '$mediaCount evidence file${mediaCount > 1 ? 's' : ''} attached',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.teal,
                          fontWeight: FontWeight.w600),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  _MediaEvidenceGrid(
                    mediaItems: mediaItems,
                    mediaUrls: mediaUrls,
                    mediaTypes: mediaTypes,
                  ),
                ],

                // ── Timeline last entry ──────────────────────────────
                if ((item['timeline'] as List?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.history,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        (item['timeline'] as List).last['message'] ??
                            '',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                        maxLines: 2,
                      ),
                    ),
                  ]),
                ],

                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.access_time,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _fmtTime(item['created_at']),
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1565C0),
                      side: const BorderSide(
                          color: Color(0xFF1565C0)),
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
      ]),
    );
  }

  void _showUpdateDialog(BuildContext context) {
    final msgCtrl = TextEditingController();
    String selectedStatus = item['status'] ?? 'under_review';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setS) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.update,
                      color: Color(0xFF1565C0)),
                  const SizedBox(width: 10),
                  const Text('Update Complaint Status',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                Text(item['subject'] ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                const Text('New Status',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'under_review',
                    'in_progress',
                    'resolved',
                    'rejected',
                    'closed',
                  ].map((s) {
                    final sel = selectedStatus == s;
                    return ChoiceChip(
                      label: Text(_fmt(s),
                          style: TextStyle(
                              fontSize: 12,
                              color: sel
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w600)),
                      selected: sel,
                      selectedColor: _statusColor(s),
                      onSelected: (_) =>
                          setS(() => selectedStatus = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Response / Update Message',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: msgCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Provide an update message for the student...',
                    hintStyle:
                        const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF1565C0),
                            width: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (msgCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please add a message')));
                        return;
                      }
                      try {
                        await ApiService()
                            .updateComplaintStatus(
                                item['id'],
                                selectedStatus,
                                msgCtrl.text.trim());
                        Navigator.pop(ctx);
                        onUpdated();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text(
                              '✅ Status updated successfully'),
                          backgroundColor: Colors.green,
                        ));
                      } catch (e) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ));
                      }
                    },
                    child: const Text('Save Update',
                        style: TextStyle(
                            fontWeight: FontWeight.bold)),
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

// ── Media Evidence Grid ───────────────────────────────────────────────────────

class _MediaEvidenceGrid extends StatelessWidget {
  final List<Map> mediaItems;
  final List<String> mediaUrls;
  final List<String> mediaTypes;

  const _MediaEvidenceGrid({
    required this.mediaItems,
    required this.mediaUrls,
    required this.mediaTypes,
  });

  @override
  Widget build(BuildContext context) {
    // Prefer rich media_items; fall back to legacy media_urls
    final items = mediaItems.isNotEmpty
        ? mediaItems
        : _buildLegacyItems(mediaUrls, mediaTypes);

    if (items.isEmpty) {
      return const Text('No files uploaded yet',
          style: TextStyle(fontSize: 11, color: Colors.grey));
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final m = items[i];
          final url = m['url'] as String? ?? '';
          final thumb = m['thumbnail_url'] as String? ?? url;
          final isVideo =
              (m['resource_type'] as String? ?? 'image') == 'video';
          final filename =
              m['original_filename'] as String? ?? (isVideo ? 'Video' : 'Photo');
          final duration = m['duration'];

          return GestureDetector(
            onTap: () => _openUrl(context, url),
            child: Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isVideo
                    ? Colors.purple.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isVideo
                        ? Colors.purple.shade200
                        : Colors.blue.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail image — show for both photos AND video thumbnails
                    if (thumb.isNotEmpty)
                      Image.network(
                        thumb,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: isVideo ? Colors.purple.shade50 : Colors.blue.shade50,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                        errorBuilder: (_, __, ___) => _fallbackIcon(isVideo),
                      )
                    else
                      _fallbackIcon(isVideo),

                    // Dark overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),

                    // Play icon for videos
                    if (isVideo)
                      const Center(
                        child: Icon(Icons.play_circle_fill,
                            color: Colors.white, size: 32),
                      ),

                    // Label at bottom
                    Positioned(
                      bottom: 5,
                      left: 4,
                      right: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (duration != null)
                            Text(
                              '${(duration as num).toStringAsFixed(0)}s',
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          Text(
                            isVideo ? 'Video' : 'Photo',
                            style: const TextStyle(
                                fontSize: 9, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    // Top-right type badge
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: isVideo
                              ? Colors.purple.shade700
                              : Colors.blue.shade700,
                          borderRadius:
                              BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                isVideo
                                    ? Icons.videocam
                                    : Icons.image,
                                size: 9,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _fallbackIcon(bool isVideo) => Container(
        color: isVideo
            ? Colors.purple.shade100
            : Colors.blue.shade100,
        child: Icon(
            isVideo ? Icons.videocam : Icons.image,
            color: isVideo ? Colors.purple : Colors.blue,
            size: 36),
      );

  List<Map> _buildLegacyItems(
      List<String> urls, List<String> types) {
    return List.generate(urls.length, (i) {
      final isVid = i < types.length &&
          (types[i] == 'video' || types[i] == 'Video');
      return {
        'url': urls[i],
        'thumbnail_url': urls[i],
        'resource_type': isVid ? 'video' : 'image',
        'original_filename': isVid ? 'Video' : 'Photo',
      };
    });
  }
}

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Cannot open: $url'),
          backgroundColor: Colors.red),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

String _fmt(String? s) {
  if (s == null) return '';
  return s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) =>
          w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

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
    case 'closed':       return const Color(0xFF546E7A);
    case 'rejected':     return const Color(0xFFD32F2F);
    default:             return Colors.grey;
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor(status).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: _statusColor(status).withOpacity(0.4)),
        ),
        child: Text(_fmt(status),
            style: TextStyle(
                fontSize: 10,
                color: _statusColor(status),
                fontWeight: FontWeight.bold)),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;
  const _InfoRow(
      {required this.icon,
      required this.text,
      this.maxLines = 1});
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
