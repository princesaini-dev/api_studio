# AGENTS.md

Project notes for coding agents working on API Studio.

## Layout

- `/` — core package `api_studio` (published to pub.dev).
- `packages/api_studio_dio` — Dio interceptor companion package.
- `packages/api_studio_http` — `package:http` client companion package.
  Both resolve `api_studio` from the repo via `pubspec_overrides.yaml`.
- `example/` — runnable demo app (uses both companions via path deps).

## Verify changes

Run from the repo root (and repeat analyze/test in each `packages/*` dir):

```bash
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test packages example/lib
dart pub publish --dry-run   # fails only on a dirty git tree locally
```

CI: `.github/workflows/ci.yml` runs analyze/test/dry-run for all three
packages on the minimum (3.27.x) and latest stable Flutter.

## Architecture rules

- Every capture path (`ApiStudio.log`, interceptors, `ApiStudioClient`,
  Edit & Run) must go through `LogPipeline.record`
  (`lib/src/core/pipeline/log_pipeline.dart`): redact → truncate → store →
  notify → upload. Never write to the repository or `ApiStudioRemoteLogger`
  directly.
- `ApiStudioRuntime.enabled` is the master switch; anything new that
  creates storage, timers, frame callbacks, network calls or UI must check
  it (see `test/unit/disabled_mode_test.dart`).
- Exports (cURL, JSON, TXT, HAR, Postman) must re-apply
  `ApiStudioRuntime.redactor`.
- Storage is `hive_ce`, boxes opened with an explicit `path:` (never call
  `Hive.init`). Schema changes: bump `LogStorageMigrator.currentSchemaVersion`
  and add a migration step; the Hive adapter is hand-written and must stay
  tolerant of missing fields.
- Tests touching `ApiStudio.initialize` must install
  `test/test_helpers/fake_path_provider.dart` and override the remote client
  with `RecordingSimpleHttpClient` (no real network in tests). State is
  static, so each such test file runs in its own isolate.
