## 1.0.2

### Fixed
- Relaxed `meta` constraint from `^1.18.3` to `^1.12.0` so `flutter pub add flod` works with Flutter's SDK-pinned `meta` (e.g. `1.18.0`) without `dependency_overrides`.

## 1.0.1

### Fixed
- Escaped angle brackets in doc comment (`lib/flod.dart`) that were being interpreted as HTML, causing a static analysis info-level warning on pub.dev.