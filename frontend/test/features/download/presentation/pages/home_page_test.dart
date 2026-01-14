import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vids_frontend/features/download/presentation/pages/home_page.dart';
import 'package:vids_frontend/features/download/presentation/providers/download_provider.dart';
import 'package:vids_frontend/features/download/presentation/widgets/quality_selector.dart';
import 'package:vids_frontend/shared/widgets/primary_button.dart';
import 'package:vids_frontend/features/download/data/datasources/download_api_client.dart';

// Create a simple Mock Client manually to avoid build_runner dependency in this quick fix
class MockDownloadApiClient extends Mock implements DownloadApiClient {
  @override
  Future<Map<String, dynamic>> getVideoInfo(String? url) async {
    // Return dummy data
    return {
      'title': 'Test Video',
      'thumbnail': 'http://img.com/1.jpg',
      'uploader': 'Test Channel',
      'qualities': [
        {'height': 720, 'filesize': 1000},
        {'height': 480, 'filesize': 500}
      ],
      'audio_filesize': 100
    };
  }
}

void main() {
  late MockDownloadApiClient mockClient;

  setUp(() {
    mockClient = MockDownloadApiClient();
  });

  testWidgets('HomePage renders initial state correctly', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomePage(),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(PrimaryButton), findsOneWidget);
  });

  // More complex tests involving provider state changes require careful mocking of the Notifier
  // or the underlying client. Since we are overriding the client provider, let's try a full flow.

  testWidgets('HomePage shows quality selector after fetching info', (tester) async {
    // Override the provider with our mock client
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadApiClientProvider.overrideWithValue(mockClient),
        ],
        child: const MaterialApp(
          home: HomePage(),
        ),
      ),
    );

    // Enter URL
    await tester.enterText(find.byType(TextField), 'http://youtube.com/watch?v=123');
    await tester.pump();

    // Tap Download/Search Button
    await tester.tap(find.byKey(const Key('action_button')));

    // Pump to start the future
    await tester.pump();
    // Pump to finish the future (simulated)
    await tester.pump(const Duration(seconds: 1));

    // Verify if QualitySelector appeared
    // Note: If the logic inside fetchVideoInfo fails or the mock isn't called, this will fail.
    // Given the previous failure, let's debug if we find the selector.

    // If logic is async, pumpAndSettle might be needed.
    await tester.pumpAndSettle();

    expect(find.text('Test Video'), findsOneWidget);
    expect(find.byType(QualitySelector), findsOneWidget);
  });
}
