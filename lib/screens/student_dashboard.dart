import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'raise_sos_screen.dart';
import 'raise_complaint_screen.dart';
import 'request_status_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          _StudentHomeTab(),
          RaiseSOSScreen(),
          RaiseComplaintScreen(),
          RequestStatusScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.sos_outlined), selectedIcon: Icon(Icons.sos), label: 'SOS'),
          NavigationDestination(icon: Icon(Icons.report_outlined), selectedIcon: Icon(Icons.report), label: 'Complaint'),
          NavigationDestination(icon: Icon(Icons.track_changes_outlined), selectedIcon: Icon(Icons.track_changes), label: 'Status'),
        ],
      ),
    );
  }
}

class _StudentHomeTab extends StatefulWidget {
  const _StudentHomeTab();
  @override
  State<_StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<_StudentHomeTab> {
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
      final data = await ApiService().getStudentDashboard();
      setState(() { _data = data; _loading = false; });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Failed to load dashboard'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = context.read<AppProvider>().currentUser!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFFD32F2F),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(student),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_loading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFFD32F2F)))),
                  if (_error != null) _errorWidget(),
                  if (!_loading && _error == null) ...[
                    _statsRow(),
                    const SizedBox(height: 16),
                    _emergencyBanner(),
                    const SizedBox(height: 18),
                    _actionButtons(),
                    const SizedBox(height: 20),
                    _recentActivity(),
                  ],
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(Map<String, dynamic> student) {
    return SliverAppBar(
      expandedHeight: 175,
      pinned: true,
      backgroundColor: const Color(0xFFD32F2F),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => _confirmLogout(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)]),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 24, backgroundColor: Colors.white24,
                      child: Text(student['name'][0], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Welcome, ${student['name'].toString().split(' ').first}!',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      Text('${student['roll_number']} · ${student['department'] ?? 'Student'}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ])),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _statPill('SOS', '${_data?['total_sos'] ?? 0}', Icons.sos),
                    const SizedBox(width: 8),
                    _statPill('Complaints', '${_data?['total_complaints'] ?? 0}', Icons.report),
                    const SizedBox(width: 8),
                    _statPill('Pending', '${_data?['pending_count'] ?? 0}', Icons.pending),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
      title: const Text('College SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statPill(String label, String count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 13),
        const SizedBox(width: 4),
        Text('$count $label', style: const TextStyle(color: Colors.white, fontSize: 11)),
      ]),
    );
  }

  Widget _statsRow() {
    final stats = [
      {'label': 'SOS Raised', 'value': '${_data?['total_sos'] ?? 0}', 'icon': Icons.sos, 'color': const Color(0xFFD32F2F)},
      {'label': 'Complaints', 'value': '${_data?['total_complaints'] ?? 0}', 'icon': Icons.report, 'color': const Color(0xFF1565C0)},
      {'label': 'Resolved', 'value': '${_data?['resolved_count'] ?? 0}', 'icon': Icons.check_circle, 'color': const Color(0xFF2E7D32)},
    ];
    return Row(
      children: stats.map((s) => Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
          child: Column(children: [
            Icon(s['icon'] as IconData, color: s['color'] as Color, size: 24),
            const SizedBox(height: 6),
            Text(s['value'] as String, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: s['color'] as Color)),
            Text(s['label'] as String, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ),
      ))).toList(),
    );
  }

  Widget _emergencyBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEF9A9A))),
      child: const Row(children: [
        Icon(Icons.phone_in_talk, color: Color(0xFFD32F2F), size: 26),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('24/7 Emergency Helpline', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB71C1C), fontSize: 13)),
          Text('Campus Security: 1800-111-2222', style: TextStyle(fontSize: 12, color: Color(0xFFD32F2F))),
        ])),
        Icon(Icons.chevron_right, color: Color(0xFFD32F2F)),
      ]),
    );
  }

  Widget _actionButtons() {
    final nav = context.findAncestorStateOfType<_StudentDashboardState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What do you need?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _ActionCard(icon: Icons.sos, label: 'Raise SOS', sub: 'Immediate emergency', color: const Color(0xFFD32F2F), onTap: () => nav?.setState(() => nav._tab = 1))),
          const SizedBox(width: 12),
          Expanded(child: _ActionCard(icon: Icons.report_problem, label: 'File Complaint', sub: 'Report an incident', color: const Color(0xFF1565C0), onTap: () => nav?.setState(() => nav._tab = 2))),
        ]),
        const SizedBox(height: 12),
        _ActionCard(icon: Icons.track_changes, label: 'Track My Requests', sub: 'View status of SOS & complaints', color: const Color(0xFF2E7D32), horizontal: true, onTap: () => nav?.setState(() => nav._tab = 3)),
      ],
    );
  }

  Widget _recentActivity() {
    final recentSos = List<Map>.from(_data?['recent_sos'] ?? []);
    final recentComplaints = List<Map>.from(_data?['recent_complaints'] ?? []);
    if (recentSos.isEmpty && recentComplaints.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...recentSos.take(2).map((s) => _ActivityCard(
          icon: Icons.sos, color: const Color(0xFFD32F2F),
          title: _formatCategory(s['category']),
          subtitle: s['description'] ?? '',
          status: s['status'] ?? '',
          time: s['created_at'] ?? '',
        )),
        ...recentComplaints.take(2).map((c) => _ActivityCard(
          icon: Icons.report, color: const Color(0xFF1565C0),
          title: c['subject'] ?? '',
          subtitle: _formatCategory(c['category']),
          status: c['status'] ?? '',
          time: c['created_at'] ?? '',
        )),
      ],
    );
  }

  Widget _errorWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        const Icon(Icons.wifi_off, color: Colors.grey, size: 40),
        const SizedBox(height: 10),
        Text(_error ?? 'Error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ]),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white),
            onPressed: () async {
              await context.read<AppProvider>().logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

String _formatCategory(String? cat) {
  if (cat == null) return '';
  return cat.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

Color _statusColor(String status) {
  switch (status) {
    case 'submitted': return const Color(0xFF1565C0);
    case 'under_review': return const Color(0xFFF57F17);
    case 'in_progress': return const Color(0xFF6A1B9A);
    case 'resolved': return const Color(0xFF2E7D32);
    case 'rejected': return const Color(0xFFD32F2F);
    default: return Colors.grey;
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final bool horizontal;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.sub, required this.color, this.horizontal = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]),
        child: horizontal
            ? Row(children: [
                Icon(icon, color: Colors.white, size: 30), const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
                const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(icon, color: Colors.white, size: 30), const SizedBox(height: 10),
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 3),
                Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String status;
  final String time;
  const _ActivityCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.status, required this.time});

  @override
  Widget build(BuildContext context) {
    String timeStr = '';
    try {
      timeStr = DateFormat('dd MMM, hh:mm a').format(DateTime.parse(time));
    } catch (_) {}
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18)),
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
