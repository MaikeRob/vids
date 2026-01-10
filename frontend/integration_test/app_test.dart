
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:vids_frontend/main.dart' as app;
import 'package:vids_frontend/features/download/data/datasources/download_api_client.dart';
import 'package:vids_frontend/features/download/presentation/providers/download_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';

// Mock Manually for Integration Test reliability or Import
class MockDownloadApiClient extends Mock implements DownloadApiClient {
  @override
  Future<Map<String, dynamic>> getVideoInfo(String? url) {
    return super.noSuchMethod(
      Invocation.method(#getVideoInfo, [url]),
      returnValue: Future.value({'title': 'Integration Test Video', 'thumbnail': 'https://example.com/img.jpg', 'qualities': [1080, 720]}),
      returnValueForMissingStub: Future.value({'title': 'Integration Test Video', 'thumbnail': 'https://example.com/img.jpg', 'qualities': [1080, 720]}),
    );
  }

  @override
  Future<String> startDownload(String? url, {int? quality}) {
    return super.noSuchMethod(
      Invocation.method(#startDownload, [url], {#quality: quality}),
      returnValue: Future.value('task-id-123'),
      returnValueForMissingStub: Future.value('task-id-123'),
    );
  }

  @override
  WebSocketChannel connectToProgressStream(String? taskId) {
     return super.noSuchMethod(
      Invocation.method(#connectToProgressStream, [taskId]),
      returnValue: MockWebSocketChannel(),
      returnValueForMissingStub: MockWebSocketChannel(),
    );
  }
  
  @override
  Future<void> downloadFile(String? filename, String? savePath) {
     return super.noSuchMethod(
      Invocation.method(#downloadFile, [filename, savePath]),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );
  }
}

class MockWebSocketChannel extends Mock implements WebSocketChannel {
  final _controller = StreamController<dynamic>();
  
  @override
  Stream get stream => _controller.stream;
  
  @override
  WebSocketSink get sink => MockWebSocketSink();
  
  void emit(String message) {
    _controller.add(message);
  }
  
  void closeStream() {
    _controller.close();
  }
}

class MockWebSocketSink extends Mock implements WebSocketSink {
  @override
  Future close([int? closeCode, String? closeReason]) async {}
  
  @override
  void add(data) {}
}


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full download flow test', (WidgetTester tester) async {
    // Setup Mocks
    final mockClient = MockDownloadApiClient();
    final mockChannel = MockWebSocketChannel();
    
    when(mockClient.getVideoInfo(any)).thenAnswer((_) async => {
      'title': 'Integration Test Video',
      'thumbnail': 'https://example.com/img.jpg',
      'qualities': [1080, 720]
    });
    
    when(mockClient.startDownload(any, quality: anyNamed('quality')))
        .thenAnswer((_) async => 'task-id-123');
        
    when(mockClient.connectToProgressStream(any))
        .thenReturn(mockChannel);

    // Override Provider
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadApiClientProvider.overrideWithValue(mockClient),
        ],
        child: const app.MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Enter URL
    final textField = find.byKey(const Key('url_input'));
    expect(textField, findsOneWidget);
    await tester.enterText(textField, 'https://youtube.com/watch?v=123');
    await tester.pumpAndSettle();

    // 2. Click Search
    final actionButton = find.byKey(const Key('action_button'));
    await tester.tap(actionButton);
    
    // Allow animation/api call
    await tester.pump(); // Start request
    await tester.pump(const Duration(milliseconds: 500)); // processing
    await tester.pumpAndSettle(); // Finish animations

    // 3. Verify Video Info Loaded
    expect(find.text('Integration Test Video'), findsOneWidget);
    expect(find.text('Selecione a Qualidade'), findsOneWidget);
    
    // 4. Select Quality (e.g. 720p)
    final qualityChip = find.text('720p');
    await tester.tap(qualityChip);
    await tester.pumpAndSettle();

    // 5. Click Download Button (Same button, text changed, but we use key)
    // Note: In strict integration tests, we might want to check if text changed too.
    expect(find.text('Baixar Agora'), findsOneWidget);
    await tester.tap(actionButton);
    await tester.pump();

    // 6. Simulate Progress via WebSocket
    mockChannel.emit(jsonEncode({
      "status": "downloading", 
      "percentage": 50.0, 
      "speed": "2MB/s", 
      "eta": "10s"
    }));
    
    await tester.pump(); // process stream event
    await tester.pump(const Duration(milliseconds: 100));
    
    // Verify Progress UI
    expect(find.textContaining('50.0%'), findsOneWidget);
    
    // 7. Simulate Finish
    mockChannel.emit(jsonEncode({
      "status": "finished", 
      "filename": "video.mp4"
    }));
    await tester.pump();
    await tester.pumpAndSettle(); 

    // Verify Success
    expect(find.text('Download Concluído!'), findsOneWidget);
  });
}
