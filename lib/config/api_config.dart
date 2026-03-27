import 'dart:io' show Platform;

const String _prodUrl = 'https://taskengine-backend.onrender.com/api';
const String _localUrl = 'http://localhost:3000/api';

final String apiBaseUrl = Platform.isAndroid ? _prodUrl : _localUrl;
