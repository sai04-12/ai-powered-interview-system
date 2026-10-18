# Phase 4 Report — Authentication & Role-Based Authorization

## 1. Overview and Objectives
Phase 4 implements production-grade authentication and role-based access control (RBAC) across the FastAPI backend and Flutter web/desktop frontend for the AI-Powered Intelligent Interview System.

All features strictly adhere to modern cryptographic standards, OWASP guidelines, and clean architectural separation without disrupting existing health endpoints, PostgreSQL database infrastructure, Alembic migrations, or Flutter communication established in Phases 1–3.

---

## 2. Database Models & Schema Design (`backend/app/models/user.py`)

Two persistent SQLAlchemy 2.x declarative models were created and integrated into the declarative metadata registry:

### 2.1 `User` Model (`users` table)
- **`id`**: String UUID primary key (v4 UUID generator default).
- **`email`**: Normalized lowercase string, indexed, unique, non-nullable.
- **`hashed_password`**: High-entropy Argon2id hash string, non-nullable. Plaintext passwords are never persisted.
- **`full_name`**: Optional display name string.
- **`role`**: User authorization role string (defaults to `candidate`; valid roles: `candidate`, `recruiter`, `admin`). Indexed for rapid RBAC lookups.
- **`is_active`**: Boolean flag (default `True`), enabling immediate administrative account deactivation.
- **`created_at` / `updated_at`**: UTC timezone-aware timestamps provided by `TimestampMixin`.
- **Relationship**: 1-to-many relationship with `RefreshToken` with `cascade="all, delete-orphan"`.

### 2.2 `RefreshToken` Model (`refresh_tokens` table)
- **`id`**: String UUID primary key.
- **`token_hash`**: SHA-256 hash of the cryptographically random raw refresh token string, indexed, unique, non-nullable. Raw refresh tokens are never persisted to the database.
- **`user_id`**: String UUID foreign key referencing `users.id` with `ondelete="CASCADE"`.
- **`expires_at`**: UTC timezone-aware expiration timestamp.
- **`is_revoked`**: Boolean flag indicating revocation status.
- **`replaced_by_hash`**: Nullable string storing the hash of the successor token issued during token rotation (enables replay detection).
- **`created_at`**: UTC timezone-aware creation timestamp.

### 2.3 Alembic Migration
- Generated and executed migration revision:
  [`backend/migrations/versions/2044e270ea2d_create_users_and_refresh_tokens_tables.py`](file:///c:/ai%20interviewer/backend/migrations/versions/2044e270ea2d_create_users_and_refresh_tokens_tables.py)
  - Revision ID: `2044e270ea2d`
  - Down Revision: `ee82c2ee4579` (System Settings migration)
  - Tables created: `users`, `refresh_tokens` with all foreign keys, unique constraints, and indexes.
  - Full bidirectional support: `upgrade()` and `downgrade()` tested against disposable engines.

---

## 3. Cryptography & Password Security (`backend/app/core/security.py`)

- **Password Hashing Algorithm**: `Argon2id` via `argon2-cffi` (`PasswordHasher(time_cost=2, memory_cost=65536, parallelism=1, hash_len=32, type=Type.ID)`), conforming to OWASP recommended parameter tuning.
- **Anti-User Enumeration**:
  - `authenticate_user` yields an identical generic error message (`Invalid email or password`) regardless of whether the user exists or the password was incorrect.
  - When an unregistered email is queried, a dummy Argon2id hash verification is computed using pre-generated hash bytes. This normalizes server response latency and defeats timing side-channel attacks attempting to enumerate registered emails.
- **Input Validation**:
  - Email addresses are validated and normalized using Pydantic `EmailStr` and `email-validator`.
  - Passwords require a minimum length of 8 characters and are validated on both client and server before processing.

---

## 4. Authentication Endpoints & Token Lifecycle

Mounted under `/api/v1/auth`:

| Method | Endpoint | Description | Auth Required | Status Code |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/auth/register` | Register new user account | Public | `201 Created` |
| `POST` | `/api/v1/auth/login` | Authenticate with email & password | Public | `200 OK` |
| `POST` | `/api/v1/auth/refresh` | Rotate refresh token & obtain new access token | Public (Token) | `200 OK` |
| `POST` | `/api/v1/auth/logout` | Revoke active refresh token | Authenticated | `200 OK` |
| `GET` | `/api/v1/auth/me` | Fetch authenticated user profile | Bearer JWT | `200 OK` |
| `GET` | `/api/v1/auth/test-role/recruiter` | RBAC test endpoint (recruiter & admin) | Bearer JWT | `200 OK` |
| `GET` | `/api/v1/auth/test-role/admin` | RBAC test endpoint (admin only) | Bearer JWT | `200 OK` |

### 4.1 Access Token Architecture
- Short-lived JSON Web Token (JWT) signed with HMAC-SHA256 (`HS256`).
- Standard claims: `sub` (User ID), `email`, `role`, `type="access"`, `iss` (Issuer), `exp` (Expiry - default 60 minutes).
- Complete validation: Decodes signature, validates expiration, checks token type claim (`type == "access"`), and rejects mismatched signatures or malformed tokens.

### 4.2 Refresh Token Rotation & Replay Attack Defense
- Generated with `secrets.token_urlsafe(48)` (high-entropy 288-bit random token).
- Only the SHA-256 digest is stored in the database.
- **Single-Use Rotation**: Every `/refresh` call invalidates the submitted token and issues a new `(access_token, refresh_token)` pair.
- **Replay Detection & Session Invalidation**: If an already-revoked refresh token is re-submitted (indicating token theft or replay), the backend detects the compromised session lineage and immediately revokes **all** active refresh tokens belonging to that user.

### 4.3 Anti-Privilege Escalation Rules
- Public registration (`/api/v1/auth/register`) rejects requests attempting to specify `role="admin"` with HTTP 400 (`Administrators cannot self-register through the public API`).
- Allowed public self-registration roles: `candidate` (default) or `recruiter`.
- Administrator accounts must be provisioned via controlled CLI/database administrative scripts.

---

## 5. Role-Based Access Control (RBAC) System (`backend/app/api/deps.py`)

- **Role Definitions**:
  - `candidate`: Can view candidate portal, take interviews, view own reports.
  - `recruiter`: Can manage job postings, review candidate results, access recruiter dashboard.
  - `admin`: Superuser authority for platform configuration, user administration, and audit logs.
- **FastAPI Dependencies**:
  - `get_current_user`: Extracts and validates the Bearer JWT, confirms user exists and is active.
  - `require_role(*allowed_roles)`: Factory returning a dependency that enforces the user's role belongs to the permitted set. Returns `HTTP 403 Forbidden` (`Insufficient privileges for this operation`) when unauthorized.

---

## 6. Frontend Flutter Integration

### 6.1 Architecture & State Management
- **Riverpod State Management**:
  - [`frontend/lib/providers/auth_provider.dart`](file:///c:/ai%20interviewer/frontend/lib/providers/auth_provider.dart): Implements `Notifier<AuthState>` managing `UserModel? user`, `AuthTokens? tokens`, `bool isLoading`, and `String? errorMessage`.
  - Exposes actions: `login(email, password)`, `register(name, email, password, role)`, `logout()`, `clearError()`.
- **Data Models**:
  - [`frontend/lib/models/user_model.dart`](file:///c:/ai%20interviewer/frontend/lib/models/user_model.dart): Immutable model with role helper getters (`isCandidate`, `isRecruiter`, `isAdmin`).
  - [`frontend/lib/models/auth_tokens.dart`](file:///c:/ai%20interviewer/frontend/lib/models/auth_tokens.dart): Typed payload for access and refresh tokens.
- **Network Interceptor**:
  - [`frontend/lib/core/network/auth_interceptor.dart`](file:///c:/ai%20interviewer/frontend/lib/core/network/auth_interceptor.dart): Injected into Dio. Automatically attaches `Authorization: Bearer <token>` to outbound requests and handles silent token refreshes on 401 Unauthorized responses.

### 6.2 Token Storage Strategy & Security Decisions
- **Flutter Web**:
  - Access and refresh tokens are held in **in-memory session state** via [`frontend/lib/core/storage/token_storage.dart`](file:///c:/ai%20interviewer/frontend/lib/core/storage/token_storage.dart).
  - Browser `localStorage` and `sessionStorage` are deliberately **not** used to store long-lived tokens, avoiding vulnerability to Cross-Site Scripting (XSS) credential exfiltration.
- **Flutter Desktop / Mobile Targets**:
  - `TokenStorage` provides an extensible interface ready to bind to `flutter_secure_storage` using OS-level secure storage (Windows DPAPI, macOS Keychain, Linux Secret Service, Android Keystore, iOS Keychain).

### 6.3 User Interface Screens & Widgets
- [`frontend/lib/features/authentication/screens/login_screen.dart`](file:///c:/ai%20interviewer/frontend/lib/features/authentication/screens/login_screen.dart):
  - Form validation for email format and non-empty password.
  - Interactive loading spinner, error banners, and direct link to registration.
  - Uses `Wrap` layout to prevent RenderFlex overflow across compact and mobile viewports.
- [`frontend/lib/features/authentication/screens/register_screen.dart`](file:///c:/ai%20interviewer/frontend/lib/features/authentication/screens/register_screen.dart):
  - Validates full name, email address, and enforces an 8-character minimum password rule.
  - Account Type Selector (`Candidate` vs `Recruiter`) with visual selection cards.
  - Disallows admin selection.
- [`frontend/lib/shared/widgets/app_header.dart`](file:///c:/ai%20interviewer/frontend/lib/shared/widgets/app_header.dart):
  - Responsive app bar displaying current authentication status.
  - Unauthenticated: Displays `Sign In` and `Register` action buttons.
  - Authenticated: Displays user initials badge, email, role pill (`CANDIDATE`, `RECRUITER`, `ADMIN`), and a `Sign Out` button.
- [`frontend/lib/router/app_router.dart`](file:///c:/ai%20interviewer/frontend/lib/router/app_router.dart):
  - Added GoRouter routes for `/login` and `/register`.

---

## 7. Security Decisions & Sensitive Data Handling

1. **Argon2id Parameters**: Memory cost 64 MB (65,536 KiB), time cost 2 iterations, parallelism 1.
2. **Zero Plaintext Secrets**: Passwords and raw refresh tokens are never logged or stored in plaintext.
3. **Log Sanitization**: FastAPI logging filters out `Authorization` headers, `password`, `access_token`, and `refresh_token` payloads.
4. **Environment Variables**:
   - `SECRET_KEY`: Kept in `.env`, defaults to development key in non-production environments.
   - `ALGORITHM`: Set to `HS256`.
   - `ACCESS_TOKEN_EXPIRE_MINUTES`: Set to `60` (configurable).
   - `REFRESH_TOKEN_EXPIRE_DAYS`: Set to `7` (configurable).

---

## 8. Migration Commands Reference

Run database migrations from the `backend/` directory:
```powershell
# Upgrade database schema to latest version
.\.venv\Scripts\alembic upgrade head

# Downgrade schema by one revision
.\.venv\Scripts\alembic downgrade -1

# Run migrations against a custom or SQLite connection URL
.\.venv\Scripts\alembic -x db_url="sqlite:///./dev.db" upgrade head
```

---

## 9. Automated Test Verification Results

### 9.1 Backend Test Suites (`pytest -v tests/`)
**29 test cases passed** (100% success rate):
- `tests/test_auth.py::test_password_hashing_and_verification` PASSED
- `tests/test_auth.py::test_user_registration_success` PASSED
- `tests/test_auth.py::test_registration_duplicate_email_rejected` PASSED
- `tests/test_auth.py::test_registration_privilege_escalation_rejected` PASSED
- `tests/test_auth.py::test_login_success` PASSED
- `tests/test_auth.py::test_login_incorrect_password_generic_error` PASSED
- `tests/test_auth.py::test_get_me_profile_with_token` PASSED
- `tests/test_auth.py::test_access_token_expiry_handling` PASSED
- `tests/test_auth.py::test_refresh_token_rotation_and_revocation` PASSED
- `tests/test_auth.py::test_logout_revokes_token` PASSED
- `tests/test_auth.py::test_role_based_authorization_guards` PASSED
- `tests/test_database_config.py` (4 tests) PASSED
- `tests/test_database_health.py` (3 tests) PASSED
- `tests/test_health.py` (6 tests) PASSED
- `tests/test_migrations.py` (2 tests, including metadata discovery for `users` & `refresh_tokens`) PASSED
- `tests/test_session_lifecycle.py` (3 tests) PASSED

### 9.2 Frontend Static Analysis (`flutter analyze`)
```text
Analyzing frontend...
No issues found! (ran in 5.0s)
```

### 9.3 Frontend Test Suites (`flutter test`)
**14 test cases passed** (100% success rate):
- `test/auth_models_test.dart` (3 tests: `UserModel.fromJson`, `UserModel.toJson`, `AuthTokens.fromJson`)
- `test/auth_screens_test.dart` (2 tests: `LoginScreen` validation, `RegisterScreen` validation & account selection)
- `test/foundation_screen_states_test.dart` (3 tests: loading, success, offline resilience)
- `test/health_status_model_test.dart` (3 tests: parsing, defaults, serialization)
- `test/live_backend_integration_test.dart` (2 tests: live FastAPI HTTP connectivity, error fallback)
- `test/widget_test.dart` (1 test: full app smoke test with Phase 4 auth header elements)

---

## 10. Boundaries & Next Phase Constraints
- **Unchanged Reference Repos**: `reference-repos/DeepInterview`, `reference-repos/FoloUp`, and `reference-repos/AI-Interviewer-Pro` remain unmodified.
- **Phase 5 Preview**: Resume parsing and matching engine will follow in Phase 5 upon user approval.
