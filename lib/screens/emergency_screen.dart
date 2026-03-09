import 'package:flutter/material.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        title: const Text('Emergency', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.history, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main SOS
            _SOSMainButton(context),
            const SizedBox(height: 20),
            const Text('Emergency Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _EmergencyGrid(),
            const SizedBox(height: 20),
            const Text('Emergency Procedures', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._procedures.map((p) => _ProcedureCard(procedure: p)),
          ],
        ),
      ),
    );
  }

  Widget _SOSMainButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD32F2F), Color(0xFF880E4F)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _confirmSOS(context),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sos, color: Colors.white, size: 56),
              SizedBox(height: 8),
              Text('PRESS FOR EMERGENCY', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              SizedBox(height: 4),
              Text('Alerts campus security & shares location', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSOS(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Emergency', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('Are you in a genuine emergency? This will alert Campus Security with your location.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🚨 Emergency Alert Sent! Help is on the way.'), backgroundColor: Colors.red, duration: Duration(seconds: 5)),
              );
            },
            child: const Text('YES, SEND ALERT'),
          ),
        ],
      ),
    );
  }
}

class _EmergencyGrid extends StatelessWidget {
  final List<Map<String, dynamic>> services = const [
    {'icon': Icons.local_police, 'label': 'Campus Police', 'phone': '100', 'color': Color(0xFF1565C0)},
    {'icon': Icons.local_hospital, 'label': 'Ambulance', 'phone': '108', 'color': Color(0xFF2E7D32)},
    {'icon': Icons.fire_truck, 'label': 'Fire Brigade', 'phone': '101', 'color': Color(0xFFE65100)},
    {'icon': Icons.psychology, 'label': 'Crisis Line', 'phone': '1800-HELP', 'color': Color(0xFF6A1B9A)},
    {'icon': Icons.security, 'label': 'Campus Security', 'phone': '1800-SEC', 'color': Color(0xFF00695C)},
    {'icon': Icons.female, 'label': 'Women Helpline', 'phone': '1091', 'color': Color(0xFFC62828)},
  ];

  const _EmergencyGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: services.length,
      itemBuilder: (context, i) {
        final s = services[i];
        return _ServiceCard(
          icon: s['icon'],
          label: s['label'],
          phone: s['phone'],
          color: s['color'],
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String phone;
  final Color color;

  const _ServiceCard({required this.icon, required this.label, required this.phone, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Calling $label: $phone'), duration: const Duration(seconds: 2)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 8),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), maxLines: 2),
                const SizedBox(height: 2),
                Text(phone, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final List<Map<String, dynamic>> _procedures = [
  {
    'title': 'Fire Emergency',
    'icon': '🔥',
    'steps': ['Activate fire alarm', 'Call fire brigade: 101', 'Evacuate using nearest exit', 'Do not use elevators', 'Assemble at designated zone'],
  },
  {
    'title': 'Medical Emergency',
    'icon': '🏥',
    'steps': ['Call ambulance: 108', 'Stay with the person', 'Do not move if spine injury suspected', 'Apply first aid if trained', 'Meet ambulance at entrance'],
  },
  {
    'title': 'Sexual Harassment',
    'icon': '🛡️',
    'steps': ['Go to a safe location', 'Contact Women Helpline: 1091', 'Report to ICC Committee', 'Preserve evidence', 'Seek counseling support'],
  },
  {
    'title': 'Ragging Incident',
    'icon': '🚫',
    'steps': ['Leave the situation immediately', 'Call Anti-Ragging Helpline', 'Report to Dean of Students', 'Document the incident', 'Seek peer support'],
  },
];

class _ProcedureCard extends StatefulWidget {
  final Map<String, dynamic> procedure;
  const _ProcedureCard({required this.procedure});

  @override
  State<_ProcedureCard> createState() => _ProcedureCardState();
}

class _ProcedureCardState extends State<_ProcedureCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final steps = widget.procedure['steps'] as List<String>;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: ExpansionTile(
        leading: Text(widget.procedure['icon'], style: const TextStyle(fontSize: 24)),
        title: Text(widget.procedure['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${steps.length} steps', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        children: steps.asMap().entries.map((e) => ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 12,
            backgroundColor: Colors.red.shade50,
            child: Text('${e.key + 1}', style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          title: Text(e.value, style: const TextStyle(fontSize: 13)),
        )).toList(),
      ),
    );
  }
}
