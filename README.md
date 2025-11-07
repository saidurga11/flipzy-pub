# Flipzy

A mobile game monorepo with Rust backend and Flutter client, optimized for Android.

## Project Structure

```
flipzy/
├── server/          # Rust backend server (Tokio + Axum)
├── client/          # Flutter mobile client (Flame + Riverpod)
└── docker-compose.yml
```

## Prerequisites

- **Rust**: >= 1.70 ([Install Rust](https://rustup.rs/))
- **Flutter**: >= 3.7 stable ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Docker & Docker Compose**: For running infrastructure ([Install Docker](https://docs.docker.com/get-docker/))
- **Android Studio**: For Android development ([Install Android Studio](https://developer.android.com/studio))
  - Android SDK (API 24+)
  - Android Emulator or physical device

## Android-Specific Setup

This project is optimized for Android mobile development with the following configurations:

### Device Requirements
- Minimum SDK: 24 (Android 7.0 Nougat)
- Target SDK: 34 (Android 14)
- Portrait orientation locked

### Automatic Network Configuration
The app automatically detects Android and uses the correct API endpoint:
- **Android Emulator**: `http://10.0.2.2:8080` (auto-configured)
- **Physical Device**: Configure network to access host machine
- **iOS/Other**: `http://localhost:8080`

### Mobile Features
- Portrait-only orientation for optimal game experience
- SafeArea handling for notched devices
- Touch-optimized UI with 50dp minimum touch targets
- Transparent status bar with proper icon colors
- Internet and network state permissions configured

## Quick Start

### 1. Start the Backend Infrastructure

Start PostgreSQL, Redis, and the Rust server using Docker Compose:

```bash
docker-compose up --build
```

This will:
- Start PostgreSQL on port 5432
- Start Redis on port 6379
- Build and start the Flipzy server on port 8080

The server will be available at `http://localhost:8080`

### 2. Run the Flutter Client (Android)

In a separate terminal:

```bash
cd client
flutter pub get
```

**Option A: Android Emulator (Recommended for Development)**
```bash
# List available devices
flutter devices

# Run on Android emulator
flutter run -d emulator-5554
# Or simply
flutter run
```

**Option B: Physical Android Device**
1. Enable Developer Options and USB Debugging on your device
2. Connect via USB
3. Accept the connection prompt on your device
4. Run:
```bash
flutter run
```

The app will:
- Automatically connect to `http://10.0.2.2:8080` on Android emulator
- Display "Flipzy — Connected to backend" when successful
- Lock to portrait orientation
- Show a mobile-optimized UI

## Development

### Backend Server (Rust)

#### Local Development

```bash
cd server
make dev
```

This runs the server with hot-reloading using cargo watch (if installed).

#### Run Tests

```bash
cd server
make test
```

#### Environment Variables

The server uses the following environment variables (defined in `server/.env`):

- `PORT`: Server port (default: 8080)
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `JWT_SECRET`: Secret key for JWT signing (default: flipzy-dev-secret)

#### Available Endpoints

- `GET /health` - Health check endpoint
  - Returns: `{"status": "ok", "service": "flipzy-server"}`

- `POST /auth/guest` - Guest authentication
  - Body: `{"name": "optional-name"}`
  - Returns: `{"token": "<jwt>", "user_id": "u-<uuid>"}`
  - Token expires in 24 hours

### Flutter Client (Android)

#### Building for Release

```bash
cd client

# Build APK for distribution
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release

# Build and install debug APK
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

#### Running on Different Targets

```bash
# Android (primary target)
cd client
flutter run -d android

# Specific device
flutter run -d <device-id>

# Release mode
flutter run --release
```

#### Configuration

The API endpoint is configured in `client/lib/config.dart` with automatic platform detection:
- **Android**: Automatically uses `http://10.0.2.2:8080` for emulator
- **Others**: Defaults to `http://localhost:8080`

To override the API endpoint:

```bash
# For production server
flutter run --dart-define=API_ENDPOINT=http://your-production-server:8080

# For physical device accessing local network
flutter run --dart-define=API_ENDPOINT=http://192.168.1.100:8080
```

#### Android-Specific Configuration Files

- `android/app/src/main/AndroidManifest.xml` - Permissions and app config
- `android/app/build.gradle` - Build settings (minSdk: 24, targetSdk: 34)
- `android/build.gradle` - Project-level dependencies
- `android/gradle.properties` - Gradle JVM settings

#### Dependencies

- **Flame**: Game engine for Flutter
- **Riverpod**: State management
- **http**: HTTP client for API calls

## Testing

### Server Integration Tests

```bash
cd server
cargo test --test integration_test
```

This will start a test server and verify that:
- The `/health` endpoint returns 200 OK
- The `/auth/guest` endpoint creates valid JWT tokens

### Client Tests

```bash
cd client
flutter test
```

## Docker

### Build Server Image

```bash
docker build -t flipzy-server ./server
```

### Run Full Stack

```bash
docker-compose up --build
```

### Stop All Services

```bash
docker-compose down
```

### Clean Up Volumes

```bash
docker-compose down -v
```

## Project Details

### Backend Stack

- **Rust**: Systems programming language
- **Tokio**: Async runtime
- **Axum**: Web framework
- **PostgreSQL**: Primary database
- **Redis**: Caching and sessions
- **JWT**: Authentication tokens

### Client Stack

- **Flutter**: Cross-platform mobile framework
- **Flame**: 2D game engine
- **Riverpod**: Reactive state management
- **Material Design**: UI components

## Troubleshooting

### Server won't start

1. Check if ports 8080, 5432, or 6379 are already in use:
   ```bash
   lsof -i :8080
   lsof -i :5432
   lsof -i :6379
   ```

2. Make sure Docker is running:
   ```bash
   docker ps
   ```

### Android Client shows "Disconnected"

1. **Verify the server is running:**
   ```bash
   curl http://localhost:8080/health
   ```

2. **Check network configuration:**
   - On Android emulator: App automatically uses `http://10.0.2.2:8080`
   - On physical device: Make sure device is on same network as host
   - Check `client/lib/config.dart` for endpoint configuration

3. **Test emulator network:**
   ```bash
   # From host machine
   adb shell
   # Inside emulator shell
   curl http://10.0.2.2:8080/health
   ```

4. **For physical Android device on local network:**
   ```bash
   # Find your host machine's local IP
   ifconfig | grep "inet " | grep -v 127.0.0.1
   # or on Windows
   ipconfig

   # Run app with your local IP
   flutter run --dart-define=API_ENDPOINT=http://192.168.1.x:8080
   ```

5. **Check Android permissions:**
   - Ensure `INTERNET` permission is in `AndroidManifest.xml` (already configured)
   - Check if `usesCleartextTraffic="true"` is set (required for HTTP)

### Flutter/Android Build Issues

1. **Gradle build fails:**
   ```bash
   cd client/android
   ./gradlew clean
   cd ../..
   flutter clean
   flutter pub get
   ```

2. **SDK not found:**
   - Set `ANDROID_HOME` environment variable
   - Accept Android licenses: `flutter doctor --android-licenses`

3. **Device not detected:**
   ```bash
   # Check connected devices
   flutter devices
   adb devices

   # Restart ADB if needed
   adb kill-server
   adb start-server
   ```

### Database connection issues

1. Check PostgreSQL is running:
   ```bash
   docker-compose ps postgres
   ```

2. Verify connection string in `server/.env`

## License

MIT
