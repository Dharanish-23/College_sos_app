import '../models/models.dart';

class AppData {
  static const List<EmergencyContact> emergencyContacts = [
    EmergencyContact(
      name: 'Campus Security',
      role: 'Security Office',
      phone: '1800-111-2222',
      email: 'security@college.edu',
      isFavorite: true,
      category: 'Security',
    ),
    EmergencyContact(
      name: 'Student Health Center',
      role: 'Medical Services',
      phone: '1800-333-4444',
      email: 'health@college.edu',
      isFavorite: true,
      category: 'Medical',
    ),
    EmergencyContact(
      name: 'Dean of Students',
      role: 'Academic Affairs',
      phone: '1800-555-6666',
      email: 'dean@college.edu',
      category: 'Academic',
    ),
    EmergencyContact(
      name: 'Counseling Center',
      role: 'Mental Health Support',
      phone: '1800-777-8888',
      email: 'counseling@college.edu',
      isFavorite: true,
      category: 'Mental Health',
    ),
    EmergencyContact(
      name: 'IT Help Desk',
      role: 'Technical Support',
      phone: '1800-999-0000',
      email: 'helpdesk@college.edu',
      category: 'Technical',
    ),
    EmergencyContact(
      name: 'Financial Aid Office',
      role: 'Financial Services',
      phone: '1800-123-4567',
      email: 'finaid@college.edu',
      category: 'Financial',
    ),
    EmergencyContact(
      name: 'Residential Life',
      role: 'Housing & Dorms',
      phone: '1800-234-5678',
      email: 'reslife@college.edu',
      category: 'Housing',
    ),
    EmergencyContact(
      name: 'Campus Police',
      role: 'Law Enforcement',
      phone: '100',
      email: 'police@college.edu',
      isFavorite: true,
      category: 'Security',
    ),
  ];

  static const List<SOSResource> resources = [
    SOSResource(
      title: 'Mental Health Crisis Line',
      description: '24/7 confidential support for emotional distress',
      category: 'Mental Health',
      icon: '🧠',
      phone: '1800-MENTAL',
    ),
    SOSResource(
      title: 'Sexual Assault Helpline',
      description: 'Confidential support and resources for survivors',
      category: 'Safety',
      icon: '🛡️',
      phone: '1800-SAFE-01',
    ),
    SOSResource(
      title: 'Substance Abuse Hotline',
      description: 'Help with alcohol and drug-related concerns',
      category: 'Health',
      icon: '💊',
      phone: '1800-DRUG-01',
    ),
    SOSResource(
      title: 'Academic Integrity Office',
      description: 'Report academic misconduct or get guidance',
      category: 'Academic',
      icon: '📚',
      email: 'integrity@college.edu',
    ),
    SOSResource(
      title: 'Anti-Ragging Committee',
      description: 'Report ragging incidents immediately',
      category: 'Safety',
      icon: '🚫',
      phone: '1800-RAGGING',
    ),
    SOSResource(
      title: 'Grievance Redressal',
      description: 'Submit formal complaints against staff or students',
      category: 'Legal',
      icon: '⚖️',
      email: 'grievance@college.edu',
    ),
    SOSResource(
      title: 'Fire & Evacuation Guide',
      description: 'Emergency evacuation procedures and maps',
      category: 'Safety',
      icon: '🔥',
      url: 'https://college.edu/fire-safety',
    ),
    SOSResource(
      title: 'First Aid Manual',
      description: 'Basic first aid instructions for common injuries',
      category: 'Medical',
      icon: '🩹',
      url: 'https://college.edu/first-aid',
    ),
    SOSResource(
      title: 'Legal Aid Cell',
      description: 'Free legal consultation for students',
      category: 'Legal',
      icon: '🏛️',
      email: 'legalaid@college.edu',
    ),
    SOSResource(
      title: 'Scholarship Emergency Fund',
      description: 'Emergency financial assistance for students in need',
      category: 'Financial',
      icon: '💰',
      email: 'emergencyfund@college.edu',
    ),
  ];
}
