# journal_trend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Flutter Firebase Configuration

Check if flutter is normal:

```bash
flutter doctor
```

Install Firebase-CLI:

```bash
npm i -g firebase-tools
```

Login:

```bash
firebase login
```

Check flutterfire installation:

```bash
flutterfire --version
```

Install flutterfire:

```bash
dart pub global activate flutterfire_cli
```

## Check flutterfire
```bash
flutterfire --version
```
If you get:
```bash
'flutterfire' is not recognized as an internal or external command...
```

Press Win and search for "Edit the system environment variables".
Click Environment Variables...
Under User variables for [Your Username], select Path → Edit.

Click New and paste:

C:\Users\YourUsername\AppData\Local\Pub\Cache\bin (You should get this in the warning when install flutterfire)
Click OK on all dialogs.
Close all Command Prompt/PowerShell windows and open a new one and re-check.


Open the project, add dependencies if needed (already added in this project):

```bash
flutter pub add firebase_core
flutter pub add firebase_auth
flutter pub add google_sign_in
flutter pub add firebase_storage
flutter pub add firebase_messaging
flutter pub add firebase_analytics
flutter pub add firebase_crashlytics
flutter pub add firebase_remote_config
```

Get dependencies:
```bash
flutter pub get
```

## Running Integration Tests (Patrol)

This project uses [Patrol](https://patrol.leancode.co/) for integration/E2E testing. Tests live in the `integration_test/` directory.

### Prerequisites

Install `patrol_cli` globally (must be compatible with the `patrol` version in `pubspec.yaml`, currently `4.6.x`):

```bash
dart pub global activate patrol_cli
```

Check the [compatibility table](https://patrol.leancode.co/documentation/compatibility-table) if you see a version mismatch error.

The `patrol:` config block in `pubspec.yaml` tells the CLI where tests live:

```yaml
patrol:
  app_name: journal_trend
  test_directory: integration_test
```

### Run all tests

```bash
patrol test
```

### Run a specific test file

```bash
patrol test -t integration_test/authentication_test.dart
```

### Run on web (Chrome/Edge)

When prompted, select the Chrome or Edge device. Web test runs require Node.js and Playwright, which `patrol_cli` installs automatically on first run:

```bash
patrol test -t integration_test/authentication_test.dart
```

If you hit a Node.js/Playwright config error on web, try reinstalling the CLI's bundled web runner dependencies:

```bash
cd %LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\patrol-<version>\web_runner
rmdir /s /q node_modules
del package-lock.json
npm cache clean --force
npm install
npx playwright install
```

### Run on a specific platform

```bash
patrol test -t integration_test/authentication_test.dart -d chrome    # Web (Chrome)
patrol test -t integration_test/authentication_test.dart -d <device-id>   # Android/iOS emulator or device
```

### Troubleshooting

- **`patrol_cli` version incompatible with `patrol` package**: activate a matching `patrol_cli` version (see compatibility table above).
- **`Bad state: This dispose scope is already disposed`**: known `patrol_cli` bug triggered by pressing `Ctrl+C` more than once. Kill the terminal/process and re-run instead of spamming `Ctrl+C`.
- **`SyntaxError` in `playwright.config.ts`**: usually a corrupted/partial npm install in the CLI's `web_runner` folder. Reinstall as shown above.