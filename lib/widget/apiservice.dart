import 'package:dio/dio.dart';

class ApiService {
  static String baseUrl = "http://localhost:3000"; // default
  static Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {"Content-Type": "application/json"},
  ));

  /// Ganti baseUrl secara global
  static void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ));
    print("✅ Base URL diganti ke: $baseUrl");
  }

  static Future<Map<String, dynamic>?> checkQR(String qr) async {
    try {
      final response = await _dio.post(
        "/check-qr",
        data: {"qr": qr},
      );
      if (response.statusCode == 200) return response.data;
      return null;
    } catch (e) {
      print("Error checkQR: $e");
      return null;
    }
  }

  static Future<bool> saveTransaction(String noTransaksi, String customer,
      List<Map<String, String>> items) async {
    try {
      final response = await _dio.post(
        "/save-transaction",
        data: {
          "no_transaksi": noTransaksi,
          "customer": customer,
          "items": items,
        },
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print("Error saveTransaction: $e");
      return false;
    }
  }
}
