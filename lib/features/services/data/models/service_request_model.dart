import '../../domain/entities/service_request.dart';

class ServiceRequestModel extends ServiceRequest {
  const ServiceRequestModel({
    required super.id,
    required super.customerId,
    required super.customerName,
    required super.providerId,
    required super.providerName,
    required super.serviceCategory,
    required super.serviceType,
    required super.title,
    required super.description,
    required super.status,
    required super.priority,
    required super.requestedDate,
    super.scheduledDate,
    required super.location,
    required super.address,
    super.latitude,
    super.longitude,
    required super.requirements,
    super.estimatedPrice,
    super.finalPrice,
    required super.attachments,
    required super.createdAt,
    required super.updatedAt,
    super.notes,
    super.cancellationReason,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id: json['id'],
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      providerId: json['provider_id'],
      providerName: json['provider_name'],
      serviceCategory: json['service_category'],
      serviceType: json['service_type'],
      title: json['title'],
      description: json['description'],
      status: _statusFromString(json['status']),
      priority: _priorityFromString(json['priority']),
      requestedDate: DateTime.parse(json['requested_date']),
      scheduledDate:
          json['scheduled_date'] != null
              ? DateTime.parse(json['scheduled_date'])
              : null,
      location: json['location'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      requirements: Map<String, dynamic>.from(json['requirements'] ?? {}),
      estimatedPrice: json['estimated_price']?.toDouble(),
      finalPrice: json['final_price']?.toDouble(),
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      notes: json['notes'],
      cancellationReason: json['cancellation_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'provider_id': providerId,
      'provider_name': providerName,
      'service_category': serviceCategory,
      'service_type': serviceType,
      'title': title,
      'description': description,
      'status': _statusToString(status),
      'priority': _priorityToString(priority),
      'requested_date': requestedDate.toIso8601String(),
      'scheduled_date': scheduledDate?.toIso8601String(),
      'location': location,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'requirements': requirements,
      'estimated_price': estimatedPrice,
      'final_price': finalPrice,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'notes': notes,
      'cancellation_reason': cancellationReason,
    };
  }

  static ServiceRequestStatus _statusFromString(String status) {
    switch (status) {
      case 'pending':
        return ServiceRequestStatus.pending;
      case 'accepted':
        return ServiceRequestStatus.accepted;
      case 'in_progress':
        return ServiceRequestStatus.inProgress;
      case 'completed':
        return ServiceRequestStatus.completed;
      case 'cancelled':
        return ServiceRequestStatus.cancelled;
      case 'rejected':
        return ServiceRequestStatus.rejected;
      default:
        return ServiceRequestStatus.pending;
    }
  }

  static String _statusToString(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.pending:
        return 'pending';
      case ServiceRequestStatus.accepted:
        return 'accepted';
      case ServiceRequestStatus.inProgress:
        return 'in_progress';
      case ServiceRequestStatus.completed:
        return 'completed';
      case ServiceRequestStatus.cancelled:
        return 'cancelled';
      case ServiceRequestStatus.rejected:
        return 'rejected';
    }
  }

  static ServiceRequestPriority _priorityFromString(String priority) {
    switch (priority) {
      case 'low':
        return ServiceRequestPriority.low;
      case 'medium':
        return ServiceRequestPriority.medium;
      case 'high':
        return ServiceRequestPriority.high;
      case 'urgent':
        return ServiceRequestPriority.urgent;
      default:
        return ServiceRequestPriority.medium;
    }
  }

  static String _priorityToString(ServiceRequestPriority priority) {
    switch (priority) {
      case ServiceRequestPriority.low:
        return 'low';
      case ServiceRequestPriority.medium:
        return 'medium';
      case ServiceRequestPriority.high:
        return 'high';
      case ServiceRequestPriority.urgent:
        return 'urgent';
    }
  }

  factory ServiceRequestModel.fromEntity(ServiceRequest request) {
    return ServiceRequestModel(
      id: request.id,
      customerId: request.customerId,
      customerName: request.customerName,
      providerId: request.providerId,
      providerName: request.providerName,
      serviceCategory: request.serviceCategory,
      serviceType: request.serviceType,
      title: request.title,
      description: request.description,
      status: request.status,
      priority: request.priority,
      requestedDate: request.requestedDate,
      scheduledDate: request.scheduledDate,
      location: request.location,
      address: request.address,
      latitude: request.latitude,
      longitude: request.longitude,
      requirements: request.requirements,
      estimatedPrice: request.estimatedPrice,
      finalPrice: request.finalPrice,
      attachments: request.attachments,
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
      notes: request.notes,
      cancellationReason: request.cancellationReason,
    );
  }
}
