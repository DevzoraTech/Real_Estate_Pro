import 'package:flutter/material.dart';

class ServiceCategories {
  static const List<Map<String, dynamic>> categories = [
    {
      'id': 'real_estate_agents',
      'name': 'Real Estate Agents',
      'icon': Icons.business_center,
      'color': Color(0xFF2196F3),
      'description': 'Licensed real estate professionals',
    },
    {
      'id': 'property_owners',
      'name': 'Property Owners',
      'icon': Icons.home_work,
      'color': Color(0xFF4CAF50),
      'description': 'Direct property owners and landlords',
    },
    {
      'id': 'property_managers',
      'name': 'Property Managers',
      'icon': Icons.apartment,
      'color': Color(0xFF9C27B0),
      'description': 'Professional property management services',
    },
    {
      'id': 'home_inspectors',
      'name': 'Home Inspectors',
      'icon': Icons.search,
      'color': Color(0xFFFF9800),
      'description': 'Certified home inspection services',
    },
    {
      'id': 'mortgage_brokers',
      'name': 'Mortgage Brokers',
      'icon': Icons.account_balance,
      'color': Color(0xFF607D8B),
      'description': 'Mortgage and financing specialists',
    },
    {
      'id': 'interior_designers',
      'name': 'Interior Designers',
      'icon': Icons.design_services,
      'color': Color(0xFFE91E63),
      'description': 'Professional interior design services',
    },
    {
      'id': 'contractors',
      'name': 'Contractors',
      'icon': Icons.construction,
      'color': Color(0xFFFF5722),
      'description': 'Construction and renovation contractors',
    },
    {
      'id': 'lawyers',
      'name': 'Legal Services',
      'icon': Icons.gavel,
      'color': Color(0xFF795548),
      'description': 'Real estate lawyers and legal services',
    },
    {
      'id': 'insurance_agents',
      'name': 'Insurance Agents',
      'icon': Icons.security,
      'color': Color(0xFF3F51B5),
      'description': 'Property and home insurance specialists',
    },
    {
      'id': 'architects',
      'name': 'Architects',
      'icon': Icons.architecture,
      'color': Color(0xFF009688),
      'description': 'Licensed architects and designers',
    },
    {
      'id': 'landscapers',
      'name': 'Landscapers',
      'icon': Icons.grass,
      'color': Color(0xFF8BC34A),
      'description': 'Landscaping and garden design services',
    },
    {
      'id': 'cleaners',
      'name': 'Cleaning Services',
      'icon': Icons.cleaning_services,
      'color': Color(0xFF00BCD4),
      'description': 'Professional cleaning and maintenance',
    },
  ];

  static Map<String, dynamic>? getCategoryById(String id) {
    try {
      return categories.firstWhere((category) => category['id'] == id);
    } catch (e) {
      return null;
    }
  }

  static String getCategoryName(String id) {
    final category = getCategoryById(id);
    return category?['name'] ?? 'Unknown Service';
  }

  static IconData getCategoryIcon(String id) {
    final category = getCategoryById(id);
    return category?['icon'] ?? Icons.work;
  }

  static Color getCategoryColor(String id) {
    final category = getCategoryById(id);
    return category?['color'] ?? Colors.grey;
  }
}
