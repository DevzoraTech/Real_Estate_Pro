import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/properties/presentation/pages/property_list_page.dart';
import '../../features/properties/presentation/pages/property_detail_page.dart';
import '../../features/properties/presentation/pages/add_property_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/chat/presentation/chat_list_page.dart';
import '../../features/chat/presentation/improved_chat_page.dart';
import '../../features/properties/domain/entities/property.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String properties = '/properties';
  static const String propertyDetail = '/property-detail';
  static const String addProperty = '/add-property';
  static const String profile = '/profile';
  static const String favorites = '/favorites';
  static const String search = '/search';
  static const String chatList = '/chat-list';
  static const String chat = '/chat';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case properties:
        return MaterialPageRoute(builder: (_) => const PropertyListPage());
      case propertyDetail:
        final args = settings.arguments;
        if (args is Property) {
          return MaterialPageRoute(
            builder: (_) => PropertyDetailPage(property: args),
          );
        } else if (args is String) {
          return MaterialPageRoute(
            builder: (_) => PropertyDetailPage(propertyId: args),
          );
        } else {
          return MaterialPageRoute(
            builder:
                (_) => const Scaffold(
                  body: Center(child: Text('Invalid property detail argument')),
                ),
          );
        }
      case addProperty:
        return MaterialPageRoute(builder: (_) => const AddPropertyPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesPage());
      case search:
        return MaterialPageRoute(builder: (_) => const SearchPage());
      case chatList:
        return MaterialPageRoute(builder: (_) => const ChatListPage());
      case chat:
        final args = settings.arguments;
        if (args is Map<String, dynamic>) {
          final agentId = args['agentId'] as String?;
          final agentName = args['agentName'] as String?;
          if (agentId != null && agentName != null) {
            return MaterialPageRoute(
              builder: (_) => ImprovedChatPage(agentId: agentId, agentName: agentName),
            );
          }
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Invalid chat arguments')),
          ),
        );
      default:
        return MaterialPageRoute(
          builder:
              (_) =>
                  const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}
