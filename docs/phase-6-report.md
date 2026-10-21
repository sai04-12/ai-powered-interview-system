# Phase 6 Report — Adaptive Interview Session Engine

## 1. Executive Summary

Phase 6 implements the stateful, adaptive interview session engine for the **AI-Powered Intelligent Interview System**. Candidates can configure, initialize, and execute structured, multi-question interviews tailored to job descriptions and optional candidate resume contexts.

The engine features deterministic question generation from curated skill taxonomies and dynamic parameterized templates, transparent difficulty adaptation governed by answer metadata, and strict state machine lifecycle guards (`draft` $\rightarrow$ `in_progress` $\rightarrow$ `completed` / `abandoned`). Candidate privacy is preserved by ensuring typed answers remain confidential by default and are never exposed to recruiters or unauthenticated users.

All existing capabilities from Phases 1–5 (authentication, database pooling, resume parsing, job descriptions, matching engine) have been preserved without regression.

---

## 2. Models and Alembic Database Migration

### 2.1 SQLAlchemy Models (`backend/app/models/interview.py`)

1. **`InterviewSession` (`interview_sessions` table)**:
   - `id`: UUID string primary key (`String(36)`).
   - `user_id`: Foreign key referencing `users.id` with `ondelete="CASCADE"`, indexed.
   - `job_id`: Foreign key referencing `job_descriptions.id` with `ondelete="CASCADE"`, indexed.
   - `resume_id`: Optional foreign key referencing `resumes.id` with `ondelete="SET NULL"`, indexed.
   - `status`: String enum (`draft`, `in_progress`, `completed`, `abandoned`), indexed.
   - `current_question_index`: Integer current position pointer (0-indexed).
   - `total_question_count`: Total questions planned for session (1–15, default 5).
   - `started_at`: UTC timestamp when session transitioned to `in_progress`.
   - `completed_at`: UTC timestamp when candidate advanced past the final question.
   - `created_at` / `updated_at`: UTC timestamp mixin.
   - Relationships: `user`, `job`, `resume`, `questions` (cascade delete-orphan, ordered by `question_order`), `answers` (cascade delete-orphan).

2. **`InterviewQuestion` (`interview_questions` table)**:
   - `id`: UUID string primary key (`String(36)`).
   - `session_id`: Foreign key referencing `interview_sessions.id` with `ondelete="CASCADE"`, indexed.
   - `question_text`: Text of the interview prompt.
   - `category`: Category string (`technical`, `problem_solving`, `project_experience`, `behavioral`).
   - `skill`: Assessed skill or competency string (e.g., `Python`, `Flutter`, `PostgreSQL`).
   - `difficulty`: Difficulty string (`easy`, `medium`, `hard`).
   - `question_order`: Zero-indexed integer sequencing the question in the session.
   - `question_source`: Source enum (`predefined`, `generated`, `adaptive_follow_up`).
   - `selection_reason`: Transparent audit trail explaining why the question was selected or adapted.
   - `parent_question_id`: Optional foreign key referencing a parent `interview_questions.id` for follow-ups.
   - `created_at`: UTC timestamp.
   - Constraint: `UniqueConstraint("session_id", "question_order", name="uq_session_question_order")` preventing duplicate question indexes within a session.

3. **`InterviewAnswer` (`interview_answers` table)**:
   - `id`: UUID string primary key (`String(36)`).
   - `session_id`: Foreign key referencing `interview_sessions.id` with `ondelete="CASCADE"`, indexed.
   - `question_id`: Foreign key referencing `interview_questions.id` with `ondelete="CASCADE"`, indexed.
   - `answer_text`: Candidate's typed text answer.
   - `word_count`: Integer word count of trimmed answer text.
   - `char_count`: Integer character count of trimmed answer text.
   - `submitted_at`: UTC timestamp of latest submission.
   - `revision_number`: Integer revision counter (starts at 1, increments on re-submission prior to advancing).
   - Constraint: `UniqueConstraint("session_id", "question_id", name="uq_session_question_answer")` enforcing a single canonical answer record per question.

### 2.2 Alembic Migration Lineage
- **Migration File**: `backend/migrations/versions/c7b8e1925a3d_create_interview_sessions_questions_answers.py`
- **Revision ID**: `c7b8e1925a3d`
- **Down Revision**: `f5a89e13d74c` (Resumes, Jobs, and Matches)
- **Bidirectional Verification**: Tested via `tests/test_migrations.py` with full upgrade to `head` and clean downgrade to `base` on disposable SQLite instances.

---

## 3. API Endpoints & State Machine

All endpoints are versioned under `/api/v1/interviews` and require an active Bearer JWT.

```
       [POST /]
          │
          ▼
      ┌───────┐      POST /{id}/start       ┌─────────────┐
      │ DRAFT │ ──────────────────────────> │ IN_PROGRESS │
      └───────┘                             └─────────────┘
          │                                        │
          │ POST /{id}/abandon                     │ POST /{id}/answers (repeatable revision)
          │                                        │ POST /{id}/next
          ▼                                        ▼
    ┌───────────┐                         ┌─────────────┐
    │ ABANDONED │                         │  COMPLETED  │ (when last question answered)
    └───────────┘                         └─────────────┘
```

| Method | Endpoint | Authorization | State Transition / Guard |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/interviews/` | Candidate / Admin | Creates `draft` session, validates job existence and resume ownership, generates balanced questions. |
| `GET` | `/api/v1/interviews/` | Authenticated | Candidates list owned sessions; recruiters list sessions for jobs they posted. |
| `GET` | `/api/v1/interviews/{id}` | Owner / Recruiter / Admin | Returns session progress and metadata; candidate answers remain private. |
| `POST` | `/api/v1/interviews/{id}/start` | Candidate Owner | `draft` $\rightarrow$ `in_progress`. Rejects duplicate start attempts on active or closed sessions. |
| `GET` | `/api/v1/interviews/{id}/questions/current` | Candidate Owner | Returns active question matching `current_question_index`. Rejects non-active sessions. |
| `POST` | `/api/v1/interviews/{id}/answers` | Candidate Owner | Records or revises answer for active question. Validates non-whitespace text and defends against cross-session question ID injection. |
| `POST` | `/api/v1/interviews/{id}/next` | Candidate Owner | Requires answered current question. Adaptively calibrates subsequent question difficulty. Advances index or transitions to `completed`. |
| `POST` | `/api/v1/interviews/{id}/abandon` | Candidate Owner | Transitions `draft` or `in_progress` to `abandoned`. Irreversible. |

---

## 4. Question Generation & Personalization Strategy

Implemented in `app.services.interview_service.InterviewService`:

1. **Curated Taxonomy & Question Bank**:
   - Organized by technology domain (`python`, `fastapi`, `flutter`, `dart`, `postgresql`, `docker`, `git`) and general engineering competency (`behavioral`, `project_experience`, `problem_solving`, `technical`).
   - Stratified across `easy`, `medium`, and `hard` difficulties.

2. **Session Blueprinting (`_build_question_plan`)**:
   - **Mixed Mode** (default):
     - Q0: Foundational Technical (Easy)
     - Q1: Core Technical Competency (Medium)
     - Q2: Scenario / Problem Solving (Medium)
     - Q3: Architectural Depth or Project Experience (Medium / Hard)
     - Q4: Collaboration / Behavioral (Medium)
   - **Technical Mode**: Emphasizes algorithms, concurrency, and architecture.
   - **Behavioral Mode**: Emphasizes communication, incident management, and code reviews.

3. **Resume Personalization & Consent**:
   - Candidates can opt-in to resume alignment by attaching an owned resume UUID.
   - The question generator references extracted resume skills and job requirements without assuming unverified claims are true or inventing experience.
   - If no resume is attached, standard job description requirements form the competency basis.

4. **Sanitization of Untrusted Inputs**:
   - Job titles and skill tokens are filtered using strict regex (`[^\w\s\+\#\.\-]`) and length constraints (max 80 chars) to prevent prompt injection or format breakage.

---

## 5. Adaptive Difficulty Rules & Limitations

### 5.1 Transparent Metadata-Driven Adaptation (`InterviewService.adapt_next_question`)
Per Phase 6 requirements, adaptation relies strictly on answer metadata (character count, word count, non-whitespace length) and session progress without fabricating answer scoring before Phase 7.

- **Rule 1 (Sparse / Brief Response)**:
  - Trigger: Character count $< 30$ or word count $< 6$.
  - Action: Calibrates next question difficulty down by one tier (`hard` $\rightarrow$ `medium` or `medium` $\rightarrow$ `easy`) to reinforce foundational knowledge.
  - Audit Note: *"Previous answer was brief ({chars} chars). Target difficulty for Question N calibrated to '{difficulty}' to reinforce foundational competencies."*
- **Rule 2 (Substantive / Thorough Response)**:
  - Trigger: Character count $\ge 150$ and word count $\ge 20$.
  - Action: Steps up difficulty by one tier (`easy` $\rightarrow$ `medium` or `medium` $\rightarrow$ `hard`) to explore deeper technical competence.
  - Audit Note: *"Previous answer was thorough ({words} words). Progression difficulty for Question N stepped up to '{difficulty}' to explore deeper technical depth."*
- **Rule 3 (Standard Response)**:
  - Trigger: Character count between 30 and 149.
  - Action: Maintains planned difficulty.

### 5.2 Ethical Boundaries & Limitations
- **No Evaluation Pretension**: The engine does not evaluate correctness, sentiment, emotion, or personality.
- **Length Disclaimers**: Longer text is not scored as "better".
- **Transparent Logging**: All adaptations record an explicit `selection_reason` and return `adaptation_note` to the candidate.

---

## 6. Authorization, Security & Privacy Measures

1. **Strict Session Ownership**:
   - Candidates are prohibited from modifying or reading sessions belonging to other candidates (HTTP 403 Forbidden).
   - Starting sessions, submitting answers, advancing questions, and abandoning sessions are restricted to the candidate owner.
2. **Answer Privacy Protection**:
   - Candidate text answers are excluded from session detail queries and recruiter lists. Recruiter review of answer transcripts is deferred to authorized evaluation flows in Phase 7.
3. **Cross-Session Question ID Attack Defense**:
   - `POST /{session_id}/answers` validates that if a `question_id` payload is provided, it must match the active `current_q.id` of the specified session. Attempts to submit answers to foreign question IDs return `HTTP 400 Bad Request`.
4. **State Machine Integrity**:
   - Advancing without answering returns `HTTP 400 Bad Request`.
   - Starting already-started, completed, or abandoned sessions returns `HTTP 400 Bad Request`.
   - Advancing past the final question automatically marks the session as `completed` with a verified `completed_at` timestamp.

---

## 7. Files Changed & Added

### Backend
- [`backend/app/models/interview.py`](file:///c:/ai%20interviewer/backend/app/models/interview.py) — `InterviewSession`, `InterviewQuestion`, `InterviewAnswer` SQLAlchemy models.
- [`backend/app/models/user.py`](file:///c:/ai%20interviewer/backend/app/models/user.py) — Added `interview_sessions` relationship to `User`.
- [`backend/app/models/__init__.py`](file:///c:/ai%20interviewer/backend/app/models/__init__.py) — Exported interview models and enums.
- [`backend/app/schemas/interview.py`](file:///c:/ai%20interviewer/backend/app/schemas/interview.py) — Pydantic schemas for session, questions, answers, and adaptive transitions.
- [`backend/app/schemas/__init__.py`](file:///c:/ai%20interviewer/backend/app/schemas/__init__.py) — Exported interview schemas.
- [`backend/app/services/interview_service.py`](file:///c:/ai%20interviewer/backend/app/services/interview_service.py) — Question generation, taxonomy bank, and adaptive difficulty service.
- [`backend/app/services/__init__.py`](file:///c:/ai%20interviewer/backend/app/services/__init__.py) — Exported `InterviewService` and `InterviewStateError`.
- [`backend/app/api/v1/endpoints/interviews.py`](file:///c:/ai%20interviewer/backend/app/api/v1/endpoints/interviews.py) — Endpoints for interview session lifecycle.
- [`backend/app/api/v1/router.py`](file:///c:/ai%20interviewer/backend/app/api/v1/router.py) — Mounted `/interviews` subrouter.
- [`backend/migrations/versions/c7b8e1925a3d_create_interview_sessions_questions_answers.py`](file:///c:/ai%20interviewer/backend/migrations/versions/c7b8e1925a3d_create_interview_sessions_questions_answers.py) — Alembic migration.
- [`backend/tests/test_interview_engine.py`](file:///c:/ai%20interviewer/backend/tests/test_interview_engine.py) — 16 automated tests for generation, lifecycle, attacks, and adaptation.
- [`backend/tests/test_migrations.py`](file:///c:/ai%20interviewer/backend/tests/test_migrations.py) — Metadata and forward/backward migration tests.

### Frontend
- [`frontend/lib/core/constants/api_constants.dart`](file:///c:/ai%20interviewer/frontend/lib/core/constants/api_constants.dart) — Added `interviewsPrefix`.
- [`frontend/lib/models/interview_model.dart`](file:///c:/ai%20interviewer/frontend/lib/models/interview_model.dart) — Dart models for session, question, answer, and summary.
- [`frontend/lib/services/interview_service.dart`](file:///c:/ai%20interviewer/frontend/lib/services/interview_service.dart) — Dio client for interview endpoints.
- [`frontend/lib/providers/interview_provider.dart`](file:///c:/ai%20interviewer/frontend/lib/providers/interview_provider.dart) — Riverpod state notifier for active interview sessions.
- [`frontend/lib/features/interviews/screens/interview_setup_screen.dart`](file:///c:/ai%20interviewer/frontend/lib/features/interviews/screens/interview_setup_screen.dart) — Position selection, optional resume context, mode, and consent.
- [`frontend/lib/features/interviews/screens/interview_list_screen.dart`](file:///c:/ai%20interviewer/frontend/lib/features/interviews/screens/interview_list_screen.dart) — Candidate session list and progress tracker.
- [`frontend/lib/features/interviews/screens/interview_session_screen.dart`](file:///c:/ai%20interviewer/frontend/lib/features/interviews/screens/interview_session_screen.dart) — Real-time interview execution with responsive controls and counter.
- [`frontend/lib/features/interviews/screens/interview_completion_screen.dart`](file:///c:/ai%20interviewer/frontend/lib/features/interviews/screens/interview_completion_screen.dart) — Session completion summary with Phase 7 notice.
- [`frontend/lib/router/app_router.dart`](file:///c:/ai%20interviewer/frontend/lib/router/app_router.dart) — Routes for `/interviews`, `/interviews/setup`, `/interviews/:id`, and `/interviews/:id/completed`.
- [`frontend/lib/shared/widgets/app_header.dart`](file:///c:/ai%20interviewer/frontend/lib/shared/widgets/app_header.dart) — Added Interviews navigation tab.
- [`frontend/lib/shared/screens/foundation_screen.dart`](file:///c:/ai%20interviewer/frontend/lib/shared/screens/foundation_screen.dart) — Updated Adaptive AI card with direct route.
- [`frontend/test/interview_models_test.dart`](file:///c:/ai%20interviewer/frontend/test/interview_models_test.dart) — Unit tests for serialization and progress calculations (5 tests).
- [`frontend/test/interview_screens_test.dart`](file:///c:/ai%20interviewer/frontend/test/interview_screens_test.dart) — Widget tests for all 4 interview screens (5 tests).
- [`frontend/test/live_backend_integration_test.dart`](file:///c:/ai%20interviewer/frontend/test/live_backend_integration_test.dart) — Resilient offline exception handling.

### Documentation
- [`docs/api.md`](file:///c:/ai%20interviewer/docs/api.md) — Documented interview endpoints.
- [`docs/architecture.md`](file:///c:/ai%20interviewer/docs/architecture.md) — Documented interview session architecture.
- [`docs/phase-6-report.md`](file:///c:/ai%20interviewer/docs/phase-6-report.md) — This report.

---

## 8. Automated Test Results

### 8.1 Backend Tests (`pytest -v tests/`)
```powershell
.\.venv\Scripts\pytest -v tests/
======================= 61 passed, 1 warning in 29.54s ========================
```
- **Phase 6 Interview Engine Tests (`tests/test_interview_engine.py`)**:
  1. `test_question_generation_balancing_and_uniqueness` — Planned count, category balance, unique questions (**PASSED**).
  2. `test_adaptive_difficulty_progression_rules` — Step down for brief answers, step up for thorough answers (**PASSED**).
  3. `test_session_creation_success` — Draft session initialization and question mapping (**PASSED**).
  4. `test_session_creation_invalid_job_id` — Rejection of non-existent job ID with HTTP 404 (**PASSED**).
  5. `test_session_creation_unauthorized_resume` — Candidate B cannot attach Candidate A's resume (HTTP 403) (**PASSED**).
  6. `test_session_ownership_access_control` — Cross-user session access rejection (HTTP 403) (**PASSED**).
  7. `test_session_lifecycle_start_and_duplicate_start` — Transition to `in_progress` and duplicate rejection (**PASSED**).
  8. `test_get_current_question_lifecycle` — Access enforcement and question retrieval (**PASSED**).
  9. `test_answer_submission_and_revision` — Blank text rejection (HTTP 400), revision incrementing (**PASSED**).
  10. `test_advance_without_answering_rejected` — Question skip prevention (HTTP 400) (**PASSED**).
  11. `test_advance_progression_and_adaptive_calibration` — Step to Question 2 with adaptive feedback (**PASSED**).
  12. `test_session_full_completion` — Completion timestamp and status closure (**PASSED**).
  13. `test_session_abandonment` — Transition to abandoned and post-abandonment lock (**PASSED**).
  14. `test_recruiter_can_view_session_summary` — Recruiter visibility for owned job sessions (**PASSED**).
  15. `test_cross_session_question_id_attack` — Rejection of injected foreign question IDs (HTTP 400) (**PASSED**).
  16. `test_question_unique_order_constraint` — Database integrity enforcement for duplicate question orders (**PASSED**).
- **Regression Tests (Phases 1–5)**:
  - Auth, registration, token refresh, RBAC (11 tests passed).
  - Database config & health (7 tests passed).
  - API liveness & CORS (6 tests passed).
  - Alembic migrations (2 tests passed).
  - Resume extraction & matching (16 tests passed).
  - Database session lifecycle (3 tests passed).

### 8.2 Frontend Code Analysis (`flutter analyze`)
```powershell
flutter analyze
Analyzing frontend...
No issues found! (ran in 8.6s)
```

### 8.3 Frontend Tests (`flutter test`)
```powershell
flutter test
00:26 +34: All tests passed!
```
- Total tests: 34 passed (0 failed).
- Coverage:
  - `auth_models_test.dart` (3 tests)
  - `auth_screens_test.dart` (2 tests)
  - `foundation_screen_states_test.dart` (3 tests)
  - `health_status_model_test.dart` (3 tests)
  - `interview_models_test.dart` (5 tests)
  - `interview_screens_test.dart` (5 tests)
  - `live_backend_integration_test.dart` (2 tests)
  - `resume_job_models_test.dart` (5 tests)
  - `resume_screens_test.dart` (5 tests)
  - `widget_test.dart` (1 test)

---

## 9. Known Limitations

1. **Answer Correctness & Rubrics Deferred to Phase 7**:
   - The current engine adapts based on length and submission completeness. Semantic answer evaluation and scoring rubrics are intentionally reserved for Phase 7.
2. **Deterministic Bank vs. LLM Fallback**:
   - Questions are served deterministically from the built-in taxonomy and parameterized templates. External LLM generation is architecturally isolated and optional to prevent billing dependencies.
3. **Application-Layer Rate Limiting**:
   - Endpoint throttling is currently handled via database constraint guards and single active question indexes; distributed token-bucket rate limiting can be added in production hardening.

---

## 10. Manual Verification Steps

1. **Start Backend**:
   ```powershell
   cd "C:\ai interviewer\backend"
   .\.venv\Scripts\Activate.ps1
   uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
   ```
2. **Start Flutter Frontend**:
   ```powershell
   cd "C:\ai interviewer\frontend"
   flutter run -d chrome
   ```
3. **Candidate Interview Walkthrough**:
   - Register or sign in as a candidate (`candidate@example.com`).
   - Click **Interviews** in the top navigation bar.
   - Click **Start New Interview**. Select an available position and choose question count (e.g. 3). Check consent and click **Begin Interview Session**.
   - Observe Question 1 metadata (Category badge, Difficulty badge, Skill tag).
   - Attempt to click **Next Question** before submitting — verify it is disabled.
   - Type a response in the text area. Observe the word and character counters update live.
   - Click **Submit Answer** — observe the green "Answer Recorded" status.
   - Click **Next Question** — observe progression to Question 2 with an adaptive calibration notice if applicable.
   - Complete all questions and observe transition to `/interviews/{id}/completed` with summary metrics and the Phase 7 notice.

---

## 11. Stop Condition

Phase 6 is complete. No Phase 7 features (evaluations, scoring rubrics, video/speech processing, proctoring/integrity scoring, PDF reports) have been started. Awaiting user review and approval before proceeding to Phase 7.
