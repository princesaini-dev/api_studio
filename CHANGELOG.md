## 0.0.1

* Initial release.
* Dio interceptor — captures URL, method, headers, body, query params, form data, multipart, duration, status code, response body, errors.
* Persistent Hive storage — logs survive hot restart, app restart, and app updates.
* Inspector dashboard — paginated list with search, filter (method/status), and sort (newest/oldest/duration/status code).
* Detail view — Overview, Request, Response, and Error tabs.
* Edit & Run engine — modify and re-execute any request; original preserved; new entry marked EDITED.
* CURL generator — generates and copies standard `curl` commands.
* Export — JSON and TXT export via share sheet.
* Theme system — `ApiInspectorThemeData` with `copyWith`, light/dark factories, `InheritedWidget` delivery.
* Clean Architecture — core / domain / data / presentation layers, BLoC state management, SOLID principles.
