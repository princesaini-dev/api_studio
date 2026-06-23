# API Studio

<p align="center">
  <img src="assets/ss3.png" width="220" alt="Inspector List"/>
  <img src="assets/ss2.png" width="220" alt="Response Tab"/>
  <img src="assets/ss6.png" width="220" alt="Edit & Run"/>
</p>

<p align="center">
  <a href="https://pub.dev/packages/api_studio"><img src="https://img.shields.io/pub/v/api_studio.svg" alt="pub version"/></a>
  <a href="https://pub.dev/packages/api_studio"><img src="https://img.shields.io/pub/points/api_studio" alt="pub points"/></a>
  <a href="https://github.com/princesaini-dev/api_studio/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"/></a>
  <img src="https://img.shields.io/badge/Flutter-3.19%2B-02569B?logo=flutter" alt="Flutter 3.19+"/>
  <img src="https://img.shields.io/badge/Dart-3.3%2B-0175C2?logo=dart" alt="Dart 3.3+"/>
</p>

A powerful **in-app API debugging and inspection tool** for Flutter — like Charles Proxy, Chucker, and Alice — built specifically for [Dio](https://pub.dev/packages/dio).

Zero configuration. Drop it in, add one interceptor, and every HTTP request your app makes is captured, stored, and browsable — without leaving the app. Go further with **Slack failure alerts**, **live internet connectivity monitoring**, and **real-time failed API counters** — all opt-in with a single flag.

---

## ✨ Features at a Glance

| | Feature | Description |
|---|---|---|
| 🔍 | **Auto-capture** | Intercepts all Dio requests — URL, method, headers, body, query params, form data, multipart |
| 💾 | **Persistent logs** | Powered by Hive — logs survive hot restart, app restart, and device reboots |
| 📊 | **Inspector dashboard** | Search, filter by method/status, sort — handles 10,000+ logs smoothly |
| 🗂 | **Detail view** | Overview / Request / Response / Error tabs with copy buttons on every section |
| ✏️ | **Edit & Run** | Modify any captured request and re-execute it — original log is never mutated |
| 🧾 | **CURL generator** | One tap to copy or share any request as a `curl` command |
| 📤 | **Export** | Export all logs as JSON or TXT and share via the system share sheet |
| 🎨 | **Themeable** | Full light/dark support + `ApiInspectorThemeData` for custom colors and radius |
| 🔔 | **Slack Alerts** | Push rich failure alerts to a Slack channel via Incoming Webhooks — zero extra packages |
| 🌐 | **Internet stream** | Opt-in broadcast stream that emits `true`/`false` on every connectivity change |
| 📉 | **Failed API counter** | Opt-in live count + stream of all failed requests — drive a badge on your debug menu |
| 🔐 | **Sensitive data masking** | Auth headers, tokens, passwords, and API keys are automatically redacted before any alert is sent |
| ⚙️ | **Configurable init** | Control `maxStoredLogs`, `requestTimeout`, connectivity stream, and failed-count stream from `init()` |

---

## Screenshots

<p align="center">
  <img src="assets/ss3.png" width="180" alt="Dashboard"/>
  <img src="assets/ss1.png" width="180" alt="Request Tab"/>
  <img src="assets/ss2.png" width="180" alt="Response Tab"/>
</p>
<p align="center">
  <img src="assets/ss5.png" width="180" alt="Error Tab"/>
  <img src="assets/ss4.png" width="180" alt="CURL Command"/>
  <img src="assets/ss6.png" width="180" alt="Edit & Run"/>
</p>

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  api_studio: ^0.0.1
```

Then run:

```sh
flutter pub get
```

---

## Quick Start

### Step 1 — Initialise before `runApp`

```dart
import 'package:api_studio/api_studio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiStudio.init();
  runApp(const MyApp());
}
```

### Step 2 — Add the interceptor to your Dio instance

```dart
final dio = Dio();
dio.interceptors.add(ApiStudio.interceptor);
```

### Step 3 — Open the inspector

Trigger it from any button, FAB, or shake gesture:

```dart
ApiStudio.show(context);
```

That's it. Every request made through that `Dio` instance is now captured and browsable.

---

## Full Example

```dart
import 'package:api_studio/api_studio.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiStudio.init();

  final dio = Dio();
  dio.interceptors.add(ApiStudio.interceptor);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('My App'),
          actions: [
            IconButton(
              icon: const Icon(Icons.bug_report_rounded),
              onPressed: () => ApiStudio.show(context),
            ),
          ],
        ),
      ),
    );
  }
}
```

See the complete working example in the [`/example`](example/) folder.

---

## Configuration

All parameters are optional — sensible defaults apply if not provided.

```dart
await ApiStudio.init(
  // Maximum number of logs retained on disk (oldest pruned automatically)
  maxStoredLogs: 500,                          // default: 10,000

  // Timeout applied to re-run requests from Edit & Run
  requestTimeout: Duration(seconds: 15),       // default: 30s

  // Enable the internet connectivity broadcast stream
  enableConnectivityStream: true,              // default: false

  // Enable the failed API count stream
  enableFailedApiStream: true,                 // default: false

  // Slack + callback alert configuration
  notificationConfig: NotificationConfig(
    slackWebhook: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL',
    onApiFailed: (log) => debugPrint('API failed: ${log.url}'),
  ),

  // Custom theme
  theme: ApiInspectorThemeData(
    primaryColor: Colors.teal,
    borderRadius: 16,
  ),
);
```

---

## 🔔 Slack Failure Alerts

API Studio can push a rich, structured alert to any Slack channel the moment an API call fails — no third-party packages required.

### Setup

1. Create a [Slack Incoming Webhook](https://api.slack.com/messaging/webhooks) for your workspace.
2. Pass the webhook URL through `NotificationConfig` in `init()`:

```dart
await ApiStudio.init(
  notificationConfig: NotificationConfig(
    slackWebhook: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL',
  ),
);
```

### What each alert includes

| Field | Description |
|---|---|
| **Method** | HTTP verb (GET, POST, PUT, DELETE, …) |
| **Endpoint** | Path extracted from the full URL |
| **Status code** | HTTP response code, or `N/A` for network errors |
| **Duration** | Request round-trip time in ms or seconds |
| **Error message** | Truncated to 300 characters to keep alerts readable |
| **Internet** | Whether the device was online at failure time |
| **Timestamp** | Exact date and time of the failure |
| **App / platform / device** | App version, OS, and device model |

### Sensitive data protection

All alerts are scrubbed automatically before dispatch:

- Request headers containing `Authorization`, `Cookie`, `token`, `api-key`, `secret`, `jwt`, and 30+ other keys are replaced with `***`
- Bearer tokens, Basic auth strings, JWTs, and long API keys are detected by pattern and masked
- Request/response body fields such as `password`, `otp`, `token`, `secret`, and `refresh_token` are redacted from JSON payloads

**Your secrets never leave the device in plain text.**

### Custom callback

Register an `onApiFailed` callback alongside (or instead of) Slack to handle failures in your own way:

```dart
notificationConfig: NotificationConfig(
  onApiFailed: (ApiLogNotificationModel log) {
    // Send to Firebase Crashlytics, Sentry, your own backend, etc.
    FirebaseCrashlytics.instance.log('API failed: ${log.url} — ${log.statusCode}');
  },
),
```

> **Teams support is coming** — Microsoft Teams webhook integration will be added in the next release.

---

## 🌐 Internet Connectivity Stream

Enable a lightweight polling-based connectivity monitor that broadcasts `true`/`false` whenever the device's internet state changes. No external plugin needed — works on all platforms.

```dart
await ApiStudio.init(
  enableConnectivityStream: true,
);
```

### One-time check

```dart
final bool isOnline = await ApiStudio.isInternetConnected();
```

### Live stream

```dart
ApiStudio.internetConnectivityStream.listen((bool isConnected) {
  if (!isConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No internet connection')),
    );
  }
});
```

The stream emits only on **state changes** (online → offline or offline → online), so listeners are not flooded with redundant events.

---

## 📉 Failed API Count

Track the running total of failed requests in real time. Useful for displaying a badge on your debug menu or triggering alerts after a threshold is crossed.

```dart
await ApiStudio.init(
  enableFailedApiStream: true,
);
```

### Synchronous snapshot

```dart
final int count = ApiStudio.failedApiCount;
```

### Reactive stream

```dart
ApiStudio.failedApiCountStream.listen((int failedCount) {
  setState(() => _badgeCount = failedCount);
});
```

### Badge example

```dart
StreamBuilder<int>(
  stream: ApiStudio.failedApiCountStream,
  builder: (context, snapshot) {
    final count = snapshot.data ?? 0;
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: IconButton(
        icon: const Icon(Icons.bug_report_rounded),
        onPressed: () => ApiStudio.show(context),
      ),
    );
  },
)
```

---

## Theming

```dart
// Light (default)
const ApiInspectorThemeData()

// Dark
ApiInspectorThemeData.dark()

// Match the app's brightness automatically
ApiInspectorThemeData.fromBrightness(Theme.of(context).brightness)

// Fully custom
ApiInspectorThemeData(
  primaryColor: Color(0xFF6C63FF),
  backgroundColor: Colors.white,
  surfaceColor: Colors.white,
  cardColor: Colors.white,
  borderRadius: 12.0,
  isDark: false,
)
```

Pass a theme per `show()` call to override the init-time theme for that session only:

```dart
ApiStudio.show(
  context,
  theme: ApiInspectorThemeData.dark(),
);
```

---

## Edit & Run

Open any captured request → tap the **pencil icon** → **Edit & Run**:

1. All fields are pre-filled with the original request data
2. Modify URL, HTTP method, headers, query params, or body
3. Tap **RUN** — a new log is created and tagged with an **EDITED** badge
4. The original log is never modified

---

## Architecture

Built with Clean Architecture + SOLID principles:

```
lib/src/
├── core/           ← Constants, errors, extensions, use-case base, utils
├── domain/         ← Entities, repository interfaces, use cases (pure Dart)
├── data/           ← Hive models, TypeAdapter, datasource, repo impl, interceptor
├── presentation/   ← BLoC × 4, screens × 3, widgets × 7
├── theme/          ← ApiInspectorTheme, AppColors, AppTextStyles, Dimensions
├── notification/   ← NotificationConfig, SlackProvider, NotificationService, SensitiveDataMasker
└── services/       ← DiService (DI wiring), ConnectivityService, FailedApiCountService, ExportService
```

| Concern | Solution |
|---|---|
| State management | `flutter_bloc` — feature-scoped BLoCs, Equatable states |
| Storage | Hive + generated TypeAdapter, 10k+ logs with pagination |
| Performance | `ListView.builder`, `RepaintBoundary` per card, `buildWhen` guards |
| Interception | Dio `Interceptor` — captures request / response / error phases |
| CURL export | Pure Dart utility, zero extra dependencies |
| Theming | `InheritedWidget`-based `ApiInspectorTheme` |
| Slack alerts | `dart:io` `HttpClient` — no third-party HTTP package |
| Connectivity | Polling-based, platform-conditional implementation (native vs. web) |
| Sensitive data | Pattern + key-list based masker applied before every notification dispatch |

---

## Requirements

| | Minimum |
|---|---|
| Flutter | 3.19+ |
| Dart | 3.3+ |
| Dio | 5.x |
| Platforms | Android, iOS, macOS, Linux, Windows, Web |

---

## Running the Example App

```sh
cd example
flutter pub get
flutter run
```

Tap the **bug icon** (🐛) in the app bar to open the inspector.

---

## Running Tests

```sh
flutter test
```

After changing the Hive model, regenerate the adapter:

```sh
dart run build_runner build --delete-conflicting-outputs
```

---

## Roadmap

- [x] Dio interception & persistent Hive storage
- [x] Inspector dashboard — search, filter, sort
- [x] Edit & Run with EDITED badge
- [x] CURL generator & JSON/TXT export
- [x] Slack failure alerts with sensitive data masking
- [x] Internet connectivity stream
- [x] Failed API count stream
- [ ] Microsoft Teams webhook alerts *(coming next)*
- [ ] Shake-to-open gesture support

---

## Contributing

- Follow the existing Clean Architecture layering — keep the domain layer free of Flutter/Hive imports
- Keep the notification layer provider-agnostic — new providers implement `NotificationProvider` and are registered in `NotificationService`
- File bugs via the [issue tracker](https://github.com/princesaini-dev/api_studio/issues)
- PRs welcome

---

## License

MIT
