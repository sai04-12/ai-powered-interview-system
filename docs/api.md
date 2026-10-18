# API Documentation

## Overview
All REST APIs are versioned under `/api/v1`.
Interactive OpenAPI documentation is automatically served by FastAPI at:
- **Swagger UI**: `http://127.0.0.1:8000/docs`
- **ReDoc**: `http://127.0.0.1:8000/redoc`

---

## 1. System & Health

- `GET /health` — Root liveness probe (independent of database).
- `GET /api/v1/health` — API v1 operational health check (status, environment, version, database summary).
- `GET /api/v1/health/database` — Dedicated database readiness probe.

---

## 2. Authentication (`/api/v1/auth`)

- `POST /api/v1/auth/register` — Register a new account (`candidate` or `recruiter`).
- `POST /api/v1/auth/login` — Authenticate with email and password, returns JWT access and refresh tokens.
- `POST /api/v1/auth/refresh` — Rotate single-use refresh token and issue new token pair.
- `POST /api/v1/auth/logout` — Revoke active refresh token.
- `GET /api/v1/auth/me` — Retrieve current authenticated user profile.
- `GET /api/v1/auth/test-role/recruiter` — Recruiter RBAC verification.
- `GET /api/v1/auth/test-role/admin` — Admin RBAC verification.

---

## 3. Resumes & Document Analysis (`/api/v1/resumes`)

All resume endpoints require an active Bearer JWT. Candidates can only access and manage resumes they own.

- `POST /api/v1/resumes/upload`
  - **Form Data**: `file` (MultipartFile; PDF or DOCX; max 10MB).
  - **Security**: Validates file magic bytes (`%PDF-`, `PK\x03\x04`), sanitizes storage key with UUID prefix, extracts text safely using `pypdf`/`python-docx`, scans for prompt injections.
  - **Response (`201 Created`)**: `ResumeResponse` containing parsed structured JSON (skills, experience, education, extraction status).
- `GET /api/v1/resumes/`
  - **Response (`200 OK`)**: List of resumes owned by current authenticated user.
- `GET /api/v1/resumes/{resume_id}`
  - **Response (`200 OK`)**: Resume details and extraction status for an owned resume (`403 Forbidden` if owned by another user).
- `DELETE /api/v1/resumes/{resume_id}`
  - **Response (`204 No Content`)**: Deletes database record and associated storage file.
- `POST /api/v1/resumes/{resume_id}/match/{job_id}`
  - **Response (`200 OK`)**: Transparent job match score breakdown (overall, skills, experience, education), matched skills list, missing skills list, explanation, limitations disclaimer. Persisted to `resume_job_matches` table.

---

## 4. Job Descriptions & Management (`/api/v1/jobs`)

- `POST /api/v1/jobs/`
  - **Authorization**: `recruiter` or `admin` role required.
  - **Body**: `JobCreate` (`title`, `company`, `description`, `required_skills`, `preferred_skills`, `min_experience_years`, `education_requirements`).
  - **Response (`201 Created`)**: `JobResponse`.
- `GET /api/v1/jobs/`
  - **Authorization**: Any authenticated user (`candidate`, `recruiter`, `admin`).
  - **Response (`200 OK`)**: List of active job postings.
- `GET /api/v1/jobs/{job_id}`
  - **Response (`200 OK`)**: Job details and skill requirements.
- `PATCH /api/v1/jobs/{job_id}`
  - **Authorization**: Recruiter who created the job or admin (`403 Forbidden` for other recruiters or candidates).
  - **Body**: `JobUpdate` (partial fields).
  - **Response (`200 OK`)**: Updated `JobResponse`.
- `DELETE /api/v1/jobs/{job_id}`
  - **Authorization**: Recruiter who created the job or admin.
  - **Response (`204 No Content`)**: Deletes job posting and cascade removes associated match scores.

---

## 5. Upcoming Phase Endpoints

### Interviews (`/api/v1/interviews`) — Phase 6
- `POST /` — Initialize interview session.
- `GET /{id}` — Get interview state & progress.
- `GET /{id}/questions/current` — Get active question.
- `POST /{id}/answers` — Submit answer to current question.
- `POST /{id}/complete` — Finish interview session & trigger evaluation.

### Reports (`/api/v1/reports`) — Phase 7
- `GET /{interview_id}` — Get evaluation report summary.
- `GET /{interview_id}/pdf` — Download full PDF interview evaluation report.
