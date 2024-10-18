import 'dart:convert'; // Backend: Untuk mengonversi data JSON
import 'package:flutter/material.dart'; // UI: Untuk menggunakan widget Flutter
import 'package:location/location.dart'; // Backend: Untuk mengakses lokasi perangkat
import 'package:presensi_app/models/save_response.dart'; // Backend: Model untuk menyimpan respons dari API
import 'package:shared_preferences/shared_preferences.dart'; // Backend: Untuk menyimpan data lokal di perangkat
import 'package:syncfusion_flutter_maps/maps.dart'; // UI: Untuk menampilkan peta
import 'package:http/http.dart' as myHttp; // Backend: Untuk melakukan HTTP request

// Kelas utama untuk halaman simpan presensi
class SavePage extends StatefulWidget {
  const SavePage({super.key}); // UI: Constructor untuk halaman simpan presensi

  @override
  State<SavePage> createState() => _SavePageState(); // UI: Membuat state untuk halaman ini
}

class _SavePageState extends State<SavePage> {
  final Future<SharedPreferences> _prefs = 
      SharedPreferences.getInstance(); // Backend: Menginisialisasi SharedPreferences
  late Future<String> _token; // Backend: Variabel untuk menyimpan token

  @override
  void initState() {
    super.initState(); // UI: Memanggil initState dari superclass
    // Mengambil token dari SharedPreferences
    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ?? ""; // Backend: Mengambil token dari SharedPreferences
    });
  }

  // Fungsi untuk mendapatkan lokasi saat ini
  Future<LocationData?> _currenctLocation() async {
    bool serviceEnable;
    PermissionStatus permissionGranted;

    Location location = Location(); // Backend: Instance dari Location untuk akses lokasi

    // Memeriksa apakah layanan lokasi diaktifkan
    serviceEnable = await location.serviceEnabled();
    if (!serviceEnable) {
      serviceEnable = await location.requestService(); // Backend: Meminta untuk mengaktifkan layanan lokasi
      if (!serviceEnable) {
        return null; // Backend: Mengembalikan null jika layanan tidak diaktifkan
      }
    }

    // Memeriksa izin lokasi
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = 
          await location.requestPermission(); // Backend: Meminta izin lokasi
      if (permissionGranted != PermissionStatus.granted) {
        return null; // Backend: Mengembalikan null jika izin tidak diberikan
      }
    }

    return await location.getLocation(); // Backend: Mengembalikan data lokasi saat ini
  }

  // Fungsi untuk menyimpan data presensi
  Future savePresensi(double latitude, double longitude) async {
    // Mempersiapkan body untuk permintaan
    Map<String, String> body = {
      "latitude": latitude.toString(),
      "longitude": longitude.toString()
    };

    // Menyiapkan header untuk permintaan
    Map<String, String> headers = {'Authorization': 'Bearer ${await _token}'}; // Backend: Menyiapkan header dengan token

    try {
      // Melakukan permintaan POST ke API untuk menyimpan presensi
      var response = await myHttp.post(
        Uri.parse("http://127.0.0.1:8000/api/save-presensi"), // Backend: URL API untuk menyimpan presensi
        body: body,
        headers: headers,
      );

      // Cek status code sebelum melanjutkan
      if (response.statusCode == 200) {
        // Mengonversi respons JSON ke model
        SaveResponseModels savePresensiResponseModel =
            SaveResponseModels.fromJson(json.decode(response.body)); // Backend: Mengonversi respons

        if (savePresensiResponseModel.success) {
          // UI: Menampilkan SnackBar jika berhasil
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sukses simpan Presensi')),
          );
          Navigator.pop(context); // UI: Kembali ke halaman sebelumnya
        } else {
          // UI: Menampilkan SnackBar jika gagal
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Gagal simpan Presensi: ${savePresensiResponseModel.message}')),
          );
        }
      } else {
        // UI: Menampilkan SnackBar jika terjadi kesalahan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // UI: Menampilkan SnackBar jika terjadi exception
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Presensi"), // UI: Judul untuk AppBar
      ),
      // FutureBuilder untuk mendapatkan lokasi saat ini
      body: FutureBuilder<LocationData?>(
          future: _currenctLocation(),
          builder: (BuildContext context, AsyncSnapshot<LocationData?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator()); // UI: Menampilkan loading
            } else if (snapshot.hasData) {
              // Jika lokasi ditemukan
              final LocationData currentLocation = snapshot.data!;
              print(
                  "Current Location: ${currentLocation.latitude}, ${currentLocation.longitude}"); // Backend: Logging lokasi
              return SafeArea(
                  child: Column(
                children: [
                  // UI: Menampilkan peta dengan marker lokasi saat ini
                  SizedBox(
                    height: 300,
                    child: SfMaps(
                      layers: [
                        MapTileLayer(
                          initialFocalLatLng: MapLatLng(
                              currentLocation.latitude!,
                              currentLocation.longitude!), // UI: Mengatur pusat peta
                          initialZoomLevel: 15, // UI: Tingkat zoom awal
                          initialMarkersCount: 1, // UI: Jumlah marker awal
                          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png", // UI: URL template untuk peta
                          markerBuilder: (BuildContext context, int index) {
                            return MapMarker(
                              latitude: currentLocation.latitude!,
                              longitude: currentLocation.longitude!,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red, // UI: Warna marker
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20), // UI: Jarak antara peta dan tombol
                  // UI: Tombol untuk menyimpan presensi
                  ElevatedButton(
                    onPressed: () {
                      savePresensi(
                          currentLocation.latitude!,
                          currentLocation.longitude!); // UI: Memanggil fungsi savePresensi
                    },
                    child: const Text("Simpan Presensi"), // UI: Teks pada tombol
                  ),
                ],
              ));
            } else {
              // UI: Menampilkan pesan jika lokasi tidak ditemukan
              return const Center(child: Text("Lokasi tidak ditemukan"));
            }
          }),
    );
  }
}
