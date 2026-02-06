import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/transaction_model.dart';

class ApiService {
  static const String _backendHost = 'localhost';
  static const int _backendPort = 8000;
  static const String _backendPath = 'transaction_api.php';

  static String get baseUrl {
    final host = kIsWeb ? _backendHost : _backendHost;
    return 'http://$host:$_backendPort/$_backendPath';
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'api_token');
    if (token != null && token.isNotEmpty) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  Future<void> logout() async {
    await _storage.delete(key: 'api_token');
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'profile_photo');
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: 'username');
  }

  Future<String?> getEmail() async {
    return await _storage.read(key: 'email');
  }

  Future<String?> getProfilePhoto() async {
    return await _storage.read(key: 'profile_photo');
  }

  Future<List<Transaction>> getTransactions() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(Uri.parse(baseUrl), headers: headers);

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
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode(transaction.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add transaction');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
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
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse("$baseUrl?id=$id"),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete transaction');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<String?> login(String username, String password) async {
    final url = Uri.parse('http://$_backendHost:$_backendPort/login.php');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    if (resp.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(resp.body);
      if (data['status'] == 'success' && data['api_token'] != null) {
        final token = data['api_token'];
        await _storage.write(key: 'api_token', value: token);
        if (data['username'] != null) {
          await _storage.write(key: 'username', value: data['username']);
        }
        if (data['email'] != null) {
          await _storage.write(key: 'email', value: data['email']);
        }
        return token;
      }
    }
    return null;
  }

  Future<String?> register(
    String username,
    String password,
    String email,
  ) async {
    final url = Uri.parse('http://$_backendHost:$_backendPort/register.php');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
        'email': email,
      }),
    );
    if (resp.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(resp.body);
      if (data['status'] == 'success' && data['api_token'] != null) {
        final token = data['api_token'];
        await _storage.write(key: 'api_token', value: token);
        if (data['username'] != null) {
          await _storage.write(key: 'username', value: data['username']);
        }
        if (data['email'] != null) {
          await _storage.write(key: 'email', value: data['email']);
        }
        return token;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> claimTransactions(List<String> ids) async {
    final url = Uri.parse(
      'http://$_backendHost:$_backendPort/claim_transactions.php',
    );
    final headers = await _authHeaders();
    final resp = await http.post(
      url,
      headers: headers,
      body: json.encode({'ids': ids}),
    );
    if (resp.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(resp.body);
      return data;
    }
    return {'status': 'error', 'message': 'HTTP ${resp.statusCode}'};
  }

  Future<Map<String, dynamic>> updateProfile(
    String username,
    List<int>? imageBytes,
  ) async {
    final url = Uri.parse(
      'http://$_backendHost:$_backendPort/update_profile.php',
    );
    final headers = await _authHeaders();
    final body = <String, dynamic>{'username': username};
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final b64 = base64.encode(imageBytes);
      body['image_base64'] = b64;
    }
    final resp = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );
    if (resp.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(resp.body);
      if (data['status'] == 'success') {
        if (data['username'] != null)
          await _storage.write(key: 'username', value: data['username']);
        if (data['profile_photo'] != null)
          await _storage.write(
            key: 'profile_photo',
            value: data['profile_photo'],
          );
      }
      return data;
    }
    return {'status': 'error', 'message': 'HTTP ${resp.statusCode}'};
  }
}
