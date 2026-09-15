import 'package:flutter/foundation.dart';

class ApiConfig {
  // Otomatis pilih URL berdasarkan platform:
  // - Web (Chrome): localhost:3000
  // - Android Emulator: 10.0.2.2:3000
  // - Android Device fisik (WiFi): 192.168.18.6:3000
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    // Android emulator: ganti ke device IP kalau pakai HP fisik
    return 'http://10.0.2.2:3000/api/v1';
  }
}
