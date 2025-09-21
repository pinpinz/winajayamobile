import 'package:animate_do/animate_do.dart';
import 'package:day35/pages/home.dart';
import 'package:day35/widget/qrscanner.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

final List<Map<String, String>> _elements = [
  {
    'name': 'Lem 5721',
    'berat': '110 Kg',
    'description': 'Cetak Sticker',
    'date': '12-08-2025'
  },
  {
    'name': 'Lem 5721',
    'berat': '120 Kg',
    'description': 'Scan aktivasi oleh Kevin',
    'date': '12-08-2025'
  },
  {
    'name': 'Lem 5721',
    'berat': '220 Kg',
    'description': 'Input timbangan oleh Dhany',
    'date': '21-08-2025'
  },
  {
    'name': 'Lem 5721',
    'berat': '120 Kg',
    'description': 'Barang Terkirim pada DO10212',
    'date': '25-08-2025'
  },
];

Widget _createGroupedListView() {
  return GroupedListView<dynamic, String>(
    elements: _elements,
    groupBy: (element) => element['name'] ?? '',
    groupComparator: (value1, value2) => value2.compareTo(value1),
    itemComparator: (item1, item2) =>
        (item1['date'] ?? '').compareTo(item2['date'] ?? ''),
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
            element['description'] ?? 'No description',
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Text(
            'Berat: ${element['berat'] ?? '-'}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: Text(
            element['date'] ?? 'No date',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      );
    },
  );
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'History Page',
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

          /// Footer scan button
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final result = await QRScannerHelper.scanQRCode(
                        context,
                        title: 'Scan QR Code',
                      );

                      if (result != null && mounted) {
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
              ],
            ),
          )
        ],
      ),
    );
  }
}
