# Flipzy

A mobile game monorepo with Rust backend and Flutter client.

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

### 2. Run the Flutter Client

In a separate terminal:

```bash
cd client
flutter pub get
flutter run
```

The app will connect to the backend and display "Flipzy — Connected to backend" if successful.

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

### Flutter Client

#### Running on Different Devices

```bash
# Android
cd client
flutter run -d android

# iOS (requires macOS)
cd client
flutter run -d ios

# Web
cd client
flutter run -d chrome
```

#### Configuration

The API endpoint is configured in `client/lib/config.dart`. By default, it points to `http://localhost:8080`.

To change the API endpoint at runtime:

```bash
flutter run --dart-define=API_ENDPOINT=http://your-server:8080
```

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

### Client shows "Disconnected"

1. Verify the server is running:
   ```bash
   curl http://localhost:8080/health
   ```

2. Check the API endpoint in `client/lib/config.dart`

3. On Android emulator, use `http://10.0.2.2:8080` instead of `localhost`

4. On iOS simulator, `localhost` should work

### Database connection issues

1. Check PostgreSQL is running:
   ```bash
   docker-compose ps postgres
   ```

2. Verify connection string in `server/.env`

## License

MIT
