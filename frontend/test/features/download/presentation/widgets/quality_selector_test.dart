
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vids_frontend/features/download/presentation/widgets/quality_selector.dart';
import 'package:vids_frontend/core/theme/app_colors.dart';

void main() {
  testWidgets('QualitySelector renders correctly', (WidgetTester tester) async {
    // Arrange
    final qualities = [360, 720, 1080];
    int selected = 720;
    int? newSelected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QualitySelector(
            qualities: qualities,
            selectedQuality: selected,
            onSelected: (val) {
              newSelected = val;
            },
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('360p'), findsOneWidget);
    expect(find.text('720p'), findsOneWidget);
    expect(find.text('1080p'), findsOneWidget);
    
    // Check if 720p is selected (has check icon)
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    
    // Act
    await tester.tap(find.text('1080p'));
    await tester.pump();

    // Assert callback
    expect(newSelected, 1080);
  });
  
  testWidgets('QualitySelector hidden when empty', (WidgetTester tester) async {
      await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QualitySelector(
            qualities: const [],
            selectedQuality: 0,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    
    expect(find.byType(Column), findsNothing);
  });
}
