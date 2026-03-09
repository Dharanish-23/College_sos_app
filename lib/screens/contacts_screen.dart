import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/app_data.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  List<EmergencyContact> _contacts = List.from(AppData.emergencyContacts);

  final List<String> _categories = ['All', 'Security', 'Medical', 'Academic', 'Mental Health', 'Technical', 'Financial', 'Housing'];

  List<EmergencyContact> get _filtered {
    return _contacts.where((c) {
      final matchCat = _selectedCategory == 'All' || c.category == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty || c.name.toLowerCase().contains(_searchQuery.toLowerCase()) || c.role.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  List<EmergencyContact> get _favorites => _contacts.where((c) => c.isFavorite).toList();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFD32F2F),
          title: const Text('Contacts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'All Contacts'),
              Tab(text: 'Favorites ⭐'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AllContactsTab(
              contacts: _filtered,
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategoryChanged: (c) => setState(() => _selectedCategory = c),
              onSearchChanged: (v) => setState(() => _searchQuery = v),
              onFavoriteToggle: _toggleFavorite,
            ),
            _FavoritesTab(favorites: _favorites, onFavoriteToggle: _toggleFavorite),
          ],
        ),
      ),
    );
  }

  void _toggleFavorite(EmergencyContact contact) {
    setState(() {
      final index = _contacts.indexWhere((c) => c.name == contact.name);
      if (index != -1) {
        _contacts[index] = _contacts[index].copyWith(isFavorite: !_contacts[index].isFavorite);
      }
    });
  }
}

class _AllContactsTab extends StatelessWidget {
  final List<EmergencyContact> contacts;
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategoryChanged;
  final Function(String) onSearchChanged;
  final Function(EmergencyContact) onFavoriteToggle;

  const _AllContactsTab({
    required this.contacts, required this.categories, required this.selectedCategory,
    required this.onCategoryChanged, required this.onSearchChanged, required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFFD32F2F),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: TextField(
            onChanged: onSearchChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search, color: Colors.white60),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: categories.length,
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final selected = cat == selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => onCategoryChanged(cat),
                  selectedColor: const Color(0xFFD32F2F),
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontSize: 12),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: contacts.isEmpty
              ? const Center(child: Text('No contacts found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: contacts.length,
                  itemBuilder: (ctx, i) => _ContactCard(contact: contacts[i], onFavoriteToggle: onFavoriteToggle),
                ),
        ),
      ],
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  final List<EmergencyContact> favorites;
  final Function(EmergencyContact) onFavoriteToggle;

  const _FavoritesTab({required this.favorites, required this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No favorites yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 6),
            Text('Star contacts to add them here', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: favorites.length,
      itemBuilder: (ctx, i) => _ContactCard(contact: favorites[i], onFavoriteToggle: onFavoriteToggle),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final Function(EmergencyContact) onFavoriteToggle;

  const _ContactCard({required this.contact, required this.onFavoriteToggle});

  Color get _categoryColor {
    switch (contact.category) {
      case 'Security': return const Color(0xFF1565C0);
      case 'Medical': return const Color(0xFF2E7D32);
      case 'Mental Health': return const Color(0xFF7B1FA2);
      case 'Academic': return const Color(0xFFE65100);
      case 'Technical': return const Color(0xFF00838F);
      case 'Financial': return const Color(0xFFF57F17);
      case 'Housing': return const Color(0xFF5D4037);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: _categoryColor.withOpacity(0.15), shape: BoxShape.circle),
              child: Center(child: Text(contact.name[0], style: TextStyle(color: _categoryColor, fontWeight: FontWeight.bold, fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(contact.role, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _categoryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(contact.category, style: TextStyle(fontSize: 10, color: _categoryColor, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                GestureDetector(
                  onTap: () => onFavoriteToggle(contact),
                  child: Icon(contact.isFavorite ? Icons.star : Icons.star_border, color: contact.isFavorite ? Colors.amber : Colors.grey, size: 22),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling ${contact.name}: ${contact.phone}'), duration: const Duration(seconds: 2)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                    child: const Icon(Icons.call, color: Color(0xFF2E7D32), size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
