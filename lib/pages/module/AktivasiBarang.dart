import 'package:animate_do/animate_do.dart';
import 'package:day35/pages/home.dart';
import 'package:day35/widget/popup.dart';
import 'package:day35/widget/qrscanner.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';

class AktivasiPage extends StatefulWidget {
  const AktivasiPage({Key? key}) : super(key: key);

  @override
  _AktivasiPageState createState() => _AktivasiPageState();
}

class _AktivasiPageState extends State<AktivasiPage> {
  // List kosong (akan terisi setelah scan QR)
  List<Map<String, String>> _elements = [];

  // Tambah item hasil scan (tanpa check API)
  void _addScannedItem(String qrResult) {
    setState(() {
      _elements.add({
        'name': qrResult,
        'status': 'Available',
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            title: Text(
              element['name'] ?? 'No Name',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // cegah tombol back Android menutup Confirm/Cancel
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
            'Aktivasi Page',
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

            /// Footer tetap di bawah
            SafeArea(
              child: Row(
                children: [
                  /// Tombol Scan QR
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final result = await QRScannerHelper.scanQRCode(
                          context,
                          title: 'Scan QR Code',
                        );

                        if (result != null) {
                          _addScannedItem(result); // ✅ masuk list
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('QR Code: $result'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
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

                  /// Tombol Confirm / Cancel
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        showAnimatedBottomSheet(
                          context: context,
                          title: "Apakah anda yakin?",
                          options: [
                            {
                              'label': 'Confirm',
                              'icon': const Icon(Icons.checklist,
                                  color: Colors.green),
                              'onTap': (sheetContext) async {
                                Navigator.of(sheetContext).pop();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const HomePage()),
                                );
                              },
                            },
                            {
                              'label': 'Cancel',
                              'icon':
                                  const Icon(Icons.cancel, color: Colors.red),
                              'onTap': (sheetContext) {
                                Navigator.of(sheetContext).pop();
                              },
                            },
                          ],
                        );
                      },
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
