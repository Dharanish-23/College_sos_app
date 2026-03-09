import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'admin_sos_screen.dart';
import 'admin_complaints_screen.dart';
import 'admin_students_screen.dart';
import 'admin_cctv_screen.dart';
import 'cctv_video_analyzer_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: const [
        _AdminHomeTab(),
        AdminSOSScreen(),
        AdminComplaintsScreen(),
        AdminCCTVScreen(),
        AdminStudentsScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.sos_outlined), selectedIcon: Icon(Icons.sos), label: 'SOS'),
          NavigationDestination(icon: Icon(Icons.report_outlined), selectedIcon: Icon(Icons.report), label: 'Complaints'),
          NavigationDestination(icon: Icon(Icons.videocam_outlined), selectedIcon: Icon(Icons.videocam), label: 'CCTV'),
          NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people), label: 'Students'),
        ],
      ),
    );
  }
}

class _AdminHomeTab extends StatefulWidget {
  const _AdminHomeTab();
  @override
  State<_AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<_AdminHomeTab> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService().getAdminDashboard();
      setState(() { _data = data; _loading = false; });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Connection error'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AppProvider>().currentUser!;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF1565C0),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 155,
              pinned: true,
              backgroundColor: const Color(0xFF1565C0),
              actions: [
                IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => _logout(context)),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)]),
                  ),
                  child: SafeArea(child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        CircleAvatar(radius: 22, backgroundColor: Colors.white24,
                            child: Text(admin['name'][0], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Welcome, ${admin['name'].toString().split(' ').first}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const Text('College Administration', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ]),
                      ]),
                      const SizedBox(height: 10),
                      Text('Last updated: ${DateFormat('dd MMM, hh:mm a').format(DateTime.now())}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ]),
                  )),
                ),
              ),
              title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(delegate: SliverChildListDelegate([
                if (_loading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFF1565C0)))),
                if (_error != null) _errorCard(),
                if (!_loading && _error == null) ...[
                  _statsGrid(),
                  const SizedBox(height: 20),
                  _criticalAlerts(),
                  const SizedBox(height: 20),
                  _categoryBreakdown(),
                  const SizedBox(height: 20),
                  _recentActivity(),
                ],
                const SizedBox(height: 16),
              ])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsGrid() {
    final items = [
      {'label': 'Total Students', 'value': '${_data?['total_students'] ?? 0}', 'icon': Icons.people, 'color': const Color(0xFF1565C0)},
      {'label': 'Total SOS', 'value': '${_data?['total_sos'] ?? 0}', 'icon': Icons.sos, 'color': const Color(0xFFD32F2F)},
      {'label': 'Complaints', 'value': '${_data?['total_complaints'] ?? 0}', 'icon': Icons.report, 'color': const Color(0xFF6A1B9A)},
      {'label': 'CCTV Alerts', 'value': '${_data?['total_cctv_alerts'] ?? 0}', 'icon': Icons.videocam, 'color': const Color(0xFFE65100)},
      {'label': 'Pending SOS', 'value': '${_data?['pending_sos'] ?? 0}', 'icon': Icons.pending, 'color': const Color(0xFFF57C00)},
      {'label': 'Pending CCTV', 'value': '${_data?['pending_cctv_alerts'] ?? 0}', 'icon': Icons.warning, 'color': const Color(0xFFFF6F00)},
      {'label': 'Resolved Today', 'value': '${_data?['resolved_today'] ?? 0}', 'icon': Icons.check_circle, 'color': const Color(0xFF2E7D32)},
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: items.map((item) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(
              color: (item['color'] as Color).withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(item['value'] as String, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: item['color'] as Color)),
            Text(item['label'] as String, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ]),
      )).toList(),
    );
  }

  Widget _criticalAlerts() {
    final pendingSOS = _data?['pending_sos'] ?? 0;
    final pendingComp = _data?['pending_complaints'] ?? 0;
    if (pendingSOS == 0 && pendingComp == 0) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.notifications_active, color: Color(0xFFD32F2F), size: 18),
          SizedBox(width: 8),
          Text('Pending Actions Required', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB71C1C), fontSize: 13)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _AlertPill(label: '$pendingSOS SOS pending', color: const Color(0xFFD32F2F)),
          const SizedBox(width: 8),
          _AlertPill(label: '$pendingComp Complaints pending', color: const Color(0xFF6A1B9A)),
        ]),
      ]),
    );
  }

  Widget _categoryBreakdown() {
    final sosByCat = Map<String, dynamic>.from(_data?['sos_by_category'] ?? {});
    final compByCat = Map<String, dynamic>.from(_data?['complaints_by_category'] ?? {});
    if (sosByCat.isEmpty && compByCat.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Category Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      if (sosByCat.isNotEmpty) ...[
        const Text('SOS by Type', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: sosByCat.entries.map((e) =>
            _CategoryTag(label: _formatCategory(e.key), count: e.value, color: const Color(0xFFD32F2F))).toList()),
        const SizedBox(height: 12),
      ],
      if (compByCat.isNotEmpty) ...[
        const Text('Complaints by Type', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: compByCat.entries.map((e) =>
            _CategoryTag(label: _formatCategory(e.key), count: e.value, color: const Color(0xFF1565C0))).toList()),
      ],
    ]);
  }

  Widget _recentActivity() {
    final recentSos = List<Map>.from(_data?['recent_sos'] ?? []);
    final recentComp = List<Map>.from(_data?['recent_complaints'] ?? []);
    if (recentSos.isEmpty && recentComp.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Recent Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      ...recentSos.take(3).map((s) => _AdminActivityCard(
        icon: Icons.sos, color: const Color(0xFFD32F2F),
        title: _formatCategory(s['category']),
        subtitle: '${s['student_name']} · ${s['location']}',
        status: s['status'], time: s['created_at'],
      )),
      ...recentComp.take(3).map((c) => _AdminActivityCard(
        icon: Icons.report, color: const Color(0xFF6A1B9A),
        title: c['subject'] ?? '',
        subtitle: '${c['student_name']} · ${_formatCategory(c['category'])}',
        status: c['status'], time: c['created_at'],
      )),
    ]);
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        const Icon(Icons.wifi_off, color: Colors.grey, size: 40),
        const SizedBox(height: 10),
        Text(_error ?? 'Error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ]),
    );
  }

  void _logout(BuildContext context) async {
    await context.read<AppProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatCategory(String? cat) {
  if (cat == null) return '';
  return cat.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

Color _statusColor(String? status) {
  switch (status) {
    case 'submitted': return const Color(0xFF1565C0);
    case 'under_review': return const Color(0xFFF57F17);
    case 'in_progress': return const Color(0xFF6A1B9A);
    case 'resolved': return const Color(0xFF2E7D32);
    case 'rejected': return const Color(0xFFD32F2F);
    default: return Colors.grey;
  }
}

class _AlertPill extends StatelessWidget {
  final String label;
  final Color color;
  const _AlertPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String label;
  final dynamic count;
  final Color color;
  const _CategoryTag({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text('$label ($count)', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _AdminActivityCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? status;
  final String? time;
  const _AdminActivityCard({required this.icon, required this.color, required this.title, required this.subtitle, this.status, this.time});

  @override
  Widget build(BuildContext context) {
    String timeStr = '';
    try { timeStr = DateFormat('dd MMM, hh:mm a').format(DateTime.parse(time!).toLocal()); } catch (_) {}
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (timeStr.isNotEmpty) Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_formatCategory(status), style: TextStyle(fontSize: 10, color: _statusColor(status), fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
