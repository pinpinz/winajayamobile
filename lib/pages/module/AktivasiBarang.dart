import 'package:animate_do/animate_do.dart';
import 'package:day35/pages/home.dart';
import 'package:day35/widget/popup.dart';
import 'package:day35/widget/qrscanner.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:day35/widget/apiservice.dart';

class AktivasiPage extends StatefulWidget {
  const AktivasiPage({Key? key}) : super(key: key);

  @override
  _AktivasiPageState createState() => _AktivasiPageState();
}

class _AktivasiPageState extends State<AktivasiPage> {
  /// List hasil scan
  List<Map<String, String>> _elements = [];

  /// Tambah item hasil scan
  void _addScannedItem(String qrResult, String status, String idTrans) {
    setState(() {
      _elements.add({
        'name': qrResult,
        'status': status,
        'idTrans': idTrans,
      });
    });
  }

  /// Widget grouped list
  Widget _createGroupedListView() {
    if (_elements.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            "Belum ada data.\nSilakan scan QR Code.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      groupSeparatorBuilder: (String value) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              element['name'] ?? 'No Name',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Transaksi: ${element['idTrans'] ?? '-'}"),
            leading: const Icon(
              Icons.add_box_sharp,
              color: Colors.redAccent,
            ),
            trailing: Text(element['status'] ?? ''),
          ),
        );
      },
    );
  }

  /// Scan QR dan panggil API Aktivasi
  Future<void> _scanQRCode() async {
    final result = await QRScannerHelper.scanQRCode(
      context,
      title: 'Scan QR Code',
    );

    if (result != null) {
      final response = await ApiService.scanAktivasi(
        flag: "0",
        nomor: "",
        qr: result,
        idUser: "1",
      );

      if (response != null && response["status"] == "success") {
        final data = response["data"][0];
        _addScannedItem(
          result,
          data["status"] ?? "Aktif",
          data["idTrans"] ?? "-",
        );

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("QR berhasil diaktivasi: ${data["idTrans"]}"),
          backgroundColor: Colors.green,
        ));
      } else {
        // 🔥 tampilkan error lebih detail
        final errorMessage = response?["message"] ??
            response?["data"]?[0]?["status"] ??
            "QR Code tidak valid di sistem";

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // Confirm data (sudah tersimpan di server via SP)
  Future<void> _confirmData() async {
    if (_elements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Belum ada data yang diaktivasi"),
      ));
      return;
    }

    showAnimatedBottomSheet(
      context: context,
      title: "Apakah anda yakin?",
      options: [
        {
          'label': 'Confirm',
          'icon': const Icon(Icons.checklist, color: Colors.green),
          'onTap': (sheetContext) async {
            Navigator.of(sheetContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Data aktivasi sudah tersimpan di server"),
              backgroundColor: Colors.green,
            ));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        },
        {
          'label': 'Cancel',
          'icon': const Icon(Icons.cancel, color: Colors.red),
          'onTap': (sheetContext) {
            Navigator.of(sheetContext).pop();
          },
        },
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Keluar Halaman?"),
            content:
                const Text("Apakah Anda yakin ingin keluar dari halaman ini?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text("Ya"),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Aktivasi Barang',
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
          leading: GestureDetector(
            onTap: () {},
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/icons/profile.png'),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    FadeInUp(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 20.0, top: 10.0, right: 10.0),
                      ),
                    ),
                    _createGroupedListView(),
                  ],
                ),
              ),
            ),

            /// Footer
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
      ),
    );
  }
}
