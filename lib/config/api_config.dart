import 'dart:io' show Platform;

final String apiBaseUrl = Platform.isAndroid
    ? 'http://10.0.2.2:3000/api' // Android emulator → host
    : 'http://localhost:3000/api'; // Desktop / iOS simulator
