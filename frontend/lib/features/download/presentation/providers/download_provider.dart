import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/download_api_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../settings/presentation/providers/settings_provider.dart';

// Enums
enum DownloadMode { video, audio }
enum AudioFormat { m4a, mp3 }

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
  final DownloadMode downloadMode;
  final AudioFormat audioFormat;

  DownloadInfoLoaded(this.info, {
    this.availableQualities = const [],
    this.selectedQuality,
    this.downloadMode = DownloadMode.video,
    this.audioFormat = AudioFormat.m4a,
  });

  DownloadInfoLoaded copyWith({
    int? selectedQuality,
    DownloadMode? downloadMode,
    AudioFormat? audioFormat,
  }) {
    return DownloadInfoLoaded(
      info,
      availableQualities: availableQualities,
      selectedQuality: selectedQuality ?? this.selectedQuality,
      downloadMode: downloadMode ?? this.downloadMode,
      audioFormat: audioFormat ?? this.audioFormat,
    );
  }
}

class DownloadProcessing extends DownloadState {
  final Map<String, dynamic> info;
  final double videoProgress;
  final double audioProgress;
  final bool isMerging;
  final String statusMessage;
  final DownloadMode downloadMode;

  DownloadProcessing(this.info, {
    this.videoProgress = 0,
    this.audioProgress = 0,
    this.isMerging = false,
    this.statusMessage = 'Processando...',
    this.downloadMode = DownloadMode.video,
  });

  DownloadProcessing copyWith({
    double? videoProgress,
    double? audioProgress,
    bool? isMerging,
    String? statusMessage,
    DownloadMode? downloadMode,
  }) {
    return DownloadProcessing(
      info,
      videoProgress: videoProgress ?? this.videoProgress,
      audioProgress: audioProgress ?? this.audioProgress,
      isMerging: isMerging ?? this.isMerging,
      statusMessage: statusMessage ?? this.statusMessage,
      downloadMode: downloadMode ?? this.downloadMode,
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
/// Gerencia o estado e a lógica de download de vídeos.
///
/// Responsável por comunicar com a API, gerenciar o estado de [DownloadState]
/// e coordenar downloads paralelos de vídeo e áudio.
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

  void setDownloadMode(DownloadMode mode) {
    if (state is DownloadInfoLoaded) {
      state = (state as DownloadInfoLoaded).copyWith(downloadMode: mode);
    }
  }

  void setAudioFormat(AudioFormat format) {
    if (state is DownloadInfoLoaded) {
      state = (state as DownloadInfoLoaded).copyWith(audioFormat: format);
    }
  }

  Future<void> startDownload(String url, Map<String, dynamic> info) async {
    final currentState = state;
    if (currentState is! DownloadInfoLoaded) return;

    final mode = currentState.downloadMode;
    final audioFormat = currentState.audioFormat;

    int? quality = currentState.selectedQuality;
    int videoSize = 0;
    int audioSize = info['audio_filesize'] ?? 0;

    if (mode == DownloadMode.video) {
      // Find estimated video size
      final qObj = currentState.availableQualities.firstWhere(
        (q) => q['height'] == quality,
        orElse: () => {'filesize': 0}
      );
      videoSize = qObj['filesize'] ?? 0;
    }

    state = DownloadProcessing(
      info,
      statusMessage: mode == DownloadMode.video ? 'Baixando faixas...' : 'Baixando áudio...',
      downloadMode: mode,
    );

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

      // Clean old temps
      final videoPath = '$saveDir/temp_video.mp4';
      final audioPath = '$saveDir/temp_audio.m4a';
      final cleanTitle = info['title'].replaceAll(RegExp(r'[^\w\s]+'), '');

      // Determine final extension based on mode/format
      String finalExt = '.mp4';
      if (mode == DownloadMode.audio) {
        finalExt = audioFormat == AudioFormat.mp3 ? '.mp3' : '.m4a';
      }
      final tempFinalPath = '$saveDir/$cleanTitle$finalExt';

      if (File(videoPath).existsSync()) File(videoPath).deleteSync();
      if (File(audioPath).existsSync()) File(audioPath).deleteSync();
      if (File(tempFinalPath).existsSync()) File(tempFinalPath).deleteSync();

      if (mode == DownloadMode.video) {
        // --- VIDEO MODE ---
        final videoFuture = _client.downloadStream(
          url: url,
          mode: 'video',
          quality: quality,
          savePath: videoPath,
          onReceiveProgress: (received, total) {
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

        // Merge Video + Audio
        await Future.delayed(const Duration(milliseconds: 1000));

        if (state is DownloadProcessing) {
          state = (state as DownloadProcessing).copyWith(isMerging: true, statusMessage: 'Unindo arquivos...');
        }
        await _mergeVideoAudio(videoPath, audioPath, tempFinalPath);

      } else {
        // --- AUDIO MODE ---
        await _client.downloadStream(
          url: url,
          mode: 'audio',
          savePath: audioPath, // Baixa como m4a primeiro
          onReceiveProgress: (received, total) {
             final effectiveTotal = (total != -1) ? total : audioSize;
             double p = 0;
             if (effectiveTotal > 0) p = (received / effectiveTotal) * 100;
             if (p > 100) p = 100;
             if (state is DownloadProcessing) {
               state = (state as DownloadProcessing).copyWith(audioProgress: p); // Use audio/video progress generic?
               // Audio fills audioProgress, video stays 0
             }
          },
        );

        await Future.delayed(const Duration(milliseconds: 1000));

        if (audioFormat == AudioFormat.mp3) {
           if (state is DownloadProcessing) {
             state = (state as DownloadProcessing).copyWith(isMerging: true, statusMessage: 'Convertendo para MP3...');
           }
           await _convertToMp3(audioPath, tempFinalPath);
        } else {
           // M4A - Just rename/copy
           // O arquivo já está em audioPath (m4a), mas precisamos mover para tempFinalPath para o passo de copia pública
           await File(audioPath).copy(tempFinalPath);
        }
      }

      // Cleanup Temps (exceto o final se for direto)
      if (File(videoPath).existsSync()) await File(videoPath).delete();
      if (File(audioPath).existsSync()) await File(audioPath).delete();

      String finalPublicPath = tempFinalPath;

      // Copy to Public Directory (Android)
      if (Platform.isAndroid) {
         try {
             if (await Permission.videos.request().isGranted ||
                await Permission.audio.request().isGranted ||
                await Permission.storage.request().isGranted ||
                await Permission.manageExternalStorage.request().isGranted) {

                // Folder selection based on type
                String folderName = (mode == DownloadMode.video) ? 'Movies' : 'Music'; // Or Download for both?
                // User requirement implied standards. Let's stick to Download folder as it is easier to find.
                folderName = 'Download';

                final publicDir = Directory('/storage/emulated/0/$folderName');
                if (!publicDir.existsSync()) {
                  publicDir.createSync(recursive: true);
                }

                final publicPath = '${publicDir.path}/$cleanTitle$finalExt';

                await File(tempFinalPath).copy(publicPath);
                await File(tempFinalPath).delete(); // Delete internal temp

                finalPublicPath = publicPath;
             }
         } catch (e) {
            debugPrint("Erro ao copiar para público: $e");
         }
      }

      state = DownloadSuccess(finalPublicPath);

    } catch (e) {
      final msg = e.toString().replaceAll("Exception: ", "");
      state = DownloadError(msg);
      debugPrint("Download Error: $e");
    }
  }

  Future<void> _mergeVideoAudio(String videoPath, String audioPath, String outputPath) async {
    // -c:v copy -c:a copy
    final command = '-i "$videoPath" -i "$audioPath" -c:v copy -c:a copy "$outputPath"';
    await _runFFmpeg(command, "Merge falhou");
  }

  Future<void> _convertToMp3(String inputPath, String outputPath) async {
    // -c:a libmp3lame -q:a 2 (High quality variable bitrate)
    final command = '-i "$inputPath" -c:a libmp3lame -q:a 2 "$outputPath"';
    await _runFFmpeg(command, "Conversão MP3 falhou");
  }

  Future<void> _runFFmpeg(String command, String errorMessage) async {
    debugPrint("FFmpeg Start: $command");
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint("FFmpeg Success");
      } else {
        final logs = await session.getAllLogsAsString();
        debugPrint("FFmpeg Fail: $logs");
        throw Exception("$errorMessage: Verifique logs.");
      }
    });
  }
}

final downloadProvider = NotifierProvider<DownloadNotifier, DownloadState>(() {
  return DownloadNotifier();
});
