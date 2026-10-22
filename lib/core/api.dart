import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Semua panggilan ke api.php. URL server disimpan di HP (bisa diganti kapan saja,
/// jadi tidak perlu build ulang APK saat pindah server).
class Api {
  static String baseUrl = ''; // contoh: http://1.2.3.4/dashboard
  static String token = ''; // dipakai nanti kalau api.php sudah punya auth

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    baseUrl = p.getString('api_base') ?? '';
    token = p.getString('api_token') ?? '';
  }

  static Future<void> save(String base, String tok) async {
    var b = base.trim();
    while (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    baseUrl = b;
    token = tok.trim();
    final p = await SharedPreferences.getInstance();
    await p.setString('api_base', baseUrl);
    await p.setString('api_token', token);
  }

  static Uri _uri(String action, [Map<String, String>? extra]) =>
      Uri.parse('$baseUrl/api.php')
          .replace(queryParameters: {'action': action, ...?extra});

  /// GET (body null) atau POST JSON (body diisi) -- sama seperti fungsi api() di index.php
  static Future<Map<String, dynamic>> call(
    String action, {
    String? username,
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    if (baseUrl.isEmpty) throw ApiException('URL server belum diisi');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token.isNotEmpty) ...{
        'Authorization': 'Bearer $token',
        'X-App-Token': token,
      },
    };
    http.Response r;
    try {
      if (body == null) {
        r = await http
            .get(
              _uri(action, {
                ...?query,
                if (username != null) 'username': username,
              }),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));
      } else {
        r = await http
            .post(_uri(action), headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 15));
      }
    } catch (_) {
      throw ApiException('Tidak bisa terhubung ke server');
    }
    if (r.statusCode == 401) {
      throw ApiException('Token salah atau belum diisi (Pengaturan)');
    }
    if (r.statusCode != 200) throw ApiException('HTTP ${r.statusCode}');
    final d = jsonDecode(utf8.decode(r.bodyBytes));
    if (d is Map<String, dynamic>) return d;
    throw ApiException('Respons tidak valid');
  }
}
