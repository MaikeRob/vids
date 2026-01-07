import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/download_api_client.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

// Providers
final downloadApiClientProvider = Provider((ref) => DownloadApiClient());

// State
abstract class DownloadState {}
class DownloadInitial extends DownloadState {}
class DownloadLoading extends DownloadState {} // Buscando info
class DownloadInfoLoaded extends DownloadState {
  final Map<String, dynamic> info;
  final List<int> availableQualities;
  final int? selectedQuality;

  DownloadInfoLoaded(this.info, {this.availableQualities = const [], this.selectedQuality});

  DownloadInfoLoaded copyWith({int? selectedQuality}) {
    return DownloadInfoLoaded(
      info,
      availableQualities: availableQualities,
      selectedQuality: selectedQuality ?? this.selectedQuality,
    );
  }
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
  late final DownloadApiClient _client;

  @override
  DownloadState build() {
    _client = ref.read(downloadApiClientProvider);
    return DownloadInitial();
  }

  Future<void> fetchVideoInfo(String url) async {
    state = DownloadLoading();
    try {
      final info = await _client.getVideoInfo(url);
      
      final List<dynamic> qualitiesRaw = info['qualities'] ?? [];
      final List<int> qualities = qualitiesRaw.cast<int>();

      state = DownloadInfoLoaded(
        info,
        availableQualities: qualities,
        selectedQuality: qualities.isNotEmpty ? qualities.first : null,
      );
    } catch (e) {
      state = DownloadError(e.toString());
    }
  }

  void setQuality(int quality) {
    if (state is DownloadInfoLoaded) {
      state = (state as DownloadInfoLoaded).copyWith(selectedQuality: quality);
    }
  }

  Future<void> startDownload(String url, Map<String, dynamic> info) async {
    try {
      int? quality;
      if (state is DownloadInfoLoaded) {
        quality = (state as DownloadInfoLoaded).selectedQuality;
      }

      // Iniciar download
      final taskId = await _client.startDownload(url, quality: quality);

      // Conectar WebSocket
      final channel = _client.connectToProgressStream(taskId);

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
          final filename = data['filename'];
          // Trigger file download to device
          _downloadToDevice(filename);
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

  Future<void> _downloadToDevice(String filename) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      }
      
      // Fallback for iOS or if external storage fails
      directory ??= await getApplicationDocumentsDirectory();

      final savePath = '${directory.path}/$filename';
      
      await _client.downloadFile(filename, savePath);
      state = DownloadSuccess(filename);
    } catch (e) {
      state = DownloadError("Erro ao salvar no dispositivo: $e");
    }
  }
}

final downloadProvider = NotifierProvider<DownloadNotifier, DownloadState>(() {
  return DownloadNotifier();
});
