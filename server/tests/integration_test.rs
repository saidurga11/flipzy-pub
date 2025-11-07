use reqwest;
use serde_json::Value;
use std::process::{Child, Command};
use std::thread;
use std::time::Duration;

struct TestServer {
    process: Option<Child>,
    port: u16,
}

impl TestServer {
    fn start(port: u16) -> Self {
        let process = Command::new("cargo")
            .args(&["run"])
            .env("PORT", port.to_string())
            .env("JWT_SECRET", "test-secret")
            .spawn()
            .expect("Failed to start server");

        // Wait for server to start
        thread::sleep(Duration::from_secs(3));

        TestServer {
            process: Some(process),
            port,
        }
    }

    fn url(&self) -> String {
        format!("http://localhost:{}", self.port)
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
    let server = TestServer::start(8081);

    let client = reqwest::Client::new();
    let response = client
        .get(format!("{}/health", server.url()))
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
    let server = TestServer::start(8082);

    let client = reqwest::Client::new();
    let response = client
        .post(format!("{}/auth/guest", server.url()))
        .json(&serde_json::json!({"name": "TestUser"}))
        .send()
        .await
        .expect("Failed to send request");

    assert_eq!(response.status(), 200);

    let body: Value = response.json().await.expect("Failed to parse JSON");
    assert!(body["token"].is_string());
    assert!(body["user_id"].as_str().unwrap().starts_with("u-"));
}
