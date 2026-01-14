import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/download_api_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../settings/presentation/providers/settings_provider.dart';

// Providers
// Recria o cliente sempre que as configurações mudarem
final downloadApiClientProvider = Provider((ref) {
  try {
    final settings = ref.watch(settingsProvider);
    return DownloadApiClient(baseUrl: settings.baseUrl);
  } catch (e, st) {
    debugPrint("DownloadApiClientProvider Error: $e\n$st");
    // Fallback para evitar crash total
    return DownloadApiClient(baseUrl: 'http://127.0.0.1:8000/api/v1/download');
  }
});

// State
abstract class DownloadState {}
class DownloadInitial extends DownloadState {}
class DownloadLoading extends DownloadState {}
class DownloadInfoLoaded extends DownloadState {
  final Map<String, dynamic> info;
  final List<dynamic> availableQualities;
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

class DownloadProcessing extends DownloadState {
  final Map<String, dynamic> info;
  final double videoProgress;
  final double audioProgress;
  final bool isMerging;

  DownloadProcessing(this.info, {
    this.videoProgress = 0,
    this.audioProgress = 0,
    this.isMerging = false,
  });

  DownloadProcessing copyWith({
    double? videoProgress,
    double? audioProgress,
    bool? isMerging,
  }) {
    return DownloadProcessing(
      info,
      videoProgress: videoProgress ?? this.videoProgress,
      audioProgress: audioProgress ?? this.audioProgress,
      isMerging: isMerging ?? this.isMerging,
    );
  }
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
  late DownloadApiClient _client;

  @override
  DownloadState build() {
    // Usar ref.watch para que o Notifier seja reconstruído se o cliente mudar (configurações alteradas)
    try {
      _client = ref.watch(downloadApiClientProvider);
      return DownloadInitial();
    } catch (e, st) {
      // Caso o provider de API falhe catastroficamente
      _client = DownloadApiClient(baseUrl: 'http://127.0.0.1:8000/api/v1/download');
      return DownloadError("Falha na inicialização do módulo de download: $e");
    }
  }

  Future<void> fetchVideoInfo(String url) async {
    state = DownloadLoading();
    try {
      final info = await _client.getVideoInfo(url);

      final List<dynamic> qualities = info['qualities'] ?? [];

      // Extract heights for default selection
      int? defaultQ;
      if (qualities.isNotEmpty) {
        defaultQ = qualities.first['height'];
      }

      state = DownloadInfoLoaded(
        info,
        availableQualities: qualities,
        selectedQuality: defaultQ,
      );
    } catch (e) {
      final msg = e.toString().replaceAll("Exception: ", "");
      state = DownloadError(msg);
    }
  }

  void setQuality(int quality) {
    if (state is DownloadInfoLoaded) {
      state = (state as DownloadInfoLoaded).copyWith(selectedQuality: quality);
    }
  }

  Future<void> startDownload(String url, Map<String, dynamic> info) async {
    final currentState = state;
    int? quality;
    int videoSize = 0;
    int audioSize = info['audio_filesize'] ?? 0;

    if (currentState is DownloadInfoLoaded) {
      quality = currentState.selectedQuality;
      // Find estimated video size
      final qObj = currentState.availableQualities.firstWhere(
        (q) => q['height'] == quality,
        orElse: () => {'filesize': 0}
      );
      videoSize = qObj['filesize'] ?? 0;
    }

    state = DownloadProcessing(info);

    try {
      String saveDir;
      if (Platform.isAndroid) {
        // Usar External Storage (Android/data/...) para melhor compatibilidade com FFmpeg Kit
        final externalDir = await getExternalStorageDirectory();
        saveDir = externalDir?.path ?? (await getApplicationDocumentsDirectory()).path;
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        saveDir = appDir.path;
      }

      final videoPath = '$saveDir/temp_video.mp4';
      final audioPath = '$saveDir/temp_audio.m4a';
      // Nome limpo para o arquivo final temporário
      final cleanTitle = info['title'].replaceAll(RegExp(r'[^\w\s]+'), '');
      final tempFinalPath = '$saveDir/$cleanTitle.mp4';

      // Clean old temps
      if (File(videoPath).existsSync()) File(videoPath).deleteSync();
      if (File(audioPath).existsSync()) File(audioPath).deleteSync();
      if (File(tempFinalPath).existsSync()) File(tempFinalPath).deleteSync();

      // Parallel Downloads
      final videoFuture = _client.downloadStream(
        url: url,
        mode: 'video',
        quality: quality,
        savePath: videoPath,
        onReceiveProgress: (received, total) {
           // If total is -1 (chunked), use estimated size
           final effectiveTotal = (total != -1) ? total : videoSize;
           double p = 0;
           if (effectiveTotal > 0) p = (received / effectiveTotal) * 100;
           if (p > 100) p = 100;

           if (state is DownloadProcessing) {
             state = (state as DownloadProcessing).copyWith(videoProgress: p);
           }
        },
      );

      final audioFuture = _client.downloadStream(
        url: url,
        mode: 'audio',
        savePath: audioPath,
        onReceiveProgress: (received, total) {
           final effectiveTotal = (total != -1) ? total : audioSize;
           double p = 0;
           if (effectiveTotal > 0) p = (received / effectiveTotal) * 100;
           if (p > 100) p = 100;

           if (state is DownloadProcessing) {
             state = (state as DownloadProcessing).copyWith(audioProgress: p);
           }
        },
      );

      await Future.wait([videoFuture, audioFuture]);

      // DEBUG: Verificar arquivos antes do merge
      final videoFile = File(videoPath);
      final audioFile = File(audioPath);

      debugPrint("DEBUG Check Video: exists=${videoFile.existsSync()}, path=$videoPath");
      if (videoFile.existsSync()) {
         debugPrint("DEBUG Video Size: ${videoFile.lengthSync()} bytes");
      }

      debugPrint("DEBUG Check Audio: exists=${audioFile.existsSync()}, path=$audioPath");
      if (audioFile.existsSync()) {
         debugPrint("DEBUG Audio Size: ${audioFile.lengthSync()} bytes");
      } else {
         throw Exception("Arquivo de áudio não foi baixado corretamente: $audioPath");
      }

      if (!videoFile.existsSync()) {
        throw Exception("Arquivo de vídeo não foi baixado corretamente: $videoPath");
      }

      // Delay para garantir que o sistema de arquivos liberou o lock (Race Condition Fix)
      await Future.delayed(const Duration(milliseconds: 1500));

      // Merge
      if (state is DownloadProcessing) {
        state = (state as DownloadProcessing).copyWith(isMerging: true);
      }

      await _mergeFiles(videoPath, audioPath, tempFinalPath);

      // Cleanup Temps
      if (File(videoPath).existsSync()) await File(videoPath).delete();
      if (File(audioPath).existsSync()) await File(audioPath).delete();

      String finalPublicPath = tempFinalPath;

      // Se Android, copiar para public downloads
      if (Platform.isAndroid) {
         try {
            // Verificar permissão antes de copiar
             if (await Permission.videos.request().isGranted ||
                await Permission.storage.request().isGranted ||
                await Permission.manageExternalStorage.request().isGranted) {

                final publicDir = Directory('/storage/emulated/0/Download');
                if (!publicDir.existsSync()) {
                  publicDir.createSync(recursive: true);
                }

                final publicPath = '${publicDir.path}/$cleanTitle.mp4';

                // Copiar
                await File(tempFinalPath).copy(publicPath);

                // Deletar o processado privado
                await File(tempFinalPath).delete();

                finalPublicPath = publicPath;
             }
         } catch (e) {
            debugPrint("Erro ao copiar para público: $e");
            // Se falhar copia, finalPublicPath continua sendo o privado,
            // que ainda é acessível mas não "público" na galeria padrão sem scan
         }
      }

      state = DownloadSuccess(finalPublicPath);

    } catch (e) {
      final msg = e.toString().replaceAll("Exception: ", "");
      state = DownloadError(msg);
      debugPrint("Download Error: $e");
    }
  }

  Future<void> _mergeFiles(String videoPath, String audioPath, String outputPath) async {
    // Command: -i video -i audio -c:v copy -c:a copy output.mp4
    // Using copy is faster than re-encoding
    // Aspas duplas para garantir que espaços não quebrem
    final command = '-i "$videoPath" -i "$audioPath" -c:v copy -c:a copy "$outputPath"';

    debugPrint("FFmpeg Start: $command");

    // Usar execute (síncrono/awaitable) para capturar o erro corretamente no fluxo principal
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint("FFmpeg Success");
      } else {
        final logs = await session.getAllLogsAsString();
        debugPrint("FFmpeg Fail: $logs");
        throw Exception("Merge falhou: Verifique logs para detalhes.");
      }
    });
  }
}

final downloadProvider = NotifierProvider<DownloadNotifier, DownloadState>(() {
  return DownloadNotifier();
});
