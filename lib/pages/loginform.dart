import 'package:day35/widget/apiservice.dart';
import 'package:day35/widget/apiservice.dart' as api;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'package:day35/animation/FadeAnimation.dart';
import 'package:lottie/lottie.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// 🔹 Popup Loading dengan Lottie
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/animation/loginanimation.json',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Sedang masuk...",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔹 Fungsi login via API
  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Username dan Password harus diisi!"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    _showLoadingDialog();

    final result =
        await ApiService.login(username: username, password: password);

    Navigator.of(context, rootNavigator: true).pop(); // tutup loading dialog

    if (result != null && result["raw"] != null) {
      final raw = result["raw"];
      final message = raw["message"];

      if (message == "Login berhasil") {
        final user = raw["user"];
        final namaPegawai = user["namaPegawai"];
        final levelUser = user["levelUser"];

        // simpan ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("userId", user["idUser"]);
        await prefs.setString("username", user["username"]);
        await prefs.setString("namaPegawai", namaPegawai);
        await prefs.setString("levelUser", levelUser);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Selamat datang $namaPegawai ($levelUser)"),
          backgroundColor: Colors.green,
        ));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message ?? "Login gagal"),
          backgroundColor: Colors.red,
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Terjadi kesalahan koneksi ke server"),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),

              /// Judul
              FadeAnimation(
                1,
                const Text(
                  "Selamat Datang",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              FadeAnimation(
                1.2,
                const Text(
                  "Silakan login untuk melanjutkan",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 40),

              /// Input Username
              FadeAnimation(
                1.4,
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /// Input Password
              FadeAnimation(
                1.6,
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// Tombol Login
              FadeAnimation(
                1.8,
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.teal,
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 15),

// 🔹 Tombol Ganti IP di halaman login
              FadeAnimation(
                2.0,
                OutlinedButton.icon(
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
                            hintText: "contoh: http://192.168.1.10/project-api",
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Batal"),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(ctx, controller.text),
                            child: const Text("Simpan"),
                          ),
                        ],
                      ),
                    );

                    if (newIp != null && newIp.isNotEmpty) {
                      api.ApiService.updateBaseUrl(newIp);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Base URL diubah ke: $newIp")),
                      );
                      setState(() {}); // refresh UI kalau perlu
                    }
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text("Ganti IP Server"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
