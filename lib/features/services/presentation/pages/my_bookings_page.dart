import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/service_booking.dart';
import '../../data/modice_booking_model.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view your bookings'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList(['pending', 'confirmed', 'in_progress']),
          _buildBookingsList(['completed']),
          _buildBookingsList([]),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<String> statusFilter) {
    final user = FirebaseAuth.instance.currentUser!;
    
    return StreamBuilder<QuerySnapshot>(
      stream: _buildBookingsQuery(user.uid, statusFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading bookings: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return _buildEmptyState(statusFilter);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final booking = ServiceBookingModel.fromJson({
              ...docs[index].data() as Map<String, dynamic>,
              'id': docs[index].id,
            });
            return _buildBookingCard(booking);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _buildBookingsQuery(String userId, List<String> statusFilter) {
    Query query = FirebaseFirestore.instance
        .collection('service_bookings')
        .where('customer_id', isEqualTo: userId);

    if (statusFilter.isNotEmpty) {
      query = query.where('status', whereIn: statusFilter);
    }

    return query.orderBy('created_at', descending: true).snapshots();
  }

  Widget _buildBookingCard(ServiceBookingModel booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(booking.status),
              ],
            ),
            const SizedBox(height: 8),

            // Provider info
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  booking.providerName,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Service type
            Row(
              children: [
                const Icon(Icons.work, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  booking.serviceType,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDate(booking.requestedDate),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Location
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.serviceAddress,
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              booking.description,
              style: TextStyle(color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (booking.canBeCancelled)
                  TextButton(
                    onPressed: () => _cancelBooking(booking),
                    child: const Text('Cancel'),
                  ),
                if (booking.canBeRated)
                  ElevatedButton(
                    onPressed: () => _rateService(booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Rate Service'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _viewBookingDetails(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        break;
      case BookingStatus.confirmed:
        color = Colors.blue;
        break;
      case BookingStatus.inProgress:
        color = Colors.purple;
        break;
      case BookingStatus.completed:
        color = Colors.green;
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        break;
      case BookingStatus.rejected:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(List<String> statusFilter) {
    String message;
    if (statusFilter.contains('pending') || statusFilter.contains('confirmed')) {
      message = 'No active bookings';
    } else if (statusFilter.contains('completed')) {
      message = 'No completed bookings';
    } else {
      message = 'No bookings yet';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_online,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Book a service to get started',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(BookingStatus status) {
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

  void _cancelBooking(ServiceBookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateBookingStatus(booking.id, BookingStatus.cancelled);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _rateService(ServiceBookingModel booking) {
    // TODO: Implement rating dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rating feature coming soon!')),
    );
  }

  void _viewBookingDetails(ServiceBookingModel booking) {
    // TODO: Implement booking details page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking details page coming soon!')),
    );
  }

  Future<void> _updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await FirebaseFirestore.instance
          .collection('service_bookings')
          .doc(bookingId)
          .update({
        'status': _statusToString(status),
        'updated_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking: $e')),
      );
    }
  }

  String _statusToString(BookingStatus status) {
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
}