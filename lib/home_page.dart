import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as myHttp;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:presensi_app/login_page.dart';
import 'package:presensi_app/models/home_response.dart';
import 'package:presensi_app/save_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _name = ""; // Nama pengguna
  late String _token = ""; // Token otentikasi
  HomeResponseModels? homeResponseModel;
  Datum? hariIni;
  List<Datum> riwayat = [];

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Panggil fungsi untuk memuat data pengguna
    getData(); // Memuat data dari API
  }

  Future<void> _loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString("name") ?? "";
      _token = prefs.getString("token") ?? "";
      print('Token: $_token'); // Debugging token
    });
  }

  Future<void> logout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("name");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> getData() async {
    final Map<String, String> headers = {
      'Authorization': 'Bearer $_token',
    };

    try {
      var response = await myHttp.get(
        // Ganti 127.0.0.1 dengan 10.0.2.2 jika menggunakan emulator
        Uri.parse('http://127.0.0.1:8000/api/get-presensi'),
        headers: headers,
      );

      print('Response Status: ${response.statusCode}'); // Debugging status code
      print('Response Body: ${response.body}'); // Debugging respons

      if (response.statusCode == 200) {
        homeResponseModel =
            HomeResponseModels.fromJson(json.decode(response.body));

        setState(() {
          riwayat.clear();
          bool hasHariIni = false; // Tambahkan flag untuk cek apakah ada data presensi hari ini
          
          for (var element in homeResponseModel!.data) {
            if (element.isHariIni) {
              hariIni = element;
              hasHariIni = true;
            } else {
              riwayat.add(element);
            }
          }

          // Jika tidak ada data hari ini, pastikan `hariIni` tetap kosong
          if (!hasHariIni) {
            hariIni = null;
          }
        });

        // Debugging: Cetak isi hariIni ke console
        if (hariIni != null) {
          print('Data hari ini: ${hariIni!.tanggal}, masuk: ${hariIni!.masuk}, pulang: ${hariIni!.pulang}');
        } else {
          print('Tidak ada presensi untuk hari ini');
        }

        // Debugging: Cetak panjang riwayat ke console
        print('Riwayat length: ${riwayat.length}');
      } else {
        print('Error fetching data: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              logout(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_name, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.blue[800]),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Jika hariIni tidak null, tampilkan data; jika null, tampilkan "-"
                      Text(hariIni?.tanggal ?? '-',
                          style: const TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(hariIni?.masuk ?? '-',
                                  style: const TextStyle(color: Colors.white, fontSize: 24)),
                              const Text("Masuk",
                                  style: TextStyle(color: Colors.white, fontSize: 16))
                            ],
                          ),
                          Column(
                            children: [
                              Text(hariIni?.pulang ?? '-',
                                  style: const TextStyle(color: Colors.white, fontSize: 24)),
                              const Text("Pulang",
                                  style: TextStyle(color: Colors.white, fontSize: 16))
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Riwayat Presensi"),
              riwayat.isEmpty
                  ? const Center(child: Text("Tidak ada riwayat presensi"))
                  : Expanded(
                      child: ListView.builder(
                        itemCount: riwayat.length,
                        itemBuilder: (context, index) => Card(
                          child: ListTile(
                            leading: Text(riwayat[index].tanggal),
                            title: Row(
                              children: [
                                Column(
                                  children: [
                                    Text(riwayat[index].masuk,
                                        style: const TextStyle(fontSize: 18)),
                                    const Text("Masuk",
                                        style: TextStyle(fontSize: 14))
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Column(
                                  children: [
                                    Text(riwayat[index].pulang,
                                        style: const TextStyle(fontSize: 18)),
                                    const Text("Pulang",
                                        style: TextStyle(fontSize: 14))
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const SavePage()))
              .then((value) {
            getData();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
