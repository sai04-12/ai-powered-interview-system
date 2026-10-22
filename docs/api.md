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

## 5. Adaptive Interview Sessions (`/api/v1/interviews`) — Phase 6

All interview session endpoints require a valid Bearer JWT. Candidate session ownership is strictly enforced on all mutations and question queries. Recruiters can only access non-sensitive metadata for sessions associated with their posted jobs.

- `POST /api/v1/interviews/`
  - **Authorization**: Authenticated candidate or admin.
  - **Body**: `InterviewSessionCreate` (`job_id`: UUID, `resume_id`: Optional[UUID], `total_questions`: int [1–15, default 5], `mode`: "mixed" | "technical" | "behavioral").
  - **Security**: Validates job existence; validates that the candidate owns the attached resume (HTTP 403 otherwise). Generates balanced, deterministic initial question set across technical, problem-solving, project-experience, and behavioral categories.
  - **Response (`201 Created`)**: `InterviewSessionResponse` with status `draft`.

- `GET /api/v1/interviews/`
  - **Authorization**: Authenticated user. Candidates receive owned sessions; recruiters receive sessions submitted to jobs they manage.
  - **Response (`200 OK`)**: `List[InterviewSessionSummary]` with status, question progress, and timestamps.

- `GET /api/v1/interviews/{session_id}`
  - **Authorization**: Session candidate owner, recruiter managing the associated job opening, or admin (HTTP 403 otherwise).
  - **Response (`200 OK`)**: `InterviewSessionResponse` with session metadata and current question if in-progress. Candidate private answers are kept unexposed.

- `POST /api/v1/interviews/{session_id}/start`
  - **Authorization**: Session candidate owner only.
  - **Security**: Validates that session is currently in `draft` status. Rejects duplicate starts on in-progress, completed, or abandoned sessions with HTTP 400.
  - **Response (`200 OK`)**: `InterviewSessionResponse` with status `in_progress` and `started_at` timestamp.

- `GET /api/v1/interviews/{session_id}/questions/current`
  - **Authorization**: Session candidate owner only.
  - **Security**: Requires session to be `in_progress`. Rejects draft or completed sessions with HTTP 400.
  - **Response (`200 OK`)**: `InterviewQuestionResponse` with question text, category, skill, difficulty, and order.

- `POST /api/v1/interviews/{session_id}/answers`
  - **Authorization**: Session candidate owner only.
  - **Body**: `InterviewAnswerSubmit` (`answer_text`: string [1–10000 chars], `question_id`: Optional[UUID]).
  - **Security**: Enforces non-blank, non-whitespace answer text. Defends against cross-session question attacks: if `question_id` is supplied, it must match the active question ID in this session. Supports revisions prior to advancing.
  - **Response (`201 Created`)**: `InterviewAnswerResponse` with word count, character count, revision number, and submission timestamp.

- `POST /api/v1/interviews/{session_id}/next`
  - **Authorization**: Session candidate owner only.
  - **Security**: Requires current question to have a submitted answer. Prevents skipping questions. Adaptively calibrates difficulty of the subsequent question based on answer substance. Completes session when advancing past final question.
  - **Response (`200 OK`)**: `InterviewNextResult` with updated session, `is_completed` boolean, `next_question` if remaining, and `adaptation_note`.

- `POST /api/v1/interviews/{session_id}/abandon`
  - **Authorization**: Session candidate owner only.
  - **Security**: Transitions session to `abandoned`. Prevents resuming or submitting further answers.
  - **Response (`200 OK`)**: Confirmation payload with session ID and `status: "abandoned"`.

---

## 6. AI Answer Evaluation & Transparent Scoring (`/api/v1/evaluations`) — Phase 7

All evaluation endpoints require an active Bearer JWT. Candidate session ownership or recruiter job management authorization is strictly enforced. Client-supplied scores are never accepted; evaluations are computed transparently via versioned rubrics and deterministic/AI provider engines.

- `POST /api/v1/evaluations/answers/{answer_id}`
  - **Authorization**: Candidate who submitted the answer, recruiter managing the associated job posting, or admin.
  - **Body (optional)**: `AnswerEvaluationRequest` (`force_reevaluate`: bool, default False).
  - **Behavior**: Evaluates candidate answer across category-specific rubric dimensions (0–4 scale). Guarantees idempotency: returns existing active evaluation unless `force_reevaluate` is True. Automatically preserves historical evaluations upon answer revision.
  - **Response (`200 OK`)**: `AnswerEvaluationResponse` with overall score (0–100), normalized rubric score (0–4), criteria breakdown, evidence quotes, strengths, growth areas, and provider metadata.

- `GET /api/v1/evaluations/answers/{answer_id}`
  - **Authorization**: Candidate owner, recruiter managing the job, or admin.
  - **Behavior**: Retrieves active rubric evaluation record for an authorized answer.
  - **Response (`200 OK`)**: `AnswerEvaluationResponse` (or `404 Not Found` if not yet evaluated).

- `POST /api/v1/evaluations/sessions/{session_id}/evaluate`
  - **Authorization**: Session candidate owner, recruiter managing the job, or admin.
  - **Body (optional)**: `AnswerEvaluationRequest` (`force_reevaluate`: bool, default False).
  - **Security**: Requires session to be in `completed` status (`400 Bad Request` if still in draft or in-progress).
  - **Behavior**: Batch evaluates all eligible submitted answers in the session and generates comprehensive summary report.
  - **Response (`200 OK`)**: `SessionEvaluationReport`.

- `GET /api/v1/evaluations/sessions/{session_id}/report`
  - **Authorization**: Session candidate owner, recruiter managing the job, or admin (`403 Forbidden` for cross-user/cross-job access).
  - **Behavior**: Retrieves structured evaluation summary containing overall proficiency score, average rubric score, per-question criteria breakdowns, direct candidate quotes, aggregated strengths/growth areas, and standard evaluation limitations disclaimer.
  - **Response (`200 OK`)**: `SessionEvaluationReport`.

---

## 7. Upcoming Phase Endpoints

### Integrity & PDF Reports — Phase 8
- `GET /api/v1/reports/{session_id}/pdf` — Download comprehensive PDF interview audit report.
- `GET /api/v1/integrity/{session_id}` — Identity observation and audit telemetry summary.

