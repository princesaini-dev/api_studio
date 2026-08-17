# API Studio Example

A demo app showcasing the **API Studio** Flutter package — an in-app API debugging and inspection tool.

## Features

- **API Inspector** — view, search, filter, and inspect all HTTP requests logged by the app
- **Edit & Run** — modify and re-execute any logged request
- **cURL Export** — generate cURL commands for any request
- **File Explorer** — browse app files and folders with lightweight file management:
  - Navigate folders with breadcrumb support
  - Open files externally via the platform's default handler
  - Download files to the device's Downloads folder (with confirmation dialog)
  - No internal file viewing — all file opening is delegated to the platform

## Getting Started

```bash
cd example
flutter pub get
flutter run
```

Tap the folder icon in the app bar to open the File Explorer.
