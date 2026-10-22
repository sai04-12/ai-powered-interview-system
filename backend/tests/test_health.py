from fastapi.testclient import TestClient


def test_root_health(client: TestClient):
    """Test root /health endpoint returns healthy status code 200."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "timestamp" in data
    assert "environment" in data
    assert data["version"] == "1.0.0"


def test_api_v1_health(client: TestClient):
    """Test versioned /api/v1/health endpoint."""
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["version"] == "1.0.0"
    assert data["database"] == "ready"


def test_cors_headers_on_standard_origin(client: TestClient):
    """Verify CORS allow-origin header is returned for configured origins."""
    origin = "http://localhost:3000"
    response = client.get("/api/v1/health", headers={"Origin": origin})
    assert response.status_code == 200
    assert response.headers.get("access-control-allow-origin") == origin


def test_cors_headers_on_flutter_web_dynamic_origin(client: TestClient):
    """Verify CORS regex permits arbitrary Flutter web development ports."""
    flutter_dev_origin = "http://localhost:53821"
    response = client.get("/api/v1/health", headers={"Origin": flutter_dev_origin})
    assert response.status_code == 200
    assert response.headers.get("access-control-allow-origin") == flutter_dev_origin


def test_cors_preflight_options_request(client: TestClient):
    """Verify CORS OPTIONS preflight handles browser preflight requests properly."""
    flutter_origin = "http://127.0.0.1:49152"
    headers = {
        "Origin": flutter_origin,
        "Access-Control-Request-Method": "GET",
        "Access-Control-Request-Headers": "content-type,accept",
    }
    response = client.options("/api/v1/health", headers=headers)
    assert response.status_code == 200
    assert response.headers.get("access-control-allow-origin") == flutter_origin
    assert "GET" in response.headers.get("access-control-allow-methods", "")


def test_cors_headers_on_railway_production_origin(client: TestClient):
    """Verify CORS permits deployed Railway app frontend domains."""
    railway_origin = "https://ai-interview-frontend.up.railway.app"
    response = client.get("/api/v1/health", headers={"Origin": railway_origin})
    assert response.status_code == 200
    assert response.headers.get("access-control-allow-origin") == railway_origin


def test_not_found_endpoint(client: TestClient):
    """Verify 404 response schema for non-existent endpoint."""
    response = client.get("/api/v1/non_existent_route")
    assert response.status_code == 404
