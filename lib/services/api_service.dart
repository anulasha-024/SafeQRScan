import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static Future<dynamic> _request(String path, {Map<String, dynamic>? body}) async {
    final client = http.Client();
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path');
      final response = await (body == null
          ? client.get(uri)
          : client.post(uri, headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body))).timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('The server could not complete the request (${response.statusCode}).');
      }
      return jsonDecode(response.body);
    } on TimeoutException {
      throw Exception('The server took too long. Check the backend connection and try again.');
    } on http.ClientException {
      throw Exception('Cannot reach the backend. Check API_BASE_URL and your network.');
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> verifyQr(String qrText) async {
    return Map<String, dynamic>.from(await _request('/verify/text',
        body: {'qr_payload': qrText}));
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final data = await _request('/logs/') as List;
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  static Future<void> reportQr(String payload, String reason) async {
    await _request('/reports/', body: {'qr_payload': payload, 'reason': reason});
  }
}
