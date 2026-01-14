import 'package:dio/dio.dart';

class DownloadApiClient {
  final Dio _dio;

  final String baseUrl;

  DownloadApiClient({required this.baseUrl}) : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  Future<Map<String, dynamic>> getVideoInfo(String url) async {
    try {
      final response = await _dio.post('/info', data: {'url': url});
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        String msg = 'Erro desconhecido (${e.response?.statusCode})';

        if (data is Map) {
           if (data.containsKey('detail')) {
             msg = data['detail'].toString();
           } else if (data.containsKey('error')) {
             msg = data['error'].toString();
           }
        }

        if (e.response?.statusCode == 403) {
           throw Exception("Acesso Negado: $msg");
        }
        throw Exception(msg);
      }
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      throw Exception('Falha ao obter info do vídeo: $e');
    }
  }

  Future<void> downloadStream({
    required String url,
    required String mode,
    required String savePath,
    int? quality,
    required Function(int received, int total) onReceiveProgress,
  }) async {
    final Map<String, dynamic> data = {
      'url': url,
      'mode': mode,
    };
    if (quality != null) {
      data['quality'] = quality;
    }

    try {
      await _dio.download(
        '/stream',
        savePath,
        data: data,
        options: Options(method: 'POST'),
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        String msg = 'Erro desconhecido (${e.response?.statusCode})';

        if (data is Map) {
           if (data.containsKey('detail')) {
             msg = data['detail'].toString();
           } else if (data.containsKey('error')) {
             msg = data['error'].toString();
           }
        }

        if (e.response?.statusCode == 403) {
          throw Exception("Acesso Negado: $msg");
        }
        throw Exception(msg);
      }
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      throw Exception('Falha ao baixar stream ($mode): $e');
    }
  }
}
