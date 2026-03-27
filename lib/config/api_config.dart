import 'dart:io' show Platform;

const String _prodUrl = 'https://taskengine-backend.onrender.com/api';
const String _localUrl = 'http://localhost:3000/api';

// Desktop (Linux/Windows/macOS) uses localhost for development.
// Mobile (Android/iOS) uses the deployed Render backend.
final String apiBaseUrl =
    (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
        ? _prodUrl
        : _localUrl;
