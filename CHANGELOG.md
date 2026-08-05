## 1.0.0

### ✨ Added
- `ApiStudio.initialize({ apiKey })` — optional automatic API execution logging to the API Studio backend
- Fire-and-forget remote logging that never blocks, delays or affects user requests
- Sensitive headers (`Authorization`, `Cookie`, `Set-Cookie`, `X-API-Key`, `Proxy-Authorization`) are stripped before upload
- Recursive-logging protection: requests to the API Studio logging backend are never logged
- Single-line console output on log upload success/failure (no bodies, headers or API keys ever printed)

### 🚀 Improved
- Improved API Inspector UI
- Enhanced request details screen
- Better cURL generation
- Improved JSON formatting
- Better README documentation
- Updated screenshots
- General performance and stability improvements

### 🛠 Fixed
- Minor bug fixes and UI improvements