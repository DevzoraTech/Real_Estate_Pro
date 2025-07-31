import 'package:equatable/equatable.dart';

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rejected,
}

enum BookingPriority { low, medium, high, urgent }

class ServiceBooking extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String providerId;
  final String providerName;
  final String serviceCategory;
  final String serviceType;
  final String title;
  final String description;
  final BookingStatus status;
  final BookingPriority priority;
  final DateTime requestedDate;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final String serviceAddress;
  final String city;
  final String state;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic> serviceDetails;
  final double? estimatedPrice;
  final double? finalPrice;
  final double? depositAmount;
  final bool depositPaid;
  final List<String> attachments;
  final String? specialInstructions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? cancellationReason;
  final String? rejectionReason;
  final Map<String, dynamic>? customerReview;
  final Map<String, dynamic>? providerNotes;

  const ServiceBooking({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
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
    this.completedDate,
    required this.serviceAddress,
    required this.city,
    required this.state,
    this.latitude,
    this.longitude,
    required this.serviceDetails,
    this.estimatedPrice,
    this.finalPrice,
    this.depositAmount,
    required this.depositPaid,
    required this.attachments,
    this.specialInstructions,
    required this.createdAt,
    required this.updatedAt,
    this.cancellationReason,
    this.rejectionReason,
    this.customerReview,
    this.providerNotes,
  });

  bool get isPending => status == BookingStatus.pending;
  bool get isConfirmed => status == BookingStatus.confirmed;
  bool get isInProgress => status == BookingStatus.inProgress;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isCancelled => status == BookingStatus.cancelled;
  bool get isRejected => status == BookingStatus.rejected;

  String get statusText {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.rejected:
        return 'Rejected';
    }
  }

  String get priorityText {
    switch (priority) {
      case BookingPriority.low:
        return 'Low';
      case BookingPriority.medium:
        return 'Medium';
      case BookingPriority.high:
        return 'High';
      case BookingPriority.urgent:
        return 'Urgent';
    }
  }

  String get fullAddress => '$serviceAddress, $city, $state';

  @override
  List<Object?> get props => [
    id,
    customerId,
    customerName,
    customerPhone,
    customerEmail,
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
    completedDate,
    serviceAddress,
    city,
    state,
    latitude,
    longitude,
    serviceDetails,
    estimatedPrice,
    finalPrice,
    depositAmount,
    depositPaid,
    attachments,
    specialInstructions,
    createdAt,
    updatedAt,
    cancellationReason,
    rejectionReason,
    customerReview,
    providerNotes,
  ];
}
