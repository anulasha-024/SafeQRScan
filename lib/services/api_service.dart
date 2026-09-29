import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static Future<Map<String, dynamic>> verifyQr(String qrText) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/verify/text');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'qr_payload': qrText,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed: ${response.body}');
    }
  }
}