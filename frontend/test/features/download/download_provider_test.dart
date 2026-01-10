import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:vids_frontend/features/download/data/datasources/download_api_client.dart';
import 'package:vids_frontend/features/download/presentation/providers/download_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Gerar mock do repositório
@GenerateMocks([DownloadApiClient, WebSocketChannel, WebSocketSink])
import 'download_provider_test.mocks.dart';


void main() {
  late MockDownloadApiClient mockClient;
  late MockWebSocketChannel mockChannel;
  late MockWebSocketSink mockSink;

  setUp(() {
    mockClient = MockDownloadApiClient();
    mockChannel = MockWebSocketChannel();
    mockSink = MockWebSocketSink();

    // Configurar o sink do channel mock
    when(mockChannel.sink).thenReturn(mockSink);
    when(mockSink.close()).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        downloadApiClientProvider.overrideWithValue(mockClient),
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

      when(mockClient.getVideoInfo(any))
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

      when(mockClient.getVideoInfo(any))
          .thenThrow(Exception('Network error'));

      await container.read(downloadProvider.notifier).fetchVideoInfo('http://test.com');

      expect(
        container.read(downloadProvider),
        isA<DownloadError>(),
      );
      expect(
        container.read(downloadProvider),
        isA<DownloadError>(),
      );
    });

    test('startDownload connects to stream and updates progress', () async {
      final container = createContainer();
      final videoInfo = {'title': 'Test Video', 'thumbnail': 'img.jpg'};
      final taskId = 'task-123';
      
      // Setup fetch info first to set state to DownloadInfoLoaded
      when(mockClient.getVideoInfo(any)).thenAnswer((_) async => videoInfo);
      await container.read(downloadProvider.notifier).fetchVideoInfo('http://test.com');
      
      // Mock startDownload
      when(mockClient.startDownload(any, quality: anyNamed('quality')))
          .thenAnswer((_) async => taskId);
          
      // Mock stream connection
      // We need a stream that emits values
      final streamController = StreamController<dynamic>();
      when(mockChannel.stream).thenAnswer((_) => streamController.stream);
      when(mockClient.connectToProgressStream(taskId))
          .thenReturn(mockChannel);

      // Act
      final future = container.read(downloadProvider.notifier).startDownload('http://test.com', videoInfo);
      
      // Emit progress
      streamController.add('{"status": "downloading", "percentage": 10.5, "speed": "1MB/s", "eta": "20s"}');
      
      // Wait for stream listener to process
      await Future.delayed(Duration.zero);

      // Assert
      final state = container.read(downloadProvider);
      expect(state, isA<DownloadProgress>());
      if (state is DownloadProgress) {
        expect(state.percentage, 10.5);
        expect(state.speed, '1MB/s');
      }
      
      // Cleanup
      streamController.close();
      await future; 
    });
  });
}

