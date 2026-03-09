class CCTVAlert {
  final String id;
  final String cameraId;
  final String cameraLocation;
  final String incidentType;
  final String description;
  final double confidenceScore;
  final String? videoUrl;
  final String? videoThumbnailUrl;
  final double? videoDuration;
  final String status;
  final List<StatusUpdate> timeline;
  final DateTime detectedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;

  CCTVAlert({
    required this.id,
    required this.cameraId,
    required this.cameraLocation,
    required this.incidentType,
    required this.description,
    required this.confidenceScore,
    this.videoUrl,
    this.videoThumbnailUrl,
    this.videoDuration,
    required this.status,
    required this.timeline,
    required this.detectedAt,
    required this.createdAt,
    required this.updatedAt,
    this.acknowledgedBy,
    this.acknowledgedAt,
  });

  factory CCTVAlert.fromJson(Map<String, dynamic> json) {
    return CCTVAlert(
      id: json['id'],
      cameraId: json['camera_id'],
      cameraLocation: json['camera_location'],
      incidentType: json['incident_type'],
      description: json['description'],
      confidenceScore: (json['confidence_score'] ?? 0.85).toDouble(),
      videoUrl: json['video_url'],
      videoThumbnailUrl: json['video_thumbnail_url'],
      videoDuration: json['video_duration']?.toDouble(),
      status: json['status'],
      timeline: (json['timeline'] as List)
          .map((e) => StatusUpdate.fromJson(e))
          .toList(),
      detectedAt: DateTime.parse(json['detected_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      acknowledgedBy: json['acknowledged_by'],
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'])
          : null,
    );
  }

  String get incidentTypeDisplay {
    switch (incidentType) {
      case 'fighting':
        return 'Fighting';
      case 'large_crowd':
        return 'Large Crowd';
      case 'suspicious_activity':
        return 'Suspicious Activity';
      case 'vandalism':
        return 'Vandalism';
      case 'unauthorized_entry':
        return 'Unauthorized Entry';
      default:
        return 'Other';
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'submitted':
        return 'New Alert';
      case 'under_review':
        return 'Under Review';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }
}

class StatusUpdate {
  final String message;
  final String status;
  final DateTime updatedAt;
  final String? updatedBy;

  StatusUpdate({
    required this.message,
    required this.status,
    required this.updatedAt,
    this.updatedBy,
  });

  factory StatusUpdate.fromJson(Map<String, dynamic> json) {
    return StatusUpdate(
      message: json['message'],
      status: json['status'],
      updatedAt: DateTime.parse(json['updated_at']),
      updatedBy: json['updated_by'],
    );
  }
}
