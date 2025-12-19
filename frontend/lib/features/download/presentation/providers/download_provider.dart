import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/download_api_client.dart';
import '../../data/repositories/download_repository_impl.dart';
import 'dart:convert';

// Providers
final downloadApiClientProvider = Provider((ref) => DownloadApiClient());
final downloadRepositoryProvider = Provider((ref) => DownloadRepository(ref.read(downloadApiClientProvider)));

// State
abstract class DownloadState {}
class DownloadInitial extends DownloadState {}
class DownloadLoading extends DownloadState {} // Buscando info
class DownloadInfoLoaded extends DownloadState {
  final Map<String, dynamic> info;
  DownloadInfoLoaded(this.info);
}
class DownloadProgress extends DownloadState {
  final Map<String, dynamic> info;
  final double percentage;
  final String speed;
  final String eta;

  DownloadProgress(this.info, this.percentage, this.speed, this.eta);
}
class DownloadSuccess extends DownloadState {
  final String filename;
  DownloadSuccess(this.filename);
}
class DownloadError extends DownloadState {
  final String message;
  DownloadError(this.message);
}

// Notifier
class DownloadNotifier extends Notifier<DownloadState> {
  late final DownloadRepository _repository;

  @override
  DownloadState build() {
    _repository = ref.read(downloadRepositoryProvider);
    return DownloadInitial();
  }

  Future<void> fetchVideoInfo(String url) async {
    state = DownloadLoading();
    try {
      final info = await _repository.getVideoInfo(url);
      state = DownloadInfoLoaded(info);
    } catch (e) {
      state = DownloadError(e.toString());
    }
  }

  Future<void> startDownload(String url, Map<String, dynamic> info) async {
    try {
      // Iniciar download
      final taskId = await _repository.startDownload(url);

      // Conectar WebSocket
      final channel = _repository.trackProgress(taskId);

      channel.stream.listen((message) {
        final data = jsonDecode(message);
        if (data['status'] == 'downloading') {
          state = DownloadProgress(
            info,
            (data['percentage'] as num).toDouble(),
            data['speed'].toString(), // Format speed as needed
            data['eta'].toString(),
          );
        } else if (data['status'] == 'finished') {
          state = DownloadSuccess(data['filename']);
          channel.sink.close();
        } else if (data['status'] == 'error') {
          state = DownloadError(data['message']);
          channel.sink.close();
        }
      }, onError: (error) {
        state = DownloadError("Erro de conexão: $error");
      });

    } catch (e) {
      state = DownloadError(e.toString());
    }
  }
}

final downloadProvider = NotifierProvider<DownloadNotifier, DownloadState>(() {
  return DownloadNotifier();
});
