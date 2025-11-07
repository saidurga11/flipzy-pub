use axum::{
    extract::State,
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};
use chrono::{Duration, Utc};
use jsonwebtoken::{encode, EncodingKey, Header};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use uuid::Uuid;

#[derive(Clone)]
struct AppState {
    jwt_secret: String,
}

#[derive(Serialize)]
struct HealthResponse {
    status: String,
    service: String,
}

#[derive(Deserialize)]
struct GuestAuthRequest {
    name: Option<String>,
}

#[derive(Serialize)]
struct GuestAuthResponse {
    token: String,
    user_id: String,
}

#[derive(Serialize, Deserialize)]
struct Claims {
    sub: String,
    name: String,
    exp: usize,
    iat: usize,
}

async fn health() -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "ok".to_string(),
        service: "flipzy-server".to_string(),
    })
}

async fn guest_auth(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<GuestAuthRequest>,
) -> Result<Json<GuestAuthResponse>, StatusCode> {
    let user_id = format!("u-{}", Uuid::new_v4());
    let guest_name = payload.name.unwrap_or_else(|| "Guest".to_string());

    let now = Utc::now();
    let expiry = now + Duration::hours(24);

    let claims = Claims {
        sub: user_id.clone(),
        name: guest_name,
        exp: expiry.timestamp() as usize,
        iat: now.timestamp() as usize,
    };

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(state.jwt_secret.as_bytes()),
    )
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(GuestAuthResponse { token, user_id }))
}

#[tokio::main]
async fn main() {
    // Load .env file
    dotenv::dotenv().ok();

    // Initialize tracing
    tracing_subscriber::fmt()
        .with_target(false)
        .compact()
        .init();

    let port = std::env::var("PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .expect("PORT must be a valid u16");

    let jwt_secret = std::env::var("JWT_SECRET")
        .unwrap_or_else(|_| "flipzy-dev-secret".to_string());

    let state = Arc::new(AppState { jwt_secret });

    let app = Router::new()
        .route("/health", get(health))
        .route("/auth/guest", post(guest_auth))
        .layer(CorsLayer::permissive())
        .with_state(state);

    let addr = format!("0.0.0.0:{}", port);
    tracing::info!("Server listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("Failed to bind to address");

    axum::serve(listener, app)
        .await
        .expect("Server failed to start");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_health_endpoint() {
        let response = health().await;
        assert_eq!(response.0.status, "ok");
        assert_eq!(response.0.service, "flipzy-server");
    }

    #[tokio::test]
    async fn test_guest_auth() {
        let state = Arc::new(AppState {
            jwt_secret: "test-secret".to_string(),
        });

        let payload = GuestAuthRequest {
            name: Some("TestUser".to_string()),
        };

        let result = guest_auth(State(state), Json(payload)).await;
        assert!(result.is_ok());

        let response = result.unwrap();
        assert!(response.0.token.len() > 0);
        assert!(response.0.user_id.starts_with("u-"));
    }
}
