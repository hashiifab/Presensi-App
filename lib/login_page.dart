import 'dart:convert'; // Backend: Mengimpor paket untuk mengonversi data ke dan dari format JSON
import 'package:flutter/material.dart'; // UI: Mengimpor paket material untuk membangun UI Flutter
import 'package:http/http.dart' as myHttp; // Backend: Mengimpor paket http untuk melakukan HTTP request
import 'package:shared_preferences/shared_preferences.dart'; // Backend: Mengimpor paket untuk menyimpan data pengguna secara lokal
import 'package:presensi_app/home_page.dart'; // UI: Mengimpor halaman utama setelah login
import 'package:presensi_app/models/login_response.dart'; // Backend: Mengimpor model respon login untuk memproses data login

// Halaman login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key}); // UI: Konstruktor halaman login

  @override
  State<LoginPage> createState() =>
      _LoginPageState(); // UI: Mengembalikan state untuk LoginPage
}

class _LoginPageState extends State<LoginPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance(); // Backend: Inisialisasi SharedPreferences untuk menyimpan data lokal
  TextEditingController emailController = TextEditingController(); // UI: Kontroler untuk input email
  TextEditingController passwordController = TextEditingController(); // UI: Kontroler untuk input password
  late Future<String> _name, _token; // Backend: Variabel untuk menyimpan nama dan token secara asinkron

  @override
  void initState() {
    super.initState(); // UI: Memanggil fungsi initState dari superclass

    // Mengambil token dari SharedPreferences
    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ??
          ""; // Backend: Mengembalikan token jika ada, jika tidak, kembali string kosong
    });

    // Mengambil nama dari SharedPreferences
    _name = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("name") ??
          ""; // Backend: Mengembalikan nama jika ada, jika tidak, kembali string kosong
    });

    // Memeriksa apakah token dan nama ada
    checkToken(_token, _name);
  }

  // Fungsi untuk memeriksa keberadaan token dan nama
  checkToken(token, name) async {
    String tokenStr = await token; // Backend: Menunggu token menjadi string
    String nameStr = await name; // Backend: Menunggu nama menjadi string
    if (tokenStr != "" && nameStr != "") {
      // Jika token dan nama tidak kosong
      Future.delayed(const Duration(seconds: 1), () async {
        // UI: Menunggu 1 detik sebelum mengarahkan ke halaman utama
        Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    const HomePage())) // UI: Mengarahkan ke halaman utama
            .then((value) {
          setState(() {}); // UI: Memperbarui tampilan jika ada perubahan
        });
      });
    }
  }

  // Fungsi untuk melakukan login
  Future login(email, password) async {
    LoginResponseModels?
        loginResponseModel; // Backend: Mendeklarasikan model respon login
    Map<String, String> body = {
      "email": email,
      "password": password
    }; // Backend: Membuat body request dengan email dan password

    // Melakukan POST request ke API login
    var response = await myHttp
        .post(Uri.parse('http://127.0.0.1:8000/api/login'), body: body);

    // Memeriksa status kode dari respon
    if (response.statusCode == 401) {
      // UI: Jika status 401, berarti login gagal
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Email atau password salah"))); // UI: Menampilkan snackbar error
    } else {
      // Backend: Jika login berhasil, proses data respon
      loginResponseModel = LoginResponseModels.fromJson(json.decode(
          response.body)); // Backend: Mengonversi respon JSON menjadi model
      print('HASIL ${response.body}'); // Backend: Mencetak hasil respon
      saveUser(
          loginResponseModel.data.token,
          loginResponseModel
              .data.name); // Backend: Menyimpan token dan nama pengguna
    }
  }

  // Fungsi untuk menyimpan user di SharedPreferences
  Future saveUser(token, name) async {
    try {
      print("${"LEWAT SINI " + token} | " +
          name); // Backend: Mencetak token dan nama
      final SharedPreferences pref =
          await _prefs; // Backend: Mengambil SharedPreferences
      pref.setString("name", name); // Backend: Menyimpan nama pengguna
      pref.setString("token", token); // Backend: Menyimpan token pengguna

      // UI: Mengarahkan ke halaman utama setelah menyimpan data
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const HomePage()))
          .then((value) {
        setState(() {}); // UI: Memperbarui tampilan
      });
    } catch (err) {
      // UI: Menangani error jika terjadi
      print('ERROR :$err'); // Backend: Mencetak error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err.toString()))); // UI: Menampilkan snackbar error
    }
  }

  // Fungsi untuk membangun tampilan UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          // UI: Menggunakan SafeArea untuk menghindari area tidak aman pada layar
          child: Padding(
        padding: const EdgeInsets.all(
            8.0), // UI: Memberikan padding di sekitar tampilan
        child: Center(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // UI: Mengatur alignment kolom
            mainAxisAlignment:
                MainAxisAlignment.center, // UI: Mengatur alignment vertikal
            children: [
              const Center(child: Text("LOGIN")), // UI: Judul halaman login
              const SizedBox(height: 20), // UI: Memberikan jarak vertikal
              const Text("Email"), // UI: Label untuk input email
              TextField(
                controller:
                    emailController, // UI: Menghubungkan kontroler email
              ),
              const SizedBox(height: 20), // UI: Memberikan jarak vertikal
              const Text("Password"), // UI: Label untuk input password
              TextField(
                controller:
                    passwordController, // UI: Menghubungkan kontroler password
                obscureText: true, // UI: Menyembunyikan input password
              ),
              const SizedBox(height: 20), // UI: Memberikan jarak vertikal
              ElevatedButton(
                  onPressed: () {
                    // UI: Menangani event ketika tombol login ditekan
                    login(
                        emailController.text,
                        passwordController
                            .text); // Backend: Memanggil fungsi login dengan input dari user
                  },
                  child: const Text("Masuk")) // UI: Teks pada tombol login
            ],
          ),
        ),
      )),
    );
  }
}
