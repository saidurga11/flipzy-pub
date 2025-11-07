use reqwest;
use serde_json::Value;
use std::process::{Child, Command};
use std::thread;
use std::time::Duration;

struct TestServer {
    process: Option<Child>,
}

impl TestServer {
    fn start() -> Self {
        let mut process = Command::new("cargo")
            .args(&["run"])
            .env("PORT", "8081")
            .env("JWT_SECRET", "test-secret")
            .spawn()
            .expect("Failed to start server");

        // Wait for server to start
        thread::sleep(Duration::from_secs(3));

        TestServer {
            process: Some(process),
        }
    }
}

impl Drop for TestServer {
    fn drop(&mut self) {
        if let Some(mut process) = self.process.take() {
            let _ = process.kill();
        }
    }
}

#[tokio::test]
async fn test_health_endpoint_returns_200() {
    let _server = TestServer::start();

    let client = reqwest::Client::new();
    let response = client
        .get("http://localhost:8081/health")
        .send()
        .await
        .expect("Failed to send request");

    assert_eq!(response.status(), 200);

    let body: Value = response.json().await.expect("Failed to parse JSON");
    assert_eq!(body["status"], "ok");
    assert_eq!(body["service"], "flipzy-server");
}

#[tokio::test]
async fn test_guest_auth_endpoint() {
    let _server = TestServer::start();

    let client = reqwest::Client::new();
    let response = client
        .post("http://localhost:8081/auth/guest")
        .json(&serde_json::json!({"name": "TestUser"}))
        .send()
        .await
        .expect("Failed to send request");

    assert_eq!(response.status(), 200);

    let body: Value = response.json().await.expect("Failed to parse JSON");
    assert!(body["token"].is_string());
    assert!(body["user_id"].as_str().unwrap().starts_with("u-"));
}
