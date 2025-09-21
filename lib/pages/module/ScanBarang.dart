import 'package:day35/pages/home.dart';
import 'package:day35/widget/qrscanner.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:day35/widget/apiservice.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  List<Map<String, String>> _elements = []; // kosong awal
  String? selectedValue;
  String? noTransaksi;

  final List<String> customers = ['PT. ABC', 'PT. DEF', 'PT. GHI'];

  Widget _createGroupedListView() {
    if (_elements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
            SizedBox(height: 10),
            Text("Belum ada barang.\nSilakan scan QR Code.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return GroupedListView<dynamic, String>(
      elements: _elements,
      groupBy: (element) => element['status'] ?? '',
      groupComparator: (value1, value2) => value2.compareTo(value1),
      itemComparator: (item1, item2) =>
          (item1['name'] ?? '').compareTo(item2['name'] ?? ''),
      order: GroupedListOrder.DESC,
      useStickyGroupSeparators: true,
      groupSeparatorBuilder: (String value) => const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'Nama Barang',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      itemBuilder: (c, element) {
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: ListTile(
            title: Text(
              element['name'] ?? 'No Name',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Status: ${element['status']}"),
            trailing: Text(element['berat'] ?? '0 Kg',
                style: const TextStyle(fontSize: 16)),
            onTap: () async {
              // Edit berat
              final controller = TextEditingController(
                  text: element['berat']?.replaceAll(" Kg", ""));
              final beratBaru = await showDialog<String>(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: const Text("Edit Berat"),
                    content: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: "Masukkan berat (Kg)",
                      ),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Batal")),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, controller.text),
                          child: const Text("Simpan")),
                    ],
                  );
                },
              );

              if (beratBaru != null && beratBaru.isNotEmpty) {
                setState(() {
                  element['berat'] = "$beratBaru Kg";
                });
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _scanQRCode() async {
    final result = await QRScannerHelper.scanQRCode(
      context,
      title: 'Scan QR Code',
    );

    if (result != null) {
      // 🔒 sementara API check dimatikan untuk uji coba bebas
      /*
    final response = await ApiService.checkQR(result);
    if (response != null && response['success'] == true) {
      if (noTransaksi == null) {
        setState(() {
          noTransaksi = response['no_transaksi'];
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("QR Code tidak valid di sistem!")),
      );
      return;
    }
    */

      // 👉 langsung input berat manual tanpa cek API
      final controller = TextEditingController();
      final berat = await showDialog<String>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Input Berat"),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Masukkan berat (Kg)",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );

      if (berat != null && berat.isNotEmpty) {
        setState(() {
          _elements.add({
            "name": result,
            "berat": "$berat Kg",
            "status": "Offline",
          });
        });
      }
    }
  }

  Future<void> _confirmData() async {
    if (selectedValue == null || _elements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Lengkapi data sebelum simpan!"),
      ));
      return;
    }

    bool allSuccess = true;

    for (var item in _elements) {
      final res = await ApiService.scanPicking(
        flag: "0",
        nomor: noTransaksi ?? "", // kalau null, kirim kosong biar SP generate
        kodeCust: selectedValue!, // dari dropdown
        sitePlan: "SP001", // sementara hardcode, nanti bisa pilih dari UI
        qr: item["name"] ?? "",
        bobot: (item["berat"] ?? "0").replaceAll(" Kg", ""),
        idUser: "U001", // sementara hardcode
      );

      if (res != null && res["status"] == "success") {
        setState(() {
          noTransaksi = res["data"][0]["idTrans"]; // simpan nomor transaksi
        });
      } else {
        allSuccess = false;
      }
    }

    if (allSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Data berhasil disimpan!"),
        backgroundColor: Colors.green,
      ));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Sebagian data gagal disimpan!"),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Scanner Page", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text("No Transaksi",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(vertical: 5),
            color: Colors.greenAccent,
            child: Text(
              noTransaksi ?? "- Belum ada -",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
          const Text("Nama Customer",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              hint: const Text("Pilih Customer"),
              value: selectedValue,
              isExpanded: true,
              items: customers.map((e) {
                return DropdownMenuItem<String>(value: e, child: Text(e));
              }).toList(),
              onChanged: (val) => setState(() => selectedValue = val),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _createGroupedListView()),
        ],
      ),
      // ✅ Tombol dipindah ke bottomNavigationBar agar aman di Android
      bottomNavigationBar: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _scanQRCode,
                child: Container(
                  height: 55,
                  color: Colors.blueGrey,
                  child: const Center(
                    child: Icon(Icons.qr_code_scanner,
                        size: 30, color: Colors.white),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: _confirmData,
                child: Container(
                  height: 55,
                  color: Colors.teal,
                  child: const Center(
                    child:
                        Icon(Icons.check_circle, size: 30, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
