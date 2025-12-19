import '../datasources/download_api_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DownloadRepository {
  final DownloadApiClient _apiClient;

  DownloadRepository(this._apiClient);

  Future<Map<String, dynamic>> getVideoInfo(String url) => _apiClient.getVideoInfo(url);

  Future<String> startDownload(String url) => _apiClient.startDownload(url);

  WebSocketChannel trackProgress(String taskId) => _apiClient.connectToProgressStream(taskId);
}
