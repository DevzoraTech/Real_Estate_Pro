import 'package:equatable/equatable.dart';

enum ServiceRequestStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
  rejected,
}

enum ServiceRequestPriority { low, medium, high, urgent }

class ServiceRequest extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final String providerId;
  final String providerName;
  final String serviceCategory;
  final String serviceType;
  final String title;
  final String description;
  final ServiceRequestStatus status;
  final ServiceRequestPriority priority;
  final DateTime requestedDate;
  final DateTime? scheduledDate;
  final String location;
  final String address;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic> requirements;
  final double? estimatedPrice;
  final double? finalPrice;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final String? cancellationReason;

  const ServiceRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.providerId,
    required this.providerName,
    required this.serviceCategory,
    required this.serviceType,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.requestedDate,
    this.scheduledDate,
    required this.location,
    required this.address,
    this.latitude,
    this.longitude,
    required this.requirements,
    this.estimatedPrice,
    this.finalPrice,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.cancellationReason,
  });

  bool get isPending => status == ServiceRequestStatus.pending;
  bool get isAccepted => status == ServiceRequestStatus.accepted;
  bool get isInProgress => status == ServiceRequestStatus.inProgress;
  bool get isCompleted => status == ServiceRequestStatus.completed;
  bool get isCancelled => status == ServiceRequestStatus.cancelled;
  bool get isRejected => status == ServiceRequestStatus.rejected;

  String get statusText {
    switch (status) {
      case ServiceRequestStatus.pending:
        return 'Pending';
      case ServiceRequestStatus.accepted:
        return 'Accepted';
      case ServiceRequestStatus.inProgress:
        return 'In Progress';
      case ServiceRequestStatus.completed:
        return 'Completed';
      case ServiceRequestStatus.cancelled:
        return 'Cancelled';
      case ServiceRequestStatus.rejected:
        return 'Rejected';
    }
  }

  String get priorityText {
    switch (priority) {
      case ServiceRequestPriority.low:
        return 'Low';
      case ServiceRequestPriority.medium:
        return 'Medium';
      case ServiceRequestPriority.high:
        return 'High';
      case ServiceRequestPriority.urgent:
        return 'Urgent';
    }
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    customerName,
    providerId,
    providerName,
    serviceCategory,
    serviceType,
    title,
    description,
    status,
    priority,
    requestedDate,
    scheduledDate,
    location,
    address,
    latitude,
    longitude,
    requirements,
    estimatedPrice,
    finalPrice,
    attachments,
    createdAt,
    updatedAt,
    notes,
    cancellationReason,
  ];
}
