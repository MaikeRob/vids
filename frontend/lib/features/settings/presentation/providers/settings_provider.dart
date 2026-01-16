import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum HealthStatus { initial, checking, success, error, unreachable }

class SettingsState {
  final String ip;
  final String port;
  final HealthStatus healthStatus;
  final String? errorMessage;

  SettingsState({
    required this.ip,
    required this.port,
    this.healthStatus = HealthStatus.initial,
    this.errorMessage,
  });

  String get baseUrl => 'http://$ip:$port/api/v1/download';
  String get healthUrl => 'http://$ip:$port/health';

  SettingsState copyWith({
    String? ip,
    String? port,
    HealthStatus? healthStatus,
    String? errorMessage,
  }) {
    return SettingsState(
      ip: ip ?? this.ip,
      port: port ?? this.port,
      healthStatus: healthStatus ?? this.healthStatus,
      errorMessage: errorMessage ?? this.errorMessage,
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
      // Opcional: Checar conexão ao carregar
      checkConnection(ip, port);
    } catch (e) {
      debugPrint("Erro ao carregar configurações: $e");
      // Mantém estado default em caso de erro
    }
  }

  Future<void> updateSettings(String ip, String port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_ip', ip);
    await prefs.setString('api_port', port);

    // Atualiza estado e dispara verificação
    state = state.copyWith(ip: ip, port: port);
    checkConnection(ip, port);
  }

  Future<void> checkConnection(String ip, String port) async {
    state = state.copyWith(healthStatus: HealthStatus.checking, errorMessage: null);

    final url = Uri.parse('http://$ip:$port/health');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        state = state.copyWith(healthStatus: HealthStatus.success);
      } else {
        state = state.copyWith(
          healthStatus: HealthStatus.error,
          errorMessage: 'Erro: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint("Health Check Error: $e");
      String msg = 'Inalcançável';
      if (e.toString().contains('Connection refused')) {
         msg = 'Conexão recusada (Verifique IP/Porta)';
      } else if (e.toString().contains('Timeout')) {
         msg = 'Tempo limite excedido';
      }

      state = state.copyWith(
        healthStatus: HealthStatus.unreachable,
        errorMessage: msg,
      );
    }
  }

  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_ip');
    await prefs.remove('api_port');
    state = SettingsState(ip: _defaultIp, port: _defaultPort);
    checkConnection(_defaultIp, _defaultPort);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
