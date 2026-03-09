import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class RequestStatusScreen extends StatefulWidget {
  const RequestStatusScreen({super.key});

  @override
  State<RequestStatusScreen> createState() => _RequestStatusScreenState();
}

class _RequestStatusScreenState extends State<RequestStatusScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _sosList = [];
  List<dynamic> _complaintList = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final sos = await ApiService().getMySOS();
      final complaints = await ApiService().getMyComplaints();
      setState(() {
        _sosList = sos;
        _complaintList = complaints;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load. Check connection.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        automaticallyImplyLeading: false,
        title: const Text('Request Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'SOS Alerts (${_sosList.length})'),
            Tab(text: 'Complaints (${_complaintList.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _error != null
              ? _ErrorWidget(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF2E7D32),
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _SOSTab(items: _sosList),
                      _ComplaintsTab(items: _complaintList),
                    ],
                  ),
                ),
    );
  }
}

// ─── SOS Tab ─────────────────────────────────────────────────────────────────

class _SOSTab extends StatelessWidget {
  final List<dynamic> items;
  const _SOSTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(icon: Icons.sos, message: 'No SOS alerts raised yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _SOSCard(item: items[i] as Map),
    );
  }
}

class _SOSCard extends StatelessWidget {
  final Map item;
  const _SOSCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item['status'] ?? '';
    final category = item['category'] ?? '';
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => _DetailScreen(item: item, type: 'sos'))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(children: [
              Text(_categoryEmoji(category), style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_formatCategory(category), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(_formatTime(item['created_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ])),
              _StatusBadge(status: status),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _InfoRow(icon: Icons.location_on, label: item['location'] ?? ''),
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.notes, label: item['description'] ?? '', maxLines: 2),
              if (item['has_video'] == true) ...[
                const SizedBox(height: 6),
                const Row(children: [
                  Icon(Icons.videocam, size: 14, color: Colors.purple),
                  SizedBox(width: 4),
                  Text('Video evidence attached', style: TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.w500)),
                ]),
              ],
              if (item['is_anonymous'] == true) ...[
                const SizedBox(height: 6),
                const Row(children: [
                  Icon(Icons.person_off, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('Submitted anonymously', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ]),
              ],
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('ID: ${(item['id'] ?? '').toString().substring(0, 8).toUpperCase()}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace')),
                const Row(children: [
                  Text('View Timeline', style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF2E7D32)),
                ]),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Complaints Tab ──────────────────────────────────────────────────────────

class _ComplaintsTab extends StatelessWidget {
  final List<dynamic> items;
  const _ComplaintsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(icon: Icons.report, message: 'No complaints filed yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _ComplaintCard(item: items[i] as Map),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Map item;
  const _ComplaintCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item['status'] ?? '';
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => _DetailScreen(item: item, type: 'complaint'))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(children: [
              const Icon(Icons.report, color: Color(0xFF1565C0), size: 24),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(_formatTime(item['created_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ])),
              _StatusBadge(status: status),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _InfoRow(icon: Icons.category, label: _formatCategory(item['category'])),
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.location_on, label: item['location'] ?? ''),
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.notes, label: item['description'] ?? '', maxLines: 2),
              if ((item['media_count'] ?? 0) > 0) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.attach_file, size: 14, color: Colors.teal),
                  const SizedBox(width: 4),
                  Text('${item['media_count']} attachment(s)',
                      style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w500)),
                ]),
              ],
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('ID: ${(item['id'] ?? '').toString().substring(0, 8).toUpperCase()}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace')),
                const Row(children: [
                  Text('View Details', style: TextStyle(fontSize: 12, color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF1565C0)),
                ]),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Detail Screen ────────────────────────────────────────────────────────────

class _DetailScreen extends StatelessWidget {
  final Map item;
  final String type; // 'sos' or 'complaint'
  const _DetailScreen({required this.item, required this.type});

  @override
  Widget build(BuildContext context) {
    final isSOS = type == 'sos';
    final color = isSOS ? const Color(0xFFD32F2F) : const Color(0xFF1565C0);
    final title = isSOS ? 'SOS: ${_formatCategory(item['category'])}' : 'Complaint Details';
    final timeline = (item['timeline'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: color,
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Details card
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
            child: Column(children: [
              if (isSOS) ...[
                _DetailRow(label: 'Category', value: _formatCategory(item['category'])),
                _Divider(),
                _DetailRow(label: 'Date & Time', value: _formatTime(item['created_at'])),
                _Divider(),
                _DetailRow(label: 'Location', value: item['location'] ?? ''),
                _Divider(),
                _DetailRow(label: 'Description', value: item['description'] ?? ''),
                _Divider(),
                _DetailRow(label: 'Video Evidence', value: item['has_video'] == true ? '✅ Attached' : 'None'),
              ] else ...[
                _DetailRow(label: 'Subject', value: item['subject'] ?? ''),
                _Divider(),
                _DetailRow(label: 'Category', value: _formatCategory(item['category'])),
                _Divider(),
                _DetailRow(label: 'Date Filed', value: _formatTime(item['created_at'])),
                _Divider(),
                _DetailRow(label: 'Location', value: item['location'] ?? ''),
                if (item['against_person'] != null) ...[
                  _Divider(),
                  _DetailRow(label: 'Against', value: item['against_person']),
                ],
                _Divider(),
                _DetailRow(label: 'Description', value: item['description'] ?? ''),
                _Divider(),
                _DetailRow(label: 'Attachments', value: (item['media_count'] ?? 0) == 0 ? 'None' : '${item['media_count']} file(s)'),
              ],
              _Divider(),
              _DetailRow(label: 'Submitted By', value: item['is_anonymous'] == true ? 'Anonymous' : (item['student_name'] ?? '')),
              _Divider(),
              _DetailRow(label: 'Reference ID', value: (item['id'] ?? '').toString().substring(0, 8).toUpperCase(), mono: true),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Status Timeline', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (timeline.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: const Text('No timeline updates yet.', style: TextStyle(color: Colors.grey)),
            )
          else
            _TimelineWidget(timeline: timeline),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

// ─── Timeline ─────────────────────────────────────────────────────────────────

class _TimelineWidget extends StatelessWidget {
  final List timeline;
  const _TimelineWidget({required this.timeline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
      child: Column(
        children: timeline.asMap().entries.map((entry) {
          final i = entry.key;
          final update = entry.value as Map;
          final isLast = i == timeline.length - 1;
          final status = update['status'] ?? '';
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: _statusColor(status), width: 1.5),
                  ),
                  child: Icon(_statusIcon(status), size: 16, color: _statusColor(status)),
                ),
                if (!isLast) Container(width: 2, height: 36, color: Colors.grey.shade200),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(_formatCategory(status),
                          style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Text(update['message'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 2),
                    if (update['updated_by'] != null)
                      Text('By ${update['updated_by']}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                    Text(_formatTime(update['updated_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ]),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Helpers & Shared Widgets ─────────────────────────────────────────────────

String _formatCategory(String? cat) {
  if (cat == null) return '';
  return cat.replaceAll('_', ' ').split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

String _formatTime(dynamic t) {
  if (t == null) return '';
  try { return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(t.toString()).toLocal()); } catch (_) { return t.toString(); }
}

String _categoryEmoji(String? cat) {
  switch (cat) {
    case 'ragging': return '🚫';
    case 'harassment': return '🛡️';
    case 'medical': return '🏥';
    case 'fire': return '🔥';
    case 'mental_health': return '🧠';
    case 'accident': return '🤕';
    case 'theft': return '🔓';
    default: return '🆘';
  }
}

Color _statusColor(String? s) {
  switch (s) {
    case 'submitted': return const Color(0xFF1565C0);
    case 'under_review': return const Color(0xFFF57F17);
    case 'in_progress': return const Color(0xFF6A1B9A);
    case 'resolved': return const Color(0xFF2E7D32);
    case 'closed': return const Color(0xFF546E7A);
    case 'rejected': return const Color(0xFFD32F2F);
    default: return Colors.grey;
  }
}

IconData _statusIcon(String? s) {
  switch (s) {
    case 'submitted': return Icons.send;
    case 'under_review': return Icons.manage_search;
    case 'in_progress': return Icons.pending_actions;
    case 'resolved': return Icons.check_circle;
    case 'closed': return Icons.lock;
    case 'rejected': return Icons.cancel;
    default: return Icons.circle;
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: _statusColor(status).withOpacity(0.12), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _statusColor(status).withOpacity(0.4))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_statusIcon(status), size: 12, color: _statusColor(status)),
        const SizedBox(width: 4),
        Text(_formatCategory(status), style: TextStyle(fontSize: 10, color: _statusColor(status), fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int maxLines;
  const _InfoRow({required this.icon, required this.label, this.maxLines = 1});
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 14, color: Colors.grey.shade500),
      const SizedBox(width: 6),
      Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          maxLines: maxLines, overflow: TextOverflow.ellipsis)),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
      const SizedBox(height: 6),
      Text('Your requests will appear here', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
    ]));
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off, color: Colors.grey, size: 48),
      const SizedBox(height: 12),
      Text(error, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
    ]));
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  const _DetailRow({required this.label, required this.value, this.mono = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: mono ? 'monospace' : null))),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(height: 1, indent: 14, endIndent: 14, color: Colors.grey.shade100);
}
