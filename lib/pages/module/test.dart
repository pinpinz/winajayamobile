// lib/test.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:day35/widget/apiservice.dart' as api; // pastikan path benar

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Scan Picking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const TestScanPage(),
    );
  }
}

class TestScanPage extends StatefulWidget {
  const TestScanPage({Key? key}) : super(key: key);
  @override
  State<TestScanPage> createState() => _TestScanPageState();
}

/// Model ringan dropdown customer
class _CustomerItem {
  final String id;
  final String kodeCustomer;
  final String namaCustomer;
  final String sitePlan;

  _CustomerItem({
    required this.id,
    required this.kodeCustomer,
    required this.namaCustomer,
    required this.sitePlan,
  });

  String get label {
    final sp = sitePlan.trim();
    final withSite =
        (sp.isEmpty || sp == '-' || sp.toLowerCase() == 'null') ? '' : ' • $sp';
    return '$kodeCustomer — $namaCustomer$withSite';
  }

  String get dedupKey => '${kodeCustomer}__${sitePlan.trim()}';
}

class _TestScanPageState extends State<TestScanPage> {
  // Hasil scan yang ditampilkan di layar
  final List<Map<String, String>> _elements = [];

  // Customer dari API
  List<_CustomerItem> _customers = [];
  _CustomerItem? _selectedCustomer;

  // No transaksi dari server
  String? _noTransaksi;

  bool _loadingCustomers = false;
  bool _processingScan = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  // -------------------- Helpers robust untuk respons API --------------------
  String? _extractIdTransFromResponse(dynamic res) {
    try {
      if (res is Map) {
        final data = res['data'];
        // Kontrak baru: { status, data:{idTrans}, message }
        if (data is Map && data['idTrans'] != null) {
          return data['idTrans'].toString();
        }
        // Kontrak lama: { status, data:[{idTrans:...}], ... }
        if (data is List && data.isNotEmpty) {
          final first = data.first;
          if (first is Map && first['idTrans'] != null) {
            return first['idTrans'].toString();
          }
        }
        // Kadang langsung di root
        if (res['idTrans'] != null) return res['idTrans'].toString();
      }
    } catch (_) {}
    return null;
  }

  bool _isSuccess(dynamic res) {
    try {
      if (res is Map) {
        final s = res['status']?.toString().toLowerCase();
        final m = res['message']?.toString().toLowerCase();
        return s == 'success' || s == 'sukses' || m == 'sukses';
      }
    } catch (_) {}
    return false;
  }

  // ====================== LOAD CUSTOMER DARI API ======================
  Future<void> _loadCustomers() async {
    setState(() => _loadingCustomers = true);

    final result = await api.ApiService.getCustomer();
    final List<_CustomerItem> parsed = [];
    final seen = <String>{};

    if (result != null &&
        result["status"] == "success" &&
        result["data"] is List) {
      for (final row in (result["data"] as List)) {
        if (row is Map) {
          final id = (row["id"] ?? '').toString();
          final kode = (row["kodeCustomer"] ?? '').toString();
          final nama = (row["namaCustomer"] ?? '').toString();
          final site = (row["sitePlan"] ?? '-').toString();
          if (kode.isEmpty && nama.isEmpty) continue;

          final item = _CustomerItem(
            id: id,
            kodeCustomer: kode,
            namaCustomer: nama,
            sitePlan: site,
          );
          if (seen.add(item.dedupKey)) parsed.add(item);
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "❌ Gagal ambil customer: ${result?['message'] ?? 'unknown'}"),
        ));
      }
    }

    if (!mounted) return;
    setState(() {
      _customers = parsed;
      _loadingCustomers = false;
      if (_selectedCustomer != null &&
          !_customers.any((c) => c.dedupKey == _selectedCustomer!.dedupKey)) {
        _selectedCustomer = null;
      }
    });
  }

  // ====================== SCAN + KIRIM KE API ======================
  Future<void> _scanQRCode() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih customer dulu sebelum scan!')),
      );
      return;
    }

    String? result;

    if (kDebugMode) {
      // DEV MODE: input manual
      final controller = TextEditingController();
      result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Masukkan QR (DEV)'),
          content: TextField(
            controller: controller,
            decoration:
                const InputDecoration(hintText: 'Tempel/paste kode QR di sini'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: const Text('OK')),
          ],
        ),
      );
    } else {
      // PRODUKSI: ganti ke scanner kamera kamu
      // result = await QRScannerHelper.scanQRCode(context, title: 'Scan QR Code');
      result = null;
    }

    if (result == null || result.isEmpty) return;

    // input berat
    final beratCtl = TextEditingController();
    final berat = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Input Berat"),
        content: TextField(
          controller: beratCtl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Masukkan berat (Kg)"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, beratCtl.text),
              child: const Text("OK")),
        ],
      ),
    );

    if (berat == null || berat.isEmpty) return;

    setState(() => _processingScan = true);

    try {
      final res = await api.ApiService.scanPicking(
        flag: "0",
        nomor: _noTransaksi ?? "", // kosongkan saat transaksi baru
        kodeCust: _selectedCustomer!.kodeCustomer,
        sitePlan: _selectedCustomer!.sitePlan,
        qr: result,
        bobot: berat,
        idUser: "1", // TODO: ganti dengan id user login
      );

      // gunakan helper robust
      final success = _isSuccess(res);
      final idTrans = _extractIdTransFromResponse(res);

      if (success && idTrans != null && idTrans.isNotEmpty) {
        setState(() {
          _noTransaksi = idTrans;
          _elements.add({
            "name": result ?? '', // pastikan String non-null
            "berat": "$berat Kg",
            "status": "Tersimpan",
          });
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Tersimpan. ID Transaksi: $idTrans")),
          );
        }
      } else {
        String msg = "Gagal simpan";
        if (res is Map) {
          final m = ["message"];
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("⚠️ $msg")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error kirim ke server: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _processingScan = false);
    }
  }

  // ====================== UI ======================
  @override
  Widget build(BuildContext context) {
    final empty = _elements.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Test Scan Picking"),
        actions: [
          IconButton(
            tooltip: 'Refresh Customer',
            onPressed: _loadingCustomers ? null : _loadCustomers,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Reset List',
            onPressed: empty
                ? null
                : () => setState(() {
                      _elements.clear();
                    }),
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Info mode
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    kDebugMode
                        ? 'Mode DEV: input QR manual'
                        : 'Mode PROD: hubungkan ke scanner kamera',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),

          // No Transaksi dari server
          const Text("No Transaksi",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _noTransaksi ?? "- Belum ada -",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),

          // Dropdown customer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: _loadingCustomers
                ? const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator()))
                : DropdownButtonFormField<_CustomerItem>(
                    isExpanded: true,
                    value: _selectedCustomer,
                    hint: const Text("Pilih Customer"),
                    items: _customers
                        .map((c) => DropdownMenuItem<_CustomerItem>(
                              value: c,
                              child: Text(
                                c.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCustomer = v),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
          ),

          const Divider(height: 0),

          // List hasil scan
          Expanded(
            child: empty
                ? const Center(
                    child: Text(
                      "Belum ada data.\nTekan tombol Scan di kanan bawah.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _elements.length,
                    itemBuilder: (context, index) {
                      final item = _elements[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.qr_code_2),
                          title: Text(item['name'] ?? ''),
                          subtitle: Text(
                              "Berat: ${item['berat']} | ${item['status']}"),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Tombol Scan
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _processingScan ? null : _scanQRCode,
        backgroundColor: _processingScan ? Colors.grey : Colors.teal,
        icon: _processingScan
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.qr_code_scanner),
        label: const Text("Scan / Input"),
      ),
    );
  }
}
