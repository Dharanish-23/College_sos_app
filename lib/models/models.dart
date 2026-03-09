import 'package:flutter/material.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum UserRole { student, admin }

enum SOSCategory {
  ragging,
  harassment,
  medical,
  fire,
  mentalHealth,
  accident,
  theft,
  other,
}

enum ComplaintCategory {
  ragging,
  harassment,
  discrimination,
  academicMisconduct,
  facilityIssue,
  staffConduct,
  financialIssue,
  other,
}

enum RequestStatus {
  submitted,
  underReview,
  inProgress,
  resolved,
  closed,
  rejected,
}

enum RequestType { sos, complaint }

// ─── Extensions ───────────────────────────────────────────────────────────────

extension SOSCategoryExtension on SOSCategory {
  String get label {
    switch (this) {
      case SOSCategory.ragging:       return 'Ragging';
      case SOSCategory.harassment:    return 'Harassment';
      case SOSCategory.medical:       return 'Medical Emergency';
      case SOSCategory.fire:          return 'Fire / Disaster';
      case SOSCategory.mentalHealth:  return 'Mental Health Crisis';
      case SOSCategory.accident:      return 'Accident / Injury';
      case SOSCategory.theft:         return 'Theft / Robbery';
      case SOSCategory.other:         return 'Other Emergency';
    }
  }

  String get emoji {
    switch (this) {
      case SOSCategory.ragging:       return '🚫';
      case SOSCategory.harassment:    return '🛡️';
      case SOSCategory.medical:       return '🏥';
      case SOSCategory.fire:          return '🔥';
      case SOSCategory.mentalHealth:  return '🧠';
      case SOSCategory.accident:      return '🤕';
      case SOSCategory.theft:         return '🔓';
      case SOSCategory.other:         return '🆘';
    }
  }

  Color get color {
    switch (this) {
      case SOSCategory.ragging:       return const Color(0xFFD32F2F);
      case SOSCategory.harassment:    return const Color(0xFF880E4F);
      case SOSCategory.medical:       return const Color(0xFF1B5E20);
      case SOSCategory.fire:          return const Color(0xFFE65100);
      case SOSCategory.mentalHealth:  return const Color(0xFF4A148C);
      case SOSCategory.accident:      return const Color(0xFF1A237E);
      case SOSCategory.theft:         return const Color(0xFF37474F);
      case SOSCategory.other:         return const Color(0xFF827717);
    }
  }
}

extension ComplaintCategoryExtension on ComplaintCategory {
  String get label {
    switch (this) {
      case ComplaintCategory.ragging:            return 'Ragging';
      case ComplaintCategory.harassment:         return 'Harassment / Bullying';
      case ComplaintCategory.discrimination:     return 'Discrimination';
      case ComplaintCategory.academicMisconduct: return 'Academic Misconduct';
      case ComplaintCategory.facilityIssue:      return 'Facility / Infrastructure';
      case ComplaintCategory.staffConduct:       return 'Staff Conduct';
      case ComplaintCategory.financialIssue:     return 'Financial Issue';
      case ComplaintCategory.other:              return 'Other';
    }
  }
}

extension RequestStatusExtension on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.submitted:    return 'Submitted';
      case RequestStatus.underReview:  return 'Under Review';
      case RequestStatus.inProgress:   return 'In Progress';
      case RequestStatus.resolved:     return 'Resolved';
      case RequestStatus.closed:       return 'Closed';
      case RequestStatus.rejected:     return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case RequestStatus.submitted:    return const Color(0xFF1565C0);
      case RequestStatus.underReview:  return const Color(0xFFF57F17);
      case RequestStatus.inProgress:   return const Color(0xFF6A1B9A);
      case RequestStatus.resolved:     return const Color(0xFF2E7D32);
      case RequestStatus.closed:       return const Color(0xFF546E7A);
      case RequestStatus.rejected:     return const Color(0xFFD32F2F);
    }
  }

  IconData get icon {
    switch (this) {
      case RequestStatus.submitted:    return Icons.send;
      case RequestStatus.underReview:  return Icons.manage_search;
      case RequestStatus.inProgress:   return Icons.pending_actions;
      case RequestStatus.resolved:     return Icons.check_circle;
      case RequestStatus.closed:       return Icons.lock;
      case RequestStatus.rejected:     return Icons.cancel;
    }
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

class Student {
  final String id;
  final String name;
  final String rollNumber;
  final String email;
  final String department;
  final String year;
  final String hostelBlock;
  final String phone;
  final String bloodGroup;

  const Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.email,
    required this.department,
    required this.year,
    required this.hostelBlock,
    required this.phone,
    required this.bloodGroup,
  });
}

class StatusUpdate {
  final String message;
  final DateTime time;
  final RequestStatus status;

  const StatusUpdate({
    required this.message,
    required this.time,
    required this.status,
  });
}

class SOSRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final SOSCategory category;
  final String description;
  final String location;
  final DateTime submittedAt;
  final RequestStatus status;
  final bool hasVideo;
  final String? videoPath;
  final List<StatusUpdate> timeline;
  final bool isAnonymous;

  SOSRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.category,
    required this.description,
    required this.location,
    required this.submittedAt,
    this.status = RequestStatus.submitted,
    this.hasVideo = false,
    this.videoPath,
    List<StatusUpdate>? timeline,
    this.isAnonymous = false,
  }) : timeline = timeline ?? [
          StatusUpdate(
            message: 'SOS alert submitted. Campus security notified.',
            time: submittedAt,
            status: RequestStatus.submitted,
          ),
        ];
}

class Complaint {
  final String id;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final ComplaintCategory category;
  final String subject;
  final String description;
  final String location;
  final DateTime submittedAt;
  final RequestStatus status;
  final List<String> mediaPaths;  // photo/video file paths
  final List<String> mediaTypes;  // 'photo' or 'video'
  final List<StatusUpdate> timeline;
  final bool isAnonymous;
  final String? againstPerson;

  Complaint({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.category,
    required this.subject,
    required this.description,
    required this.location,
    required this.submittedAt,
    this.status = RequestStatus.submitted,
    List<String>? mediaPaths,
    List<String>? mediaTypes,
    List<StatusUpdate>? timeline,
    this.isAnonymous = false,
    this.againstPerson,
  })  : mediaPaths = mediaPaths ?? [],
        mediaTypes = mediaTypes ?? [],
        timeline = timeline ?? [
              StatusUpdate(
                message: 'Complaint filed successfully. Under review.',
                time: submittedAt,
                status: RequestStatus.submitted,
              ),
            ];
}

// ─── Legacy models (kept for Resources/Contacts screens) ──────────────────────

class EmergencyContact {
  final String name;
  final String role;
  final String phone;
  final String? email;
  final bool isFavorite;
  final String category;

  const EmergencyContact({
    required this.name,
    required this.role,
    required this.phone,
    this.email,
    this.isFavorite = false,
    required this.category,
  });

  EmergencyContact copyWith({bool? isFavorite}) {
    return EmergencyContact(
      name: name, role: role, phone: phone, email: email,
      isFavorite: isFavorite ?? this.isFavorite, category: category,
    );
  }
}

class SOSResource {
  final String title;
  final String description;
  final String category;
  final String icon;
  final String? url;
  final String? phone;
  final String? email;

  const SOSResource({
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    this.url,
    this.phone,
    this.email,
  });
}

class AlertItem {
  final String title;
  final String message;
  final DateTime time;
  final AlertSeverity severity;
  bool isRead;

  AlertItem({
    required this.title,
    required this.message,
    required this.time,
    required this.severity,
    this.isRead = false,
  });
}

enum AlertSeverity { low, medium, high, critical }
