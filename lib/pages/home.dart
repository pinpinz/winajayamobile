import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// PAGE: Login
import 'package:day35/pages/loginform.dart';

// PAGE: Test (sesuaikan lokasi — ini mengacu ke lib/test.dart)
import 'package:day35/pages/module/test.dart';

// MODEL
import 'package:day35/models/service.dart';

// MODULE PAGES
import 'package:day35/pages/module/AktivasiBarang.dart'; // -> AktivasiPage
import 'package:day35/pages/module/HistoryBarang.dart'; // -> HistoryPage
import 'package:day35/pages/module/ScanBarang.dart'; // -> ScannerPage
import 'package:day35/pages/module/LabelBarang.dart'; // -> ReturPage

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String namaPegawai = "Guest";
  String levelUser = "Staff Gudang";

  final List<Service> services = [
    Service('Picking', 'assets/icons/scan.png'),
    Service('Aktivasi', 'assets/icons/active.png'),
    Service('History', 'assets/icons/file.png'),
    Service('Jerigen Kembali', 'assets/icons/label.png'),
    Service('TEST', 'assets/icons/label.png'),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      namaPegawai = prefs.getString("namaPegawai") ?? "Guest";
      levelUser = prefs.getString("levelUser") ?? "Staff Gudang";
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _goToService(String name) {
    if (name == 'Picking') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ScannerPage()));
    } else if (name == 'Aktivasi') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AktivasiPage()));
    } else if (name == 'History') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const HistoryPage()));
    } else if (name == 'Jerigen Kembali') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ReturPage()));
    } else if (name == 'TEST') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const TestScanPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Dashboard', style: TextStyle(color: Colors.black)),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: Icon(Icons.logout, color: Colors.grey.shade700, size: 30),
          ),
        ],
        leading: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/login'),
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

                  // Kartu profil
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
                              children: [
                                Text(
                                  namaPegawai,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  levelUser,
                                  style: const TextStyle(
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

                  // Title categories
                  FadeInUp(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Categories',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                  // Grid menu
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
                        final svc = services[index];
                        return GestureDetector(
                          onTap: () => _goToService(svc.name),
                          child: FadeInUp(
                            delay: Duration(milliseconds: 120 * index),
                            child:
                                serviceContainer(svc.imageURL, svc.name, index),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer
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
          ),
        ],
      ),
    );
  }

  Widget serviceContainer(String image, String name, int index) {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.blue.withOpacity(0), width: 2.0),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset(image, height: 45, fit: BoxFit.contain),
          const SizedBox(height: 20),
          Text(name, style: const TextStyle(fontSize: 17)),
        ],
      ),
    );
  }
}
