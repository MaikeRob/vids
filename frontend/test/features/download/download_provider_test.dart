import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:vids_frontend/features/download/data/repositories/download_repository_impl.dart';
import 'package:vids_frontend/features/download/presentation/providers/download_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';

// Gerar mock do repositório
@GenerateMocks([DownloadRepository, WebSocketChannel, WebSocketSink])
import 'download_provider_test.mocks.dart';

void main() {
  late MockDownloadRepository mockRepository;
  late MockWebSocketChannel mockChannel;
  late MockWebSocketSink mockSink;

  setUp(() {
    mockRepository = MockDownloadRepository();
    mockChannel = MockWebSocketChannel();
    mockSink = MockWebSocketSink();

    // Configurar o sink do channel mock
    when(mockChannel.sink).thenReturn(mockSink);
    when(mockSink.close()).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        downloadRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('DownloadNotifier Tests', () {
    test('Initial state should be DownloadInitial', () {
      final container = createContainer();
      expect(
        container.read(downloadProvider),
        isA<DownloadInitial>(),
      );
    });

    test('fetchVideoInfo success', () async {
      final container = createContainer();
      final videoInfo = {'title': 'Test Video', 'thumbnail': 'img.jpg'};

      when(mockRepository.getVideoInfo(any))
          .thenAnswer((_) async => videoInfo);

      await container.read(downloadProvider.notifier).fetchVideoInfo('http://test.com');

      expect(
        container.read(downloadProvider),
        isA<DownloadInfoLoaded>()
            .having((s) => s.info, 'info', videoInfo),
      );
    });

    test('fetchVideoInfo error', () async {
      final container = createContainer();

      when(mockRepository.getVideoInfo(any))
          .thenThrow(Exception('Network error'));

      await container.read(downloadProvider.notifier).fetchVideoInfo('http://test.com');

      expect(
        container.read(downloadProvider),
        isA<DownloadError>(),
      );
    });
  });
}
