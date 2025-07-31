import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/utils/firebase_seeder.dart';

class AdminDebugPage extends StatefulWidget {
  const AdminDebugPage({super.key});

  @override
  State<AdminDebugPage> createState() => _AdminDebugPageState();
}

class _AdminDebugPageState extends State<AdminDebugPage> {
  bool _isSeeding = false;
  String _seedingStatus = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Debug'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Firebase Data Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This will create sample service providers and reviews in your Firebase database.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isSeeding ? null : _seedDatabase,
                      icon:
                          _isSeeding
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.cloud_upload),
                      label: Text(_isSeeding ? 'Seeding...' : 'Seed Database'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    if (_seedingStatus.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              _seedingStatus.contains('Error')
                                  ? Colors.red[50]
                                  : Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                _seedingStatus.contains('Error')
                                    ? Colors.red[200]!
                                    : Colors.green[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _seedingStatus.contains('Error')
                                  ? Icons.error
                                  : Icons.check_circle,
                              color:
                                  _seedingStatus.contains('Error')
                                      ? Colors.red
                                      : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _seedingStatus,
                                style: TextStyle(
                                  color:
                                      _seedingStatus.contains('Error')
                                          ? Colors.red[700]
                                          : Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What will be created:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      '6 Sample Service Providers',
                      'Real estate agents, contractors, designers, etc.',
                    ),
                    _buildInfoItem(
                      'Sample Reviews',
                      'Realistic reviews for each provider',
                    ),
                    _buildInfoItem(
                      'Proper Categories',
                      'All providers categorized correctly',
                    ),
                    _buildInfoItem(
                      'Ratings & Verification',
                      'Realistic ratings and verification status',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Important Notes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• This will only create data if the database is empty\n'
                      '• Make sure your Firebase project is properly configured\n'
                      '• You may need to create Firestore indexes for queries\n'
                      '• This is for development/testing purposes only',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _seedDatabase() async {
    setState(() {
      _isSeeding = true;
      _seedingStatus = '';
    });

    try {
      await FirebaseSeeder.seedAllData();
      setState(() {
        _seedingStatus = 'Successfully seeded database with sample data!';
      });
    } catch (e) {
      setState(() {
        _seedingStatus = 'Error seeding database: $e';
      });
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }
}
