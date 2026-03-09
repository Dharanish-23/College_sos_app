import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});
  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  List<dynamic> _students = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService().getStudentList();
      setState(() { _students = data; _filtered = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _students
          : _students.where((s) =>
              (s['name'] ?? '').toLowerCase().contains(q) ||
              (s['roll_number'] ?? '').toLowerCase().contains(q) ||
              (s['department'] ?? '').toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        automaticallyImplyLeading: false,
        title: Text('Students (${_students.length})',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
        ],
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name, roll no, department...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _searchCtrl.clear())
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
              : _error != null
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline, color: Colors.grey, size: 48),
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                    ]))
                  : _filtered.isEmpty
                      ? const Center(child: Text('No students found'))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) => _StudentCard(student: _filtered[i]),
                          ),
                        ),
        ),
      ]),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Map student;
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final name = student['name'] ?? 'Unknown';
    final roll = student['roll_number'] ?? '';
    final dept = student['department'] ?? 'N/A';
    final year = student['year'] ?? '';
    final hostel = student['hostel_block'] ?? '';
    final phone = student['phone'] ?? '';
    final blood = student['blood_group'] ?? '';
    final email = student['email'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF2E7D32).withOpacity(0.15),
            radius: 22,
            child: Text(name[0].toUpperCase(),
                style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('$roll · $dept', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(children: [
                const Divider(height: 1),
                const SizedBox(height: 10),
                _Detail(icon: Icons.email_outlined, label: 'Email', value: email),
                _Detail(icon: Icons.phone_outlined, label: 'Phone', value: phone),
                _Detail(icon: Icons.school_outlined, label: 'Year', value: year),
                _Detail(icon: Icons.home_outlined, label: 'Hostel', value: hostel),
                _Detail(icon: Icons.bloodtype_outlined, label: 'Blood Group', value: blood),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Detail({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label:', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(width: 6),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
