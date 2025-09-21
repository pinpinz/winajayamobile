import 'package:dio/dio.dart';

class ApiService {
  static String baseUrl =
      "http://localhost/project-api"; // ganti sesuai path di server (misal http://192.168.1.5/api)
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

  // =========================
  // 🔹 1. API Aktivasi QR
  // =========================
  static Future<Map<String, dynamic>?> scanAktivasi({
    required String flag,
    required String nomor,
    required String qr,
    required String idUser,
  }) async {
    try {
      final response = await _dio.post(
        "/api_scanqr.php",
        data: {
          "flag": flag,
          "nomor": nomor,
          "QR": qr,
          "idUser": idUser,
        },
      );
      if (response.statusCode == 200) return response.data;
      return null;
    } catch (e) {
      print("❌ Error scanAktivasi: $e");
      return null;
    }
  }

  // =========================
  // 🔹 2. API Picking
  // =========================
  static Future<Map<String, dynamic>?> scanPicking({
    required String flag,
    required String nomor,
    required String kodeCust,
    required String sitePlan,
    required String qr,
    required String bobot,
    required String idUser,
  }) async {
    try {
      final response = await _dio.post(
        "/api_scanPicking.php",
        data: {
          "flag": flag,
          "nomor": nomor,
          "kodeCust": kodeCust,
          "sitePlan": sitePlan,
          "QR": qr,
          "bobot": bobot,
          "idUser": idUser,
        },
      );
      if (response.statusCode == 200) return response.data;
      return null;
    } catch (e) {
      print("❌ Error scanPicking: $e");
      return null;
    }
  }

  // =========================
  // 🔹 3. API Jurigen Kembali
  // =========================
  static Future<Map<String, dynamic>?> scanJurigenKembali({
    required String flag,
    required String nomor,
    required String qr,
    required String idUser,
  }) async {
    try {
      final response = await _dio.post(
        "/api_scanJurigenKembali.php",
        data: {
          "flag": flag,
          "nomor": nomor,
          "QR": qr,
          "idUser": idUser,
        },
      );
      if (response.statusCode == 200) return response.data;
      return null;
    } catch (e) {
      print("❌ Error scanJurigenKembali: $e");
      return null;
    }
  }
}
