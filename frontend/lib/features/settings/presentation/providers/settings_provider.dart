import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class SettingsState {
  final String ip;
  final String port;

  SettingsState({required this.ip, required this.port});

  String get baseUrl => 'http://$ip:$port/api/v1/download';

  SettingsState copyWith({String? ip, String? port}) {
    return SettingsState(
      ip: ip ?? this.ip,
      port: port ?? this.port,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  // Default values
  // Android Emulator precisa de 10.0.2.2 p/ acessar host
  // Linux/Desktop usa localhost (127.0.0.1)
  String get _defaultIp {
    try {
      if (Platform.isAndroid) return '10.0.2.2';
    } catch (_) {}
    return '127.0.0.1';
  }

  static const String _defaultPort = '8000';

  @override
  SettingsState build() {
    try {
      _loadSettings();
      // Usa o getter dinâmico
      return SettingsState(ip: _defaultIp, port: _defaultPort);
    } catch (e, st) {
      debugPrint("SettingsNotifier Build Error: $e\n$st");
      // Fallback seguro
      return SettingsState(ip: '127.0.0.1', port: '8000');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ip = prefs.getString('api_ip') ?? _defaultIp;
      final port = prefs.getString('api_port') ?? _defaultPort;
      state = SettingsState(ip: ip, port: port);
    } catch (e) {
      debugPrint("Erro ao carregar configurações: $e");
      // Mantém estado default em caso de erro
    }
  }

  Future<void> updateSettings(String ip, String port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_ip', ip);
    await prefs.setString('api_port', port);
    state = state.copyWith(ip: ip, port: port);
  }

  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_ip');
    await prefs.remove('api_port');
    state = SettingsState(ip: _defaultIp, port: _defaultPort);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
