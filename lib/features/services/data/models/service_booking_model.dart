import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/service_booking.dart';

class ServiceBookingModel extends ServiceBooking {
  const ServiceBookingModel({
    required super.id,
    required super.customerId,
    required super.customerName,
    required super.customerPhone,
    required super.customerEmail,
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
    super.completedDate,
    required super.serviceAddress,
    required super.city,
    required super.state,
    super.latitude,
    super.longitude,
    required super.serviceDetails,
    super.estimatedPrice,
    super.finalPrice,
    super.depositAmount,
    required super.depositPaid,
    required super.attachments,
    super.specialInstructions,
    required super.createdAt,
    required super.updatedAt,
    super.cancellationReason,
    super.rejectionReason,
    super.customerReview,
    super.providerNotes,
  });

  factory ServiceBookingModel.fromJson(Map<String, dynamic> json) {
    return ServiceBookingModel(
      id: json['id'],
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      customerEmail: json['customer_email'],
      providerId: json['provider_id'],
      providerName: json['provider_name'],
      serviceCategory: json['service_category'],
      serviceType: json['service_type'],
      title: json['title'],
      description: json['description'],
      status: _statusFromString(json['status']),
      priority: _priorityFromString(json['priority']),
      requestedDate: _parseDateTime(json['requested_date']),
      scheduledDate:
          json['scheduled_date'] != null
              ? _parseDateTime(json['scheduled_date'])
              : null,
      completedDate:
          json['completed_date'] != null
              ? _parseDateTime(json['completed_date'])
              : null,
      serviceAddress: json['service_address'],
      city: json['city'],
      state: json['state'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      serviceDetails: Map<String, dynamic>.from(json['service_details'] ?? {}),
      estimatedPrice: json['estimated_price']?.toDouble(),
      finalPrice: json['final_price']?.toDouble(),
      depositAmount: json['deposit_amount']?.toDouble(),
      depositPaid: json['deposit_paid'] ?? false,
      attachments: List<String>.from(json['attachments'] ?? []),
      specialInstructions: json['special_instructions'],
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      cancellationReason: json['cancellation_reason'],
      rejectionReason: json['rejection_reason'],
      customerReview:
          json['customer_review'] != null
              ? Map<String, dynamic>.from(json['customer_review'])
              : null,
      providerNotes:
          json['provider_notes'] != null
              ? Map<String, dynamic>.from(json['provider_notes'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'provider_id': providerId,
      'provider_name': providerName,
      'service_category': serviceCategory,
      'service_type': serviceType,
      'title': title,
      'description': description,
      'status': _statusToString(status),
      'priority': _priorityToString(priority),
      'requested_date': _dateTimeToTimestamp(requestedDate),
      'scheduled_date':
          scheduledDate != null ? _dateTimeToTimestamp(scheduledDate!) : null,
      'completed_date':
          completedDate != null ? _dateTimeToTimestamp(completedDate!) : null,
      'service_address': serviceAddress,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'service_details': serviceDetails,
      'estimated_price': estimatedPrice,
      'final_price': finalPrice,
      'deposit_amount': depositAmount,
      'deposit_paid': depositPaid,
      'attachments': attachments,
      'special_instructions': specialInstructions,
      'created_at': _dateTimeToTimestamp(createdAt),
      'updated_at': _dateTimeToTimestamp(updatedAt),
      'cancellation_reason': cancellationReason,
      'rejection_reason': rejectionReason,
      'customer_review': customerReview,
      'provider_notes': providerNotes,
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.parse(value);
    }

    return DateTime.now();
  }

  static Timestamp _dateTimeToTimestamp(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  static BookingStatus _statusFromString(String status) {
    switch (status) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'rejected':
        return BookingStatus.rejected;
      default:
        return BookingStatus.pending;
    }
  }

  static String _statusToString(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.rejected:
        return 'rejected';
    }
  }

  static BookingPriority _priorityFromString(String priority) {
    switch (priority) {
      case 'low':
        return BookingPriority.low;
      case 'medium':
        return BookingPriority.medium;
      case 'high':
        return BookingPriority.high;
      case 'urgent':
        return BookingPriority.urgent;
      default:
        return BookingPriority.medium;
    }
  }

  static String _priorityToString(BookingPriority priority) {
    switch (priority) {
      case BookingPriority.low:
        return 'low';
      case BookingPriority.medium:
        return 'medium';
      case BookingPriority.high:
        return 'high';
      case BookingPriority.urgent:
        return 'urgent';
    }
  }

  factory ServiceBookingModel.fromEntity(ServiceBooking booking) {
    return ServiceBookingModel(
      id: booking.id,
      customerId: booking.customerId,
      customerName: booking.customerName,
      customerPhone: booking.customerPhone,
      customerEmail: booking.customerEmail,
      providerId: booking.providerId,
      providerName: booking.providerName,
      serviceCategory: booking.serviceCategory,
      serviceType: booking.serviceType,
      title: booking.title,
      description: booking.description,
      status: booking.status,
      priority: booking.priority,
      requestedDate: booking.requestedDate,
      scheduledDate: booking.scheduledDate,
      completedDate: booking.completedDate,
      serviceAddress: booking.serviceAddress,
      city: booking.city,
      state: booking.state,
      latitude: booking.latitude,
      longitude: booking.longitude,
      serviceDetails: booking.serviceDetails,
      estimatedPrice: booking.estimatedPrice,
      finalPrice: booking.finalPrice,
      depositAmount: booking.depositAmount,
      depositPaid: booking.depositPaid,
      attachments: booking.attachments,
      specialInstructions: booking.specialInstructions,
      createdAt: booking.createdAt,
      updatedAt: booking.updatedAt,
      cancellationReason: booking.cancellationReason,
      rejectionReason: booking.rejectionReason,
      customerReview: booking.customerReview,
      providerNotes: booking.providerNotes,
    );
  }
}
