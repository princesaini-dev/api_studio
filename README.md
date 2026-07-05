
<h1 align="center">API Studio</h1>

<p align="center">
Build • Debug • Monitor • Analyze APIs from a Single Toolkit
</p>

<p align="center">

[![pub package](https://img.shields.io/pub/v/api_studio.svg)](https://pub.dev/packages/api_studio)
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Android%20|%20iOS%20|%20Web-success)
![License](https://img.shields.io/badge/License-MIT-blue)

</p>

---

## 🚀 Overview

API Studio is a modern networking toolkit built exclusively for Flutter developers.

It combines networking, debugging, monitoring, request inspection, connectivity tracking, and developer utilities into one clean and easy-to-use package.

Whether you're building a personal project or a production application, API Studio provides everything needed to understand, debug, and manage your application's network layer.

---

## ✨ Why API Studio?

Modern applications require much more than simply sending HTTP requests.

API Studio provides an integrated developer experience that allows you to:

- 🌐 Send network requests
- 📡 Automatically inspect every request
- 📊 Monitor API traffic
- 📱 View beautiful request details
- 🌍 Track internet connectivity
- 📈 Monitor failed requests in real time
- 📝 Generate cURL commands instantly
- 📤 Export request history
- ⚡ Edit and retry requests
- 🔍 Analyze request performance

Everything works together with minimal setup.

---

## 🌐 Networking

- Built-in HTTP Client
- GET
- POST
- PUT
- PATCH
- DELETE
- Multipart Upload
- File Download
- Custom Headers
- Query Parameters
- Authorization Support
- Request Timeout
- Retry Requests
- Base URL Configuration

---

## 📡 Automatic API Interceptor

Every request is captured automatically.

Captured information includes:

- URL
- Method
- Headers
- Request Body
- Query Parameters
- Response
- Status Code
- Response Time
- Error Details
- Stack Trace

No additional configuration required.

---

## 📱 API Inspector

Professional API debugging interface with:

- Search Requests
- Filter by Method
- Filter by Status
- Request Details
- Response Viewer
- Error Viewer
- JSON Formatter
- Copy Request
- Delete Logs
- Edit & Retry
- Generate cURL

---

## 🌍 Internet Monitoring

Monitor application connectivity in real time.

Features include:

- Current Internet Status
- Internet Status Stream
- Connectivity Listener
- Live Updates

---

## 📈 Live Streams

Built-in streams for:

- Internet Connectivity
- Failed API Count
- Request Updates

Perfect for dashboards and debugging.

---

## 📝 cURL Generator

Generate production-ready cURL commands with one click.

Useful for:

- Backend Teams
- QA Testing
- API Sharing
- Terminal Testing

---

## 📤 Export Logs

Export request history as:

- JSON
- PDF

---

## ⚡ Edit & Retry

Modify intercepted requests directly from the inspector.

Update:

- Headers
- Query Parameters
- Request Body

Retry instantly without changing application code.

---

## 📸 Screenshots

<p align="center">
  <img src="assets/ss1.png" width="32%">
  <img src="assets/ss2.png" width="32%">
  <img src="assets/ss3.png" width="32%">
</p>

<p align="center">
  <img src="assets/ss4.png" width="32%">
  <img src="assets/ss5.png" width="32%">
</p>

---

## 📦 Installation

Add the package to your project.

```yaml
dependencies:
  api_studio: ^0.1.1
```

Install packages.

```bash
flutter pub get
```

---

## 🚀 Quick Start

Initialize API Studio.

```dart
await ApiStudio.initialize();
```

---

## 🌐 HTTP Client

Create a client.

```dart
final client = ApiStudioClient();
```

GET Request

```dart
final response = await client.get("/posts");
```

POST Request

```dart
await client.post(
  "/login",
  data: {
    "email": "john@example.com",
    "password": "123456",
  },
);
```

PUT Request

```dart
await client.put("/users/1");
```

DELETE Request

```dart
await client.delete("/users/1");
```

Every request is automatically available inside the API Inspector.

---

## 📱 Open API Inspector

```dart
ApiInspector.show(context);
```

Inspect every request in real time.

---

## 🌍 Internet Connectivity

Current connectivity status.

```dart
ApiStudio.internetStatus
```

Listen continuously.

```dart
ApiStudio.internetStream.listen((status) {

});
```

---

## 📈 Failed API Stream

```dart
ApiStudio.failedApiCountStream.listen((count) {

});
```

Perfect for dashboards and monitoring widgets.

---

## ✅ Supported HTTP Methods

- GET
- POST
- PUT
- PATCH
- DELETE
- HEAD
- OPTIONS

---

## 🎯 Features

- Built-in HTTP Client
- Automatic API Interceptor
- API Inspector UI
- Request & Response Viewer
- Error Viewer
- JSON Formatter
- Edit & Retry
- cURL Generator
- Internet Monitoring
- Live Internet Stream
- Failed API Stream
- Export Logs

---

## 📄 License

MIT License

---

<p align="center">

Made with ❤️ for the Flutter Community

</p>