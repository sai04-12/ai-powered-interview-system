# Setup and Installation Guide

## Prerequisites
- **Python**: 3.11+
- **Flutter**: 3.41+ (channel stable with web & windows desktop enabled)
- **Git**: Installed
- **PostgreSQL**: 14+ installed and running locally on port 5432 (or configured remote instance)

## Backend Setup (Windows PowerShell)

```powershell
# Navigate to backend directory
cd "c:\ai interviewer\backend"

# Create virtual environment (if not already created)
python -m venv .venv

# Activate virtual environment
.\.venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Copy example environment file
Copy-Item .env.example .env

# Run database migrations to latest revision
alembic upgrade head

# Run FastAPI server
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

## Database Migrations (Alembic)

```powershell
cd "c:\ai interviewer\backend"
.\.venv\Scripts\Activate.ps1

# Upgrade to latest migration revision
alembic upgrade head

# Downgrade one revision
alembic downgrade -1

# View migration history
alembic history --verbose

# Verify database readiness probe
Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/health/database"
```

## Frontend Setup (Flutter Web / Desktop)

```powershell
# Navigate to frontend directory
cd "c:\ai interviewer\frontend"

# Get Flutter packages
flutter pub get

# Run on Chrome (Flutter Web)
flutter run -d chrome

# Run on Windows Desktop
flutter run -d windows
```

## File Upload Storage
Uploaded resumes are securely stored on the local filesystem outside public static directories at:
`c:\ai interviewer\backend\uploads\resumes`
- Directories are created automatically with strict access controls.
- Uploads enforce magic byte signature verification (`%PDF-` for PDF, `PK\x03\x04` for DOCX).
- Size limit is enforced at 10 MB.

## Running Automated Tests

```powershell
# Backend tests (45 tests covering auth, DB health, PDF/DOCX extraction, security, matching engine)
cd "c:\ai interviewer\backend"
.\.venv\Scripts\pytest -v tests/

# Frontend analyzer & tests (0 analyzer issues, 24 passing tests)
cd "c:\ai interviewer\frontend"
flutter analyze
flutter test
```
