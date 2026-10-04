import 'dart:io';

import 'package:api_studio/api_studio.dart';
import 'package:api_studio/src/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers/fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = installFakePathProvider();
    await ApiStudio.initialize();
  });

  tearDownAll(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget wrap(Widget child) => MaterialApp(
        home: ApiInspectorTheme(
          data: const ApiInspectorThemeData(),
          child: child,
        ),
      );

  testWidgets('renders all three navigation tabs', (tester) async {
    await tester.pumpWidget(wrap(const ApiStudioNavigationScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.navLogs), findsOneWidget);
    expect(find.text(AppStrings.navPerformance), findsOneWidget);
    expect(find.text(AppStrings.navFiles), findsOneWidget);
  });

  testWidgets('renders one dashboard awareness strip', (tester) async {
    await tester.pumpWidget(wrap(const ApiStudioNavigationScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.dashboardTitle), findsOneWidget);
    expect(find.text(AppStrings.dashboardSubtitle), findsOneWidget);
    expect(find.byKey(const Key('apiStudioDashboardStrip')), findsOneWidget);
  });

  testWidgets('dashboard strip is tappable', (tester) async {
    await tester.pumpWidget(wrap(const ApiStudioNavigationScreen()));
    await tester.pump();

    await tester.tap(find.byKey(const Key('apiStudioDashboardStrip')));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const Key('apiStudioDashboardStrip')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard strip does not overflow in constrained layouts',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(wrap(const ApiStudioNavigationScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });

  testWidgets('starts on the Logs tab by default', (tester) async {
    await tester.pumpWidget(wrap(const ApiStudioNavigationScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.appTitle), findsOneWidget);
  });

  testWidgets('switching tabs keeps IndexedStack children alive',
      (tester) async {
    await tester.pumpWidget(wrap(const ApiStudioNavigationScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Scope to the IndexedStack that hosts the 3 feature screens, in case
    // Scaffold's internal layout also produces IndexedStack copies (e.g.
    // with `extendBody: true`) sharing the same index/children.
    final indexedStackFinder = find.byWidgetPredicate(
      (widget) => widget is IndexedStack && widget.children.length == 3,
    );
    expect(indexedStackFinder, findsWidgets);

    IndexedStack indexedStack =
        tester.widgetList<IndexedStack>(indexedStackFinder).first;
    expect(indexedStack.index, 0);
    expect(indexedStack.children.length, 3);

    await tester.tap(find.text(AppStrings.navPerformance));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    indexedStack = tester.widgetList<IndexedStack>(indexedStackFinder).first;
    expect(indexedStack.index, 1);
    // Same 3 children instances are still mounted — no rebuild/recreation.
    expect(indexedStack.children.length, 3);

    await tester.tap(find.text(AppStrings.navFiles));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    indexedStack = tester.widgetList<IndexedStack>(indexedStackFinder).first;
    expect(indexedStack.index, 2);
  });

  testWidgets('ApiStudio.showNavigation opens the navigation screen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ApiStudio.showNavigation(context),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ApiStudioNavigationScreen), findsOneWidget);
    expect(find.text(AppStrings.navLogs), findsOneWidget);
  });
}
