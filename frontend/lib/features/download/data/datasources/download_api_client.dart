import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DownloadApiClient {
  final Dio _dio;

  // URL base - usar 10.0.2.2 para emulador Android acessar localhost do host
  // URL base - ALTERADO para IP da LAN para teste em dispositivo real
  // URL base - usar 10.0.2.2 para emulador Android acessar localhost do host
  static const String _baseUrl = 'http://10.0.2.2:8000/api/v1/download';
  static const String _wsUrl = 'ws://10.0.2.2:8000/api/v1/download/ws';

  DownloadApiClient() : _dio = Dio(BaseOptions(baseUrl: _baseUrl));

  Future<Map<String, dynamic>> getVideoInfo(String url) async {
    try {
      final response = await _dio.post('/info', data: {'url': url});
      return response.data;
    } catch (e) {
      throw Exception('Falha ao obter info do vídeo: $e');
    }
  }

  Future<String> startDownload(String url) async {
    try {
      final response = await _dio.post('/start', data: {'url': url});
      return response.data['task_id'];
    } catch (e) {
      throw Exception('Falha ao iniciar download: $e');
    }
  }

  WebSocketChannel connectToProgressStream(String taskId) {
    return WebSocketChannel.connect(Uri.parse('$_wsUrl/$taskId'));
  }
}
