import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vids_frontend/features/download/presentation/providers/download_provider.dart';
import 'package:vids_frontend/features/download/data/datasources/download_api_client.dart';
import 'package:flutter/services.dart';

// Generate mocks manually or via build_runner if configured.
// For this quick fix, we use basic extending or simple mocks if possible without build_runner wait.
// But project has build_runner. Let's try to trust build_runner presence or simplistic mock.
// User wants to run tests, so we should probably implement a test that doesn't rely on complex platform mocks if possible,
// or mock the channel correctly.

class MockDownloadApiClient extends Mock implements DownloadApiClient {
  @override
  Future<Map<String, dynamic>> getVideoInfo(String? url) async {
    return {
      'title': 'Test Video',
      'qualities': [{'height': 720, 'filesize': 1024}],
      'audio_filesize': 512
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '.';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });

  // Mock permission_handler channel
  const MethodChannel permissionChannel = MethodChannel('flutter.baseflow.com/permissions/methods');
  setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      permissionChannel,
      (MethodCall methodCall) async {
          // Return granted (1) for all checks request
          // Enum values map to integers usually.
          // For simplicity in unit test often better to skip platform calls if logic allows,
          // but logic calls them directly.
          return {
             16: 1 // PermissionStatus.granted
          };
      },
    );
  });


  test('DownloadNotifier fetchVideoInfo updates state to DownloadInfoLoaded', () async {
    final mockClient = MockDownloadApiClient();
    final container = ProviderContainer(
      overrides: [
        downloadApiClientProvider.overrideWithValue(mockClient),
      ],
    );

    final notifier = container.read(downloadProvider.notifier);

    // Initial state
    expect(container.read(downloadProvider), isA<DownloadInitial>());

    // Fetch
    await notifier.fetchVideoInfo('http://test.com');

    // Verify
    expect(container.read(downloadProvider), isA<DownloadInfoLoaded>());
    final state = container.read(downloadProvider) as DownloadInfoLoaded;
    expect(state.info['title'], 'Test Video');
  });
}
