/// Best-effort, dependency-free description of the device and OS, attached
/// to every log uploaded to the API Studio cloud. Internal.
library;

export 'device_context_io.dart'
    if (dart.library.js_interop) 'device_context_web.dart';
