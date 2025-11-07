.PHONY: dev test build clean

# Load environment variables and run the server in development mode
dev:
	@echo "Starting flipzy-server in development mode..."
	@if [ -f .env ]; then export $$(cat .env | xargs); fi && cargo run

# Run tests
test:
	@echo "Running tests..."
	cargo test

# Run integration tests
test-integration:
	@echo "Running integration tests..."
	cargo test --test integration_test

# Build the release binary
build:
	@echo "Building release binary..."
	cargo build --release

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	cargo clean

# Check code formatting and lints
check:
	cargo fmt -- --check
	cargo clippy -- -D warnings
