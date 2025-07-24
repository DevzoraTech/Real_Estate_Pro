import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Update formatPrice to accept a currency argument and use the correct symbol.
const supportedCurrencies = [
  {'code': 'USD', 'symbol': '\$'},
  {'code': 'UGX', 'symbol': 'USh'},
  {'code': 'EUR', 'symbol': '€'},
];

class Helpers {
  static String formatPrice(double price, {String currency = 'USD'}) {
    final symbol =
        supportedCurrencies.firstWhere(
          (c) => c['code'] == currency,
          orElse: () => supportedCurrencies[0],
        )['symbol'];
    if (currency == 'UGX') {
      return '$symbol${price.toStringAsFixed(0)}';
    }
    return '$symbol${price.toStringAsFixed(2)}';
  }

  static String formatArea(double area) {
    return '${area.toStringAsFixed(0)} sq ft';
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }

  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String getPropertyStatusText(String status) {
    switch (status) {
      case 'for_sale':
        return 'For Sale';
      case 'for_rent':
        return 'For Rent';
      case 'sold':
        return 'Sold';
      case 'rented':
        return 'Rented';
      default:
        return capitalizeFirst(status);
    }
  }
}
