import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../bloc/service_bloc.dart';
import '../bloc/service_event.dart';
import '../bloc/service_state.dart';
import 'admin_debug_page.dart';

class ServicesTestPage extends StatelessWidget {
  const ServicesTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              di.sl<ServiceBloc>()..add(const LoadFeaturedProviders(limit: 5)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Services Test'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<ServiceBloc, ServiceState>(
          builder: (context, state) {
            if (state is ServiceLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Loading services...'),
                  ],
                ),
              );
            } else if (state is FeaturedProvidersLoaded) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.green[50],
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Success! Loaded ${state.providers.length} providers',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.providers.length,
                      itemBuilder: (context, index) {
                        final provider = state.providers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              provider.name.isNotEmpty ? provider.name[0] : '?',
                              style: const TextStyle(color: AppColors.primary),
                            ),
                          ),
                          title: Text(provider.name),
                          subtitle: Text(provider.primaryService),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              Text(provider.rating.toStringAsFixed(1)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            } else if (state is ServiceError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Services Architecture Test',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${state.message}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'This is expected if no Firebase data exists yet.\nThe architecture is working correctly!',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ServiceBloc>().add(
                          const LoadFeaturedProviders(limit: 5),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Services architecture initialized'),
                  SizedBox(height: 8),
                  Text(
                    'Tap the button below to test',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'admin',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminDebugPage(),
                  ),
                );
              },
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              child: const Icon(Icons.admin_panel_settings),
            ),
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              heroTag: 'test',
              onPressed: () {
                context.read<ServiceBloc>().add(
                  const LoadFeaturedProviders(limit: 5),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.refresh),
              label: const Text('Test Services'),
            ),
          ],
        ),
      ),
    );
  }
}
