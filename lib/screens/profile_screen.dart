import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _locationSharing = true;
  bool _emergencyAlerts = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFFD32F2F),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, size: 44, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      const Text('Student Name', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
                        child: const Text('Roll No: 2023CS001 • CSE - 3rd Year', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emergency Info Card
                  _SectionCard(
                    title: 'Emergency Information',
                    icon: Icons.emergency,
                    iconColor: Colors.red,
                    children: [
                      _InfoRow(icon: Icons.bloodtype, label: 'Blood Group', value: 'B+'),
                      _InfoRow(icon: Icons.medical_information, label: 'Allergies', value: 'None known'),
                      _InfoRow(icon: Icons.phone, label: 'Emergency Contact', value: 'Parent: +91-98765-43210'),
                      _InfoRow(icon: Icons.location_city, label: 'Hostel', value: 'Block C, Room 204'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Academic Info
                  _SectionCard(
                    title: 'Academic Details',
                    icon: Icons.school,
                    iconColor: Colors.blue,
                    children: [
                      _InfoRow(icon: Icons.badge, label: 'Student ID', value: '2023CS001'),
                      _InfoRow(icon: Icons.calendar_today, label: 'Batch', value: '2023-2027'),
                      _InfoRow(icon: Icons.email, label: 'College Email', value: '2023cs001@college.edu'),
                      _InfoRow(icon: Icons.person_pin, label: 'Faculty Advisor', value: 'Dr. Sharma'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Settings
                  _SectionCard(
                    title: 'Settings',
                    icon: Icons.settings,
                    iconColor: Colors.grey.shade700,
                    children: [
                      _ToggleRow(
                        icon: Icons.notifications,
                        label: 'Push Notifications',
                        value: _notificationsEnabled,
                        onChanged: (v) => setState(() => _notificationsEnabled = v),
                      ),
                      _ToggleRow(
                        icon: Icons.location_on,
                        label: 'Location Sharing',
                        value: _locationSharing,
                        onChanged: (v) => setState(() => _locationSharing = v),
                      ),
                      _ToggleRow(
                        icon: Icons.warning_amber,
                        label: 'Emergency Alerts',
                        value: _emergencyAlerts,
                        onChanged: (v) => setState(() => _emergencyAlerts = v),
                      ),
                      _ToggleRow(
                        icon: Icons.dark_mode,
                        label: 'Dark Mode',
                        value: _darkMode,
                        onChanged: (v) => setState(() => _darkMode = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  _SectionCard(
                    title: 'Account',
                    icon: Icons.manage_accounts,
                    iconColor: Colors.purple,
                    children: [
                      _TileRow(icon: Icons.edit, label: 'Edit Profile', onTap: () {}),
                      _TileRow(icon: Icons.lock, label: 'Change Password', onTap: () {}),
                      _TileRow(icon: Icons.privacy_tip, label: 'Privacy Policy', onTap: () {}),
                      _TileRow(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),
                      _TileRow(
                        icon: Icons.logout,
                        label: 'Logout',
                        color: Colors.red,
                        onTap: () => _confirmLogout(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text('College SOS v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.iconColor, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Function(bool) onChanged;

  const _ToggleRow({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFFD32F2F)),
        ],
      ),
    );
  }
}

class _TileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _TileRow({required this.icon, required this.label, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade700;
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: c),
      title: Text(label, style: TextStyle(fontSize: 13, color: c)),
      trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}
