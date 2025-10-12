import 'package:day35/widget/qrscanner.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:day35/widget/apiservice.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  _ScannerPageState createState() => _ScannerPageState();
}

/// Model customer dari API
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

class _ScannerPageState extends State<ScannerPage> {
  List<Map<String, String>> _elements = [];
  List<_CustomerItem> _customers = [];
  _CustomerItem? _selectedCustomer;

  String? noTransaksi;
  bool _loadingCustomers = false;
  bool _processingScan = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  // ---------- Helpers: robust parsing ----------
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

  String? _extractIdTrans(dynamic res) {
    try {
      if (res is Map) {
        final data = res['data'];
        if (data is Map && data['idTrans'] != null) {
          return data['idTrans'].toString();
        }
        if (data is List && data.isNotEmpty) {
          final first = data.first;
          if (first is Map && first['idTrans'] != null) {
            return first['idTrans'].toString();
          }
        }
        if (res['idTrans'] != null) return res['idTrans'].toString();
      }
    } catch (_) {}
    return null;
  }

  String _extractMessage(dynamic res, {String fallback = 'Gagal simpan'}) {
    try {
      if (res is Map) {
        final m = res['message'];
        if (m != null) return m.toString();
      }
    } catch (_) {}
    return fallback;
  }

  // ---------- Load customers ----------
  Future<void> _loadCustomers() async {
    setState(() => _loadingCustomers = true);
    final result = await ApiService.getCustomer();
    final List<_CustomerItem> parsed = [];
    final seen = <String>{};

    if (result != null &&
        result["status"] == "success" &&
        result["data"] is List) {
      for (final row in (result["data"] as List)) {
        if (row is Map) {
          final kode = (row["kodeCustomer"] ?? '').toString();
          final nama = (row["namaCustomer"] ?? '').toString();
          final site = (row["sitePlan"] ?? '-').toString();
          final id = (row["id"] ?? '').toString();
          if (kode.isEmpty && nama.isEmpty) continue;

          final ci = _CustomerItem(
            id: id,
            kodeCustomer: kode,
            namaCustomer: nama,
            sitePlan: site,
          );

          if (seen.add(ci.dedupKey)) parsed.add(ci);
        }
      }
    } else {
      if (mounted) {
        final msg;
        if ((result is Map && result?["message"] != null)) {
          msg = result != null ? ["message"].toString() : "unknown";
        } else {
          msg = "unknown";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Gagal ambil data customer: $msg")),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _customers = parsed;
      _loadingCustomers = false;
    });
  }

  /// 🔹 Scan QR lalu langsung POST ke API picking
  Future<void> _scanQRCode() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih customer dulu sebelum scan!")),
      );
      return;
    }

    final result =
        await QRScannerHelper.scanQRCode(context, title: 'Scan QR Code');
    if (result == null || result.isEmpty) return;

    final controller = TextEditingController();
    final berat = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Input Berat"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Masukkan berat (Kg)"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text("OK")),
        ],
      ),
    );

    if (berat == null || berat.isEmpty) return;

    setState(() => _processingScan = true);

    try {
      final res = await ApiService.scanPicking(
        flag: "0",
        nomor: noTransaksi ?? "",
        kodeCust: _selectedCustomer!.kodeCustomer,
        sitePlan: _selectedCustomer!.sitePlan,
        qr: result,
        bobot: berat,
        idUser: "1",
      );

      final success = _isSuccess(res);
      final idTrans = _extractIdTrans(res);

      if (success && idTrans != null && idTrans.isNotEmpty) {
        setState(() {
          noTransaksi = idTrans;
          _elements.add({
            "name": result ?? '', // pastikan String non-null
            "berat": "$berat Kg",
            "status": "Tersimpan",
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ QR tersimpan. ID Transaksi: $idTrans")),
        );
      } else {
        final msg = _extractMessage(res);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Gagal simpan QR: $msg")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error kirim ke server: $e")),
      );
    } finally {
      if (mounted) setState(() => _processingScan = false);
    }
  }

  Widget _createGroupedListView() {
    if (_elements.isEmpty) {
      return const Center(
        child:
            Text("Belum ada hasil scan.", style: TextStyle(color: Colors.grey)),
      );
    }

    return GroupedListView<dynamic, String>(
      elements: _elements,
      groupBy: (e) => e['status'] ?? '',
      order: GroupedListOrder.DESC,
      groupSeparatorBuilder: (value) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          value,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
        ),
      ),
      itemBuilder: (context, element) => ListTile(
        leading: const Icon(Icons.qr_code_2),
        title: Text(element['name'] ?? ''),
        subtitle: Text("Berat: ${element['berat']}"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Scan Picking", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadingCustomers ? null : _loadCustomers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text("No Transaksi",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.greenAccent,
            child: Text(
              noTransaksi ?? "- Belum ada -",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
          const SizedBox(height: 10),
          const Text("Nama Customer",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: _loadingCustomers
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<_CustomerItem>(
                    hint: const Text("Pilih Customer"),
                    value: _selectedCustomer,
                    isExpanded: true,
                    items: _customers
                        .map((e) => DropdownMenuItem<_CustomerItem>(
                              value: e,
                              child: Text(e.label,
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCustomer = v),
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                  ),
          ),
          Expanded(child: _createGroupedListView()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _processingScan ? null : _scanQRCode,
        backgroundColor: _processingScan ? Colors.grey : Colors.teal,
        label: const Text("Scan QR"),
        icon: _processingScan
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
