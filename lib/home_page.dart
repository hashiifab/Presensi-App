// BACKEND: Mengimpor library yang diperlukan untuk backend
import 'dart:convert'; // Untuk mengonversi data JSON
import 'package:presensi_app/login_page.dart'; // Untuk navigasi ke halaman login
import 'package:presensi_app/models/home_responses.dart'; // Model untuk menyimpan respons dari API
import 'package:presensi_app/save_page.dart'; // Untuk navigasi ke halaman untuk menyimpan data
import 'package:shared_preferences/shared_preferences.dart'; // Untuk menyimpan data lokal di perangkat
import 'package:http/http.dart' as myHttp; // Untuk melakukan HTTP request

// UI: Mengimpor library untuk UI Flutter
import 'package:flutter/material.dart'; // Untuk menggunakan widget Flutter

// UI: Kelas utama untuk halaman utama aplikasi (UI)
class HomePage extends StatefulWidget {
  const HomePage({super.key}); // Constructor untuk halaman utama

  @override
  State<HomePage> createState() =>
      _HomePageState(); // Membuat state untuk halaman ini
}

// BACKEND: State dari halaman utama, mengatur data dan logika aplikasi
class _HomePageState extends State<HomePage> {
  final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance(); // Menginisialisasi SharedPreferences
  late Future<String> _name, _token; // Variabel untuk menyimpan nama dan token
  HomeResponseModels?
      homeResponseModel; // Model untuk menyimpan respons dari API
  Datum? hariIni; // Menyimpan data presensi hari ini
  List<Datum> riwayat = []; // List untuk menyimpan riwayat presensi

  // BACKEND: Fungsi untuk melakukan logout dan menghapus token dari SharedPreferences
  Future<void> logout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token"); // Hapus token dari SharedPreferences
    await prefs.remove("name"); // Hapus nama dari SharedPreferences

    // UI: Navigasi ke halaman login dan hapus semua route sebelumnya
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void initState() {
    super.initState(); // Memanggil initState dari superclass

    // BACKEND: Mengambil token dan nama dari SharedPreferences
    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ?? "";
    });

    _name = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("name") ?? "";
    });

    // BACKEND: Mengambil data saat halaman diinisialisasi
    getData();
  }

  // BACKEND: Fungsi untuk mengambil data presensi dari API
  Future<void> getData() async {
    // BACKEND: Menyiapkan header untuk permintaan
    final Map<String, String> headers = {
      'Authorization':
          'Bearer ${await _token}' // Menambahkan token untuk otorisasi
    };

    try {
      // BACKEND: Melakukan permintaan GET ke API
      var response = await myHttp.get(
        Uri.parse('http://10.0.2.2:8000/api/get-presensi'),
        headers: headers,
      );

      // Debugging: Menampilkan respons di console
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // BACKEND: Memastikan status code adalah 200
      if (response.statusCode == 200) {
        // BACKEND: Mengonversi respons JSON ke model
        homeResponseModel =
            HomeResponseModels.fromJson(json.decode(response.body));

        // BACKEND: Clear riwayat dan log data yang diterima
        riwayat.clear(); // Mengosongkan list riwayat
        for (var element in homeResponseModel!.data) {
          if (element.isHariIni) {
            hariIni = element; // Menyimpan data presensi hari ini
          } else {
            riwayat.add(element); // Menambahkan data riwayat
          }
        }

        // Debugging: Menampilkan panjang riwayat di console
        print('Riwayat length: ${riwayat.length}');
      } else {
        // BACKEND: Menangani kesalahan jika status code bukan 200
        print('Error fetching data: ${response.statusCode}');
      }
    } catch (e) {
      // BACKEND: Menangani kesalahan jika terjadi exception
      print('Exception: $e');
    }
  }

  // UI: Fungsi build untuk menampilkan UI halaman
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading:
            false, // Menghilangkan panah kembali di AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // Tombol logout
            onPressed: () {
              logout(context); // Panggil fungsi logout
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Padding di sekitar konten
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // UI: FutureBuilder untuk menampilkan nama pengguna
              FutureBuilder<String>(
                future: _name, // Mengambil data nama pengguna
                builder:
                    (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(); // Menampilkan loading
                  } else {
                    // Menampilkan nama jika ada
                    if (snapshot.hasData) {
                      return Text(snapshot.data!,
                          style: const TextStyle(fontSize: 18));
                    } else {
                      return const Text("-", style: TextStyle(fontSize: 18));
                    }
                  }
                },
              ),
              const SizedBox(height: 20), // Jarak antara widget

              // UI: Menampilkan data presensi hari ini
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.blue[800]), // Warna latar belakang
                child: Padding(
                  padding:
                      const EdgeInsets.all(16.0), // Padding di dalam container
                  child: Column(children: [
                    // Menampilkan tanggal hari ini
                    Text(hariIni?.tanggal ?? '-',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 30), // Jarak
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround, // Mengatur posisi
                      children: [
                        Column(
                          children: [
                            // Menampilkan waktu masuk
                            Text(hariIni?.masuk ?? '-',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 24)),
                            const Text("Masuk",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16))
                          ],
                        ),
                        Column(
                          children: [
                            // Menampilkan waktu pulang
                            Text(hariIni?.pulang ?? '-',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 24)),
                            const Text("Pulang",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16))
                          ],
                        )
                      ],
                    )
                  ]),
                ),
              ),
              const SizedBox(height: 20), // Jarak
              const Text("Riwayat Presensi"), // Judul untuk riwayat

              // UI: Menampilkan riwayat presensi
              riwayat.isEmpty
                  ? const Center(
                      child: Text(
                          "Tidak ada riwayat presensi")) // Pesan jika tidak ada riwayat
                  : Expanded(
                      child: ListView.builder(
                        itemCount: riwayat.length, // Jumlah item dalam list
                        itemBuilder: (context, index) => Card(
                          child: ListTile(
                            leading: Text(riwayat[index]
                                .tanggal), // Menampilkan tanggal riwayat
                            title: Row(children: [
                              Column(
                                children: [
                                  // Menampilkan waktu masuk pada riwayat
                                  Text(riwayat[index].masuk,
                                      style: const TextStyle(fontSize: 18)),
                                  const Text("Masuk",
                                      style: TextStyle(fontSize: 14))
                                ],
                              ),
                              const SizedBox(width: 20), // Jarak
                              Column(
                                children: [
                                  // Menampilkan waktu pulang pada riwayat
                                  Text(riwayat[index].pulang,
                                      style: const TextStyle(fontSize: 18)),
                                  const Text("Pulang",
                                      style: TextStyle(fontSize: 14))
                                ],
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),

      // UI: Tombol untuk menambahkan data presensi baru
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(
                  builder: (context) =>
                      const SavePage())) // Navigasi ke halaman SavePage
              .then((value) {
            getData(); // Memanggil getData() untuk memperbarui data setelah kembali
          });
        },
        child: const Icon(Icons.add), // Ikon untuk tombol
      ),
    );
  }
}
