# Deliverance

System for reporting and tracking problems with office devices.

- `Deliverance.WebAPI` – ASP.NET Core 9 API
- `Deliverance.Services` – business logic and database (EF Core, SQL Server)
- `Deliverance.Model` – DTOs
- `UI/deliverance_desktop` – Flutter Windows app for admins
- `UI/deliverance_mobile` – Flutter Android app for users
- `UI/deliverance_scout` – Flutter Windows agent that runs on a device and sends its logs and system info to the API

## Requirements

- Docker Desktop
- Flutter SDK
- Android emulator (for the mobile app)
- Visual Studio 2022 with "Desktop development with C++" (for the Windows apps)

## Run the backend

All settings are in `.env` in the repo root.

```
docker compose up -d
```

This starts SQL Server, RabbitMQ, Ollama (chatbot) and the API on `http://localhost:5095`.
On first start the API creates the database and fills it with test data.

## Accounts

| App     | Username  | Password |
|---------|-----------|----------|
| Desktop | `desktop` | `test`   |
| Mobile  | `mobile`  | `test`   |

## Run the apps

From the app folder:

```
flutter pub get
flutter run
```

Default API address:

- Mobile: `http://10.0.2.2:5095/` (Android emulator → your PC)
- Desktop and scout: `http://localhost:5095/`

Use a different address with `--dart-define=API_BASE_URL=http://<ip>:5095/`.

## Build

### Mobile (APK)

```
cd UI/deliverance_mobile
flutter build apk --release
```

Output: `UI/deliverance_mobile/build/app/outputs/flutter-apk/app-release.apk`

The default address `10.0.2.2` only works on the emulator. For a real phone, build with your PC's IP:

```
flutter build apk --release --dart-define=API_BASE_URL=http://<pc-ip>:5095/
```

### Desktop (Windows)

Windows limits paths to 260 characters, and the repo path is too long for a release build.
Build from a copy at a short path (Command Prompt):

```
robocopy "<repo>\UI\deliverance_desktop" "C:\dd\deliverance_desktop" /MIR /XD build .dart_tool ephemeral
cd /d C:\dd\deliverance_desktop
flutter pub get
flutter build windows --release
```

Output: `C:\dd\deliverance_desktop\build\windows\x64\runner\Release\`
Copy the whole `Release` folder; the `.exe` needs the files next to it.
