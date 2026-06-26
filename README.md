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