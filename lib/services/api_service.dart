import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';

import 'package:flutter/foundation.dart';

class ApiService {
  // Use localhost for Web/iOS, 10.0.2.2 for Android Emulator
  // Note: For real device, use your machine's local IP (e.g., 192.168.1.x)
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8888/uangbro_api/transaction_api.php";
    }
    
    // For Android Emulator, use 10.0.2.2
    // For iOS Simulator or macOS, use localhost
    // Since we can't easily import dart:io without breaking Web compilation in a single file,
    // we will Default to localhost (works for iOS/macOS).
    // UNCOMMENT formatting below if testing on Android Emulator:
    // return "http://10.0.2.2:8888/uangbro_api/transaction_api.php";
    
    return "http://localhost:8888/uangbro_api/transaction_api.php";
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

  Future<void> deleteTransaction(String id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl?id=$id"),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete transaction');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
