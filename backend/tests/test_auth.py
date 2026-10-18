from datetime import timedelta
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool
from app.api.deps import get_db
from app.core.security import (
    create_access_token,
    decode_access_token,
    hash_password,
    verify_password,
)
from app.main import app
from app.models.base import Base
from app.models.user import User, UserRole


@pytest.fixture
def auth_db():
    """Create isolated in-memory SQLite database with schema for auth tests."""
    test_engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=test_engine)
    TestingSession = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

    def override_get_db():
        session = TestingSession()
        try:
            yield session
        finally:
            session.close()

    app.dependency_overrides[get_db] = override_get_db
    yield TestingSession
    app.dependency_overrides.clear()
    Base.metadata.drop_all(bind=test_engine)
    test_engine.dispose()


def test_password_hashing_and_verification():
    """Verify Argon2id password hashing produces non-reversible hashes and verifies correctly."""
    plain = "SuperSecurePassword123!"
    hashed = hash_password(plain)

    assert hashed != plain
    assert hashed.startswith("$argon2id$")
    assert verify_password(plain, hashed) is True
    assert verify_password("WrongPassword123!", hashed) is False


def test_user_registration_success(client: TestClient, auth_db):
    """Verify registration creates candidate account with 201 status."""
    payload = {
        "email": "candidate@example.com",
        "password": "Password1234!",
        "full_name": "Jane Candidate",
        "role": "candidate",
    }
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "candidate@example.com"
    assert data["full_name"] == "Jane Candidate"
    assert data["role"] == "candidate"
    assert data["is_active"] is True
    assert "hashed_password" not in data


def test_registration_duplicate_email_rejected(client: TestClient, auth_db):
    """Verify registering an existing email returns 409 Conflict."""
    payload = {
        "email": "duplicate@example.com",
        "password": "Password1234!",
        "role": "candidate",
    }
    first_resp = client.post("/api/v1/auth/register", json=payload)
    assert first_resp.status_code == 201

    dup_resp = client.post("/api/v1/auth/register", json=payload)
    assert dup_resp.status_code == 409
    assert "already exists" in dup_resp.json()["detail"].lower()


def test_registration_privilege_escalation_rejected(client: TestClient, auth_db):
    """Verify public registration rejecting attempts to register as admin."""
    payload = {
        "email": "hacker@example.com",
        "password": "Password1234!",
        "role": "admin",
    }
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 422
    assert "admin is prohibited" in response.text


def test_login_success(client: TestClient, auth_db):
    """Verify user can authenticate and receive JWT access + refresh token."""
    # 1. Register user
    reg_payload = {
        "email": "loginuser@example.com",
        "password": "Password1234!",
        "role": "recruiter",
    }
    client.post("/api/v1/auth/register", json=reg_payload)

    # 2. Login
    login_payload = {
        "email": "loginuser@example.com",
        "password": "Password1234!",
    }
    response = client.post("/api/v1/auth/login", json=login_payload)
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"
    assert data["expires_in"] > 0


def test_login_incorrect_password_generic_error(client: TestClient, auth_db):
    """Verify login with incorrect password returns generic 401 without user enumeration."""
    # Register user
    reg_payload = {
        "email": "user@example.com",
        "password": "CorrectPassword123!",
    }
    client.post("/api/v1/auth/register", json=reg_payload)

    # Try wrong password
    bad_resp = client.post(
        "/api/v1/auth/login",
        json={"email": "user@example.com", "password": "WrongPassword!"},
    )
    assert bad_resp.status_code == 401
    assert "incorrect email or password" in bad_resp.json()["detail"].lower()

    # Try non-existent user
    non_existent_resp = client.post(
        "/api/v1/auth/login",
        json={"email": "nonexistent@example.com", "password": "WrongPassword!"},
    )
    assert non_existent_resp.status_code == 401
    assert non_existent_resp.json()["detail"] == bad_resp.json()["detail"]


def test_get_me_profile_with_token(client: TestClient, auth_db):
    """Verify /api/v1/auth/me returns profile when presented with valid access token."""
    reg = client.post(
        "/api/v1/auth/register",
        json={"email": "me@example.com", "password": "Password1234!", "full_name": "Test Me"},
    )
    login_resp = client.post(
        "/api/v1/auth/login",
        json={"email": "me@example.com", "password": "Password1234!"},
    )
    token = login_resp.json()["access_token"]

    me_resp = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert me_resp.status_code == 200
    assert me_resp.json()["email"] == "me@example.com"
    assert me_resp.json()["full_name"] == "Test Me"


def test_access_token_expiry_handling(client: TestClient, auth_db):
    """Verify expired access token is rejected with 401."""
    expired_token = create_access_token(
        subject="user-123",
        role="candidate",
        expires_delta=timedelta(seconds=-10),  # expired 10s ago
    )
    resp = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {expired_token}"})
    assert resp.status_code == 401
    assert "expired" in resp.json()["detail"].lower()


def test_refresh_token_rotation_and_revocation(client: TestClient, auth_db):
    """Verify refresh token rotation issues new tokens and rejects replayed/revoked tokens."""
    # 1. Register & login
    client.post("/api/v1/auth/register", json={"email": "rotator@example.com", "password": "Password1234!"})
    login_resp = client.post("/api/v1/auth/login", json={"email": "rotator@example.com", "password": "Password1234!"})
    first_refresh = login_resp.json()["refresh_token"]

    # 2. Rotate token
    rotate_resp = client.post("/api/v1/auth/refresh", json={"refresh_token": first_refresh})
    assert rotate_resp.status_code == 200
    second_refresh = rotate_resp.json()["refresh_token"]
    assert second_refresh != first_refresh

    # 3. Replay attack: attempt to use the first_refresh token again
    replay_resp = client.post("/api/v1/auth/refresh", json={"refresh_token": first_refresh})
    assert replay_resp.status_code == 401
    assert "revoked" in replay_resp.json()["detail"].lower()


def test_logout_revokes_token(client: TestClient, auth_db):
    """Verify logout revokes the presented refresh token."""
    client.post("/api/v1/auth/register", json={"email": "logout@example.com", "password": "Password1234!"})
    login_resp = client.post("/api/v1/auth/login", json={"email": "logout@example.com", "password": "Password1234!"})
    refresh_token = login_resp.json()["refresh_token"]

    # Logout
    logout_resp = client.post("/api/v1/auth/logout", json={"refresh_token": refresh_token})
    assert logout_resp.status_code == 200

    # Attempt to refresh with logged-out token
    failed_refresh = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert failed_refresh.status_code == 401


def test_role_based_authorization_guards(client: TestClient, auth_db):
    """Verify recruiter and admin protected routes correctly enforce RBAC."""
    # Register candidate
    client.post("/api/v1/auth/register", json={"email": "cand@example.com", "password": "Password1234!", "role": "candidate"})
    cand_token = client.post("/api/v1/auth/login", json={"email": "cand@example.com", "password": "Password1234!"}).json()["access_token"]

    # Register recruiter
    client.post("/api/v1/auth/register", json={"email": "rec@example.com", "password": "Password1234!", "role": "recruiter"})
    rec_token = client.post("/api/v1/auth/login", json={"email": "rec@example.com", "password": "Password1234!"}).json()["access_token"]

    # 1. Candidate tries recruiter endpoint -> 403 Forbidden
    resp1 = client.get("/api/v1/auth/test-role/recruiter", headers={"Authorization": f"Bearer {cand_token}"})
    assert resp1.status_code == 403
    assert "access denied" in resp1.json()["detail"].lower()

    # 2. Recruiter tries recruiter endpoint -> 200 OK
    resp2 = client.get("/api/v1/auth/test-role/recruiter", headers={"Authorization": f"Bearer {rec_token}"})
    assert resp2.status_code == 200
    assert resp2.json()["role"] == "recruiter"

    # 3. Recruiter tries admin endpoint -> 403 Forbidden
    resp3 = client.get("/api/v1/auth/test-role/admin", headers={"Authorization": f"Bearer {rec_token}"})
    assert resp3.status_code == 403

    # 4. Unauthenticated access -> 403/401 HTTPBearer
    resp4 = client.get("/api/v1/auth/test-role/recruiter")
    assert resp4.status_code in (401, 403)
