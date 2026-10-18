from fastapi.testclient import TestClient
from app.core import database


def test_database_health_endpoint_when_connected(client: TestClient, monkeypatch):
    """Verify /api/v1/health/database returns HTTP 200 when database ping succeeds."""
    monkeypatch.setattr(database, "check_database_connection", lambda timeout_seconds=2.0: (True, "connected"))
    
    response = client.get("/api/v1/health/database")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["database"] == "connected"
    assert "latency_ms" in data
    assert "environment" in data


def test_database_health_endpoint_when_unavailable(client: TestClient, monkeypatch):
    """Verify /api/v1/health/database returns HTTP 503 and sanitized payload when database fails."""
    monkeypatch.setattr(database, "check_database_connection", lambda timeout_seconds=2.0: (False, "unavailable"))
    
    response = client.get("/api/v1/health/database")
    assert response.status_code == 503
    data = response.json()
    assert data["status"] == "unavailable"
    assert data["database"] == "disconnected"
    assert "latency_ms" in data
    # Ensure sensitive credentials/connection strings are NEVER leaked
    assert "password" not in response.text.lower()
    assert "postgresql://" not in response.text.lower()


def test_liveness_probes_independent_of_database(client: TestClient, monkeypatch):
    """Verify root /health and /api/v1/health return 200 even when database is disconnected."""
    monkeypatch.setattr(database, "check_database_connection", lambda timeout_seconds=2.0: (False, "unavailable"))

    root_resp = client.get("/health")
    assert root_resp.status_code == 200
    assert root_resp.json()["status"] == "healthy"

    api_resp = client.get("/api/v1/health")
    assert api_resp.status_code == 200
    assert api_resp.json()["status"] == "healthy"
