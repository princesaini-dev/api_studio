import 'dart:io';

import 'package:api_studio/api_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers/fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = installFakePathProvider();
    await ApiStudio.initialize(enabled: true);
  });

  tearDownAll(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  // The inspector shows a repeating loading animation, so pumpAndSettle
  // would never return; pump past the 250ms route transition instead.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Widget app() => MaterialApp(
        navigatorKey: ApiStudio.navigatorKey,
        home: const Scaffold(body: Text('home')),
      );

  testWidgets('open() uses navigatorKey, no BuildContext needed',
      (tester) async {
    await tester.pumpWidget(app());

    ApiStudio.open();
    await settle(tester);
    expect(find.byType(ApiStudioNavigationScreen), findsOneWidget);

    // A second open() while already open does not stack another screen.
    ApiStudio.open();
    await settle(tester);
    expect(find.byType(ApiStudioNavigationScreen), findsOneWidget);

    ApiStudio.navigatorKey.currentState!.pop();
    await settle(tester);
    expect(find.byType(ApiStudioNavigationScreen), findsNothing);
  });

  testWidgets('floating button opens API Studio and can be hidden',
      (tester) async {
    await tester.pumpWidget(app());

    ApiStudio.showFloatingButton();
    await tester.pump();
    final button = find.byKey(const Key('apiStudioFloatingButton'));
    expect(button, findsOneWidget);
    expect(ApiStudio.isFloatingButtonVisible, isTrue);

    // Showing twice does not insert a second button.
    ApiStudio.showFloatingButton();
    await tester.pump();
    expect(button, findsOneWidget);

    // Dragging keeps it on screen.
    await tester.drag(button, const Offset(-5000, -5000));
    await tester.pump();
    final pos = tester.getTopLeft(button);
    expect(pos.dx, greaterThanOrEqualTo(0));
    expect(pos.dy, greaterThanOrEqualTo(0));

    await tester.tap(button);
    await settle(tester);
    expect(find.byType(ApiStudioNavigationScreen), findsOneWidget);

    ApiStudio.navigatorKey.currentState!.pop();
    await settle(tester);

    ApiStudio.hideFloatingButton();
    await tester.pump();
    expect(button, findsNothing);
    expect(ApiStudio.isFloatingButtonVisible, isFalse);
  });

  testWidgets('showFloatingButton(context) works without navigatorKey',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => ApiStudio.showFloatingButton(context),
          child: const Text('show'),
        ),
      ),
    ));
    await tester.tap(find.text('show'));
    await tester.pump();
    expect(find.byKey(const Key('apiStudioFloatingButton')), findsOneWidget);
    ApiStudio.hideFloatingButton();
    await tester.pump();
  });
}
