import 'package:animate_do/animate_do.dart';
import 'package:day35/models/service.dart';
import 'package:day35/pages/module/AktivasiBarang.dart';
import 'package:day35/pages/module/HistoryBarang.dart';
import 'package:day35/pages/module/LabelBarang.dart';
import 'package:day35/pages/module/ScanBarang.dart';
// ✅ hanya pakai ApiService dari sini
import 'package:day35/widget/apiservice.dart' as api;
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Service> services = [
    Service('Picking', 'assets/icons/scan.png'),
    Service('Aktivasi', 'assets/icons/active.png'),
    Service('History', 'assets/icons/file.png'),
    Service('Jerigen Kembali', 'assets/icons/label.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'dashboard',
          style: TextStyle(color: Colors.black),
        ),
        elevation: 0,
        actions: [
          // 🔹 Tombol ganti IP
          IconButton(
            onPressed: () async {
              final controller =
                  TextEditingController(text: api.ApiService.baseUrl);
              final newIp = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Ganti IP Server"),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "contoh: http://192.168.1.10:3000",
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Batal"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, controller.text),
                      child: const Text("Simpan"),
                    ),
                  ],
                ),
              );

              if (newIp != null && newIp.isNotEmpty) {
                setState(() {
                  api.ApiService.updateBaseUrl(newIp);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Base URL diubah ke: $newIp")),
                );
              }
            },
            icon: Icon(
              Icons.settings,
              color: Colors.grey.shade700,
              size: 30,
            ),
          ),

          // 🔹 Tombol logout
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            icon: Icon(
              Icons.logout,
              color: Colors.grey.shade700,
              size: 30,
            ),
          )
        ],
        leading: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/login');
          },
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
                  FadeInUp(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              offset: const Offset(0, 4),
                              blurRadius: 10.0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15.0),
                              child: Image.asset(
                                'assets/icons/profile.png',
                                height:
                                    MediaQuery.of(context).size.height * 0.1,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  "Guest",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Staff Gudang",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                      ),
                      itemCount: services.length,
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                          onTap: () {
                            if (services[index].name == 'Picking') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ScannerPage()),
                              );
                            } else if (services[index].name == 'Aktivasi') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AktivasiPage()),
                              );
                            } else if (services[index].name == 'History') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HistoryPage()),
                              );
                            } else if (services[index].name ==
                                'Jerigen Kembali') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ReturPage()),
                              );
                            }
                          },
                          child: FadeInUp(
                            delay: Duration(milliseconds: 500 * index),
                            child: serviceContainer(
                              services[index].imageURL,
                              services[index].name,
                              index,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: true,
            top: false,
            child: Container(
              color: Colors.blueGrey,
              height: 50,
              width: double.infinity,
              child: const Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    "© 2025 Arkav - All Rights Reserved",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget serviceContainer(String image, String name, int index) {
    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(
            color: Colors.blue.withOpacity(0),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(image, height: 45, fit: BoxFit.contain),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(fontSize: 17),
            )
          ],
        ),
      ),
    );
  }
}
