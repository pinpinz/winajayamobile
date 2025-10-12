import 'package:dio/dio.dart';

class ApiService {
  static String baseUrl = "http://hg309xdcrrq.sn.mynetname.net:1414/wn";
  static Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {"Content-Type": "application/json"},
  ));

  /// ===== baseUrl switcher =====
  static void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ));
    // ignore: avoid_print
    print("Base URL diganti ke: $baseUrl");
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
      // ignore: avoid_print
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
      // ignore: avoid_print
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
      // ignore: avoid_print
      print("❌ Error scanJurigenKembali: $e");
      return null;
    }
  }

  // =========================
  // 🔹 0. API Login
  // =========================
  static Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "/login.php",
        data: {"username": username, "password": password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data["status"] == "success" && data["user"] != null) {
          final namaPegawai = data["user"]["namaPegawai"];
          final levelUser = data["user"]["levelUser"];

          // ignore: avoid_print
          print("✅ Nama Pegawai: $namaPegawai");
          // ignore: avoid_print
          print("✅ Level User  : $levelUser");

          return {
            "status": "success",
            "namaPegawai": namaPegawai,
            "levelUser": levelUser,
            "raw": data,
          };
        } else {
          return {
            "status": "error",
            "message": data["message"] ?? "Login gagal",
            "raw": data,
          };
        }
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error login: $e");
      return {"status": "error", "message": e.toString()};
    }
  }

  // ============================================================================
  // 🔹 4. API Get Customer (RAW) — tetap tersedia untuk kompatibilitas
  //    (mengembalikan response asli dari server /customer.php)
  // ============================================================================
  static Future<Map<String, dynamic>?> getCustomer() async {
    try {
      final response = await _dio.get("/api_getCustomer.php");
      if (response.statusCode == 200) {
        return response.data; // {status: success, data: [ ... ] }
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error getCustomer: $e");
      return {"status": "error", "message": e.toString()};
    }
  }

  // ============================================================================
  // 🔹 4b. Customer model + helper yang lebih ergonomis
  //    - parse JSON → List<Customer>
  //    - dedup (kodeCustomer + sitePlan)
  //    - cache 60 detik (bisa forceRefresh)
  //    - search & site grouping
  // ============================================================================

  // Cache ringan di memori
  static List<Customer>? _customerCache;
  static DateTime? _customerCacheAt;
  static const Duration _customerTtl = Duration(seconds: 60);

  /// Ambil daftar Customer terparse & dedup.
  static Future<List<Customer>> fetchCustomers(
      {bool forceRefresh = false}) async {
    // gunakan cache jika masih fresh
    final now = DateTime.now();
    if (!forceRefresh &&
        _customerCache != null &&
        _customerCacheAt != null &&
        now.difference(_customerCacheAt!).compareTo(_customerTtl) < 0) {
      return _customerCache!;
    }

    final raw = await getCustomer();
    final List<Customer> out = [];

    if (raw != null && raw['status'] == 'success' && raw['data'] is List) {
      final List data = raw['data'];
      final seen = <String>{}; // dedup key: kodeCustomer + sitePlan
      for (final item in data) {
        if (item is Map) {
          final c = Customer.fromJson(item);
          if (c.kodeCustomer.isEmpty && c.namaCustomer.isEmpty) continue;

          final key = '${c.kodeCustomer}__${c.sitePlan.trim()}';
          if (seen.add(key)) out.add(c);
        }
      }
    }

    _customerCache = out;
    _customerCacheAt = DateTime.now();
    return out;
  }

  /// Cari customers mengandung kata pada kode/nama/sitePlan (case-insensitive)
  static Future<List<Customer>> searchCustomers(String query,
      {bool forceRefresh = false}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return fetchCustomers(forceRefresh: forceRefresh);
    final list = await fetchCustomers(forceRefresh: forceRefresh);
    return list.where((c) {
      return c.kodeCustomer.toLowerCase().contains(q) ||
          c.namaCustomer.toLowerCase().contains(q) ||
          c.sitePlan.toLowerCase().contains(q);
    }).toList();
  }

  /// Ambil daftar sitePlan unik untuk 1 kodeCustomer
  static Future<List<String>> getSitesByKode(String kodeCustomer,
      {bool forceRefresh = false}) async {
    final list = await fetchCustomers(forceRefresh: forceRefresh);
    final sites = list
        .where((c) => c.kodeCustomer == kodeCustomer)
        .map((c) => c.sitePlan.trim())
        .where((sp) => sp.isNotEmpty && sp != '-')
        .toSet()
        .toList()
      ..sort();
    return sites;
  }
}

/// ==============================
/// Customer Model
/// ==============================
class Customer {
  final String id;
  final String kodeCustomer;
  final String namaCustomer;
  final String hp;
  final String email;
  final String nik;
  final String npwp;
  final String alamat;
  final String isAktif;
  final String tglCreate;
  final String userCreate;
  final String? tglNonAktif;
  final String? userNonAktif;
  final String? alasanNonAktif;
  final String type;
  final String sitePlan;

  Customer({
    required this.id,
    required this.kodeCustomer,
    required this.namaCustomer,
    required this.hp,
    required this.email,
    required this.nik,
    required this.npwp,
    required this.alamat,
    required this.isAktif,
    required this.tglCreate,
    required this.userCreate,
    required this.tglNonAktif,
    required this.userNonAktif,
    required this.alasanNonAktif,
    required this.type,
    required this.sitePlan,
  });

  factory Customer.fromJson(Map json) {
    String _s(dynamic v) => (v ?? '').toString();

    return Customer(
      id: _s(json['id']),
      kodeCustomer: _s(json['kodeCustomer']),
      namaCustomer: _s(json['namaCustomer']),
      hp: _s(json['hp']),
      email: _s(json['email']),
      nik: _s(json['nik']),
      npwp: _s(json['npwp']),
      alamat: _s(json['alamat']),
      isAktif: _s(json['isAktif']),
      tglCreate: _s(json['tglCreate']),
      userCreate: _s(json['userCreate']),
      tglNonAktif: json['tglNonAktif']?.toString(),
      userNonAktif: json['userNonAktif']?.toString(),
      alasanNonAktif: json['alasanNonAktif']?.toString(),
      type: _s(json['type']),
      sitePlan: _s(json['sitePlan']),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "kodeCustomer": kodeCustomer,
        "namaCustomer": namaCustomer,
        "hp": hp,
        "email": email,
        "nik": nik,
        "npwp": npwp,
        "alamat": alamat,
        "isAktif": isAktif,
        "tglCreate": tglCreate,
        "userCreate": userCreate,
        "tglNonAktif": tglNonAktif,
        "userNonAktif": userNonAktif,
        "alasanNonAktif": alasanNonAktif,
        "type": type,
        "sitePlan": sitePlan,
      };

  /// Label ringkas untuk dropdown
  String get label {
    final sp = sitePlan.trim();
    final spShown =
        (sp.isEmpty || sp == '-' || sp.toLowerCase() == 'null') ? '' : ' • $sp';
    return '$kodeCustomer — $namaCustomer$spShown';
  }
}
