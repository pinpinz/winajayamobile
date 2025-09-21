import 'package:animate_do/animate_do.dart';
import 'package:day35/pages/home.dart';
import 'package:day35/widget/qrscanner.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:day35/widget/apiservice.dart';

class ReturPage extends StatefulWidget {
  const ReturPage({Key? key}) : super(key: key);

  @override
  _ReturPageState createState() => _ReturPageState();
}

class _ReturPageState extends State<ReturPage> {
  List<Map<String, String>> _jerigenList = [];

  /// Widget untuk menampilkan data jerigen
  Widget _createGroupedListView() {
    if (_jerigenList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "Belum ada jerigen.\nSilakan scan QR Code.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GroupedListView<dynamic, String>(
      elements: _jerigenList,
      groupBy: (element) => "Jerigen",
      order: GroupedListOrder.ASC,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      groupSeparatorBuilder: (String value) => const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          "Data Jerigen",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      itemBuilder: (c, element) {
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            title: Text(
              "QR: ${element['qr'] ?? '-'}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Transaksi: ${element['idTrans'] ?? '-'}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            leading: const Icon(Icons.local_drink, color: Colors.blueAccent),
          ),
        );
      },
    );
  }

  /// Fungsi untuk scan QR dan langsung simpan via API
  Future<void> _scanQRCode() async {
    final result = await QRScannerHelper.scanQRCode(
      context,
      title: 'Scan QR Code Jerigen',
    );

    if (result != null) {
      final response = await ApiService.scanJurigenKembali(
        flag: "0", // 0 = insert baru
        nomor: "", // kosong → biar SP generate otomatis
        qr: result,
        idUser: "U001", // TODO: ganti dengan user login
      );

      if (response != null && response["status"] == "success") {
        final data = response["data"][0]; // ambil hasil SP

        setState(() {
          _jerigenList.add({
            "qr": result,
            "idTrans": data["idTrans"] ?? "",
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Jerigen berhasil diretur"),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              response?["data"]?[0]?["status"] ?? "QR tidak valid di sistem"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  /// Konfirmasi (tidak perlu simpan ulang, karena SP sudah langsung insert)
  Future<void> _confirmData() async {
    if (_jerigenList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Belum ada data untuk disimpan"),
      ));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Data retur jerigen sudah tersimpan di server"),
      backgroundColor: Colors.green,
    ));

    setState(() => _jerigenList.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Retur Jerigen',
          style: TextStyle(color: Colors.black),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            icon: Icon(
              Icons.logout,
              color: Colors.grey.shade700,
              size: 30,
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  FadeInUp(
                    child: const SizedBox(height: 10),
                  ),
                  _createGroupedListView(),
                ],
              ),
            ),
          ),

          /// Footer dengan tombol aksi
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _scanQRCode,
                    child: Container(
                      height: 55,
                      color: Colors.blueGrey,
                      child: const Center(
                        child: Icon(
                          Icons.photo_camera_outlined,
                          size: 30,
                          color: Colors.white,
                        ),
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
                        child: Icon(
                          Icons.check_circle,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
