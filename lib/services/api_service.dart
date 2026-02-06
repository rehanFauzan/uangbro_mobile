import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';

import 'package:flutter/foundation.dart';

class ApiService {
  // Use localhost for Web/iOS, 10.0.2.2 for Android Emulator
  // Recommended local backend URL configuration:
  // - Run the PHP backend with: php -S localhost:8000 -t backend_api
  // - Android emulator should use 10.0.2.2 to reach host machine
  // - iOS simulator / web can use localhost
  // For a physical device, replace with your machine IP (e.g., 192.168.1.x:8000)
  static const String _backendHost = 'localhost';
  static const int _backendPort = 8080;
  static const String _backendPath = 'transaction_api.php';

  static String get baseUrl {
    const host = kIsWeb ? _backendHost : _backendHost;
    // Use 10.0.2.2 for Android emulator when running on emulator
    // We can't detect Android emulator from here reliably without platform checks,
    // so Android devs should prefer editing this constant or using their local IP.
    // However, for common emulator case change host manually to 10.0.2.2 if needed.
    return 'http://$host:$_backendPort/$_backendPath';
  }

  Future<List<Transaction>> getTransactions() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transaction.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add transaction');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Update an existing transaction. Backend accepts POST with same payload
  /// and will perform update when ID already exists.
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transaction.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update transaction');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl?id=$id"));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete transaction');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
