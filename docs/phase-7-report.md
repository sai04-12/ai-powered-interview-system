# Phase 7 Report — AI Answer Evaluation & Transparent Scoring Engine

## 1. Executive Summary

Phase 7 implements the **AI Answer Evaluation & Transparent Scoring Engine** for the **AI-Powered Intelligent Interview System**. The engine provides objective, rubric-grounded assessments for candidate interview responses while upholding psychological safety, transparency, and data integrity.

Evaluations are performed across five standardized dimensions (`technical_knowledge`, `relevance`, `reasoning_problem_solving`, `practical_application`, and `behavioral_competencies`) using category-specific configurable weights normalized to 1.0. Every evaluation produces granular criterion scores on a 0–4 evidence scale, direct text evidence quotes extracted from candidate answers, identified strengths, actionable growth areas, and an overall proficiency score (0–100%).

A modular provider abstraction layer (`BaseEvaluationProvider`) decouples scoring logic from any single vendor, offering environment-based selection (`DeterministicEvaluationProvider`, `MockEvaluationProvider`, and cloud model connectors). Candidate answers are treated as untrusted text, actively defended against prompt injection and instruction override attempts, and explicitly disclaimed as rubric judgments of submitted text rather than holistic measurements of human worth or future workplace performance.

All existing capabilities from Phases 1–6 (auth, database pooling, resume parsing, job descriptions, matching engine, and adaptive interview sessions) have been preserved without regression.

---

## 2. Models and Alembic Database Migration

### 2.1 SQLAlchemy Model (`backend/app/models/interview.py`)

**`AnswerEvaluation` (`answer_evaluations` table)**:
- `id`: UUID string primary key (`String(36)`).
- `session_id`: Foreign key referencing `interview_sessions.id` with `ondelete="CASCADE"`, indexed.
- `answer_id`: Foreign key referencing `interview_answers.id` with `ondelete="CASCADE"`, indexed.
- `question_id`: Foreign key referencing `interview_questions.id` with `ondelete="CASCADE"`, indexed.
- `answer_revision`: Integer revision number tracking which answer revision was evaluated (starts at 1).
- `status`: String enum (`pending`, `completed`, `failed`, `requires_review`), indexed.
- `rubric_version`: Semantic version string of the rubric used (e.g., `"1.0.0"`).
- `overall_score`: Nullable float proficiency percentage (`0.0`–`100.0`). Set to `None` when evaluation fails or requires review.
- `normalized_score`: Nullable float rubric average (`0.0`–`4.0`).
- `criteria_scores`: JSON array of structured criterion objects containing `key`, `name`, `score` (0–4), `max_score` (4), `base_weight`, `normalized_weight`, `explanation`, and `evidence_quote`.
- `evidence_excerpts`: JSON array of verbatim text excerpts from candidate answer supporting the evaluation.
- `strengths`: JSON array of demonstrated technical and collaborative strengths.
- `improvement_areas`: JSON array of actionable suggestions for growth.
- `evaluator_type`: String identifier of the evaluator used (`deterministic`, `mock`, `openai`, `gemini`).
- `provider_metadata`: Sanitized JSON dictionary recording provider parameters and execution duration. Never stores secrets or hidden model reasoning.
- `evaluation_limitations`: Text containing standard legal and ethical limitations disclaimer.
- `feedback_summary`: Concise constructive narrative summary of candidate performance.
- `is_active`: Boolean flag indicating current active evaluation for the answer.
- `created_at` / `updated_at`: UTC timestamps via `TimestampMixin`.
- **Constraint**: `UniqueConstraint("answer_id", "answer_revision", "rubric_version", name="uq_answer_eval_revision_rubric")` preventing duplicate evaluations for identical answer revisions.

### 2.2 Reversible Alembic Migration
- **Migration File**: `backend/migrations/versions/a8b7c6d5e4f3_create_answer_evaluations_table.py`
- **Revision ID**: `a8b7c6d5e4f3`
- **Down Revision**: `c7b8e1925a3d` (Interview Sessions, Questions, Answers)
- **Bidirectional Verification**: Tested via `tests/test_migrations.py` with clean upgrade to `head` and full downgrade to `base` on disposable SQLite instances.

---

## 3. Rubric Definitions & Weight Normalization

Implemented in `app.services.rubric_service.RubricService`:

### 3.1 Five Standard Rubric Dimensions
1. **Technical Knowledge & Correctness (`technical_knowledge`)**:
   Accuracy, conceptual depth, syntax, and terminology relevant to the target skill.
2. **Relevance to Question (`relevance`)**:
   Directness in addressing core prompt constraints without evasiveness or tangential filler.
3. **Reasoning & Problem-Solving (`reasoning_problem_solving`)**:
   Logical cause-and-effect structure, analytical depth, and awareness of architectural trade-offs.
4. **Practical Application & Examples (`practical_application`)**:
   Real-world production context, code implementation patterns, schemas, or realistic tooling.
5. **Behavioral Competencies (`behavioral_competencies`)**:
   Constructive collaboration, ownership, clear stakeholder communication, and blameless retrospectives.

### 3.2 Category-Specific Weights
Not every criterion applies to every question. Categories emphasize relevant competencies:

| Criterion | Technical Mode | Problem Solving Mode | Project Experience Mode | Behavioral Mode |
| :--- | :---: | :---: | :---: | :---: |
| `technical_knowledge` | **0.35** | 0.25 | 0.25 | *N/A (0.00)* |
| `relevance` | 0.25 | 0.20 | 0.20 | 0.30 |
| `reasoning_problem_solving` | 0.20 | **0.35** | 0.20 | 0.30 |
| `practical_application` | 0.20 | 0.20 | **0.35** | *N/A (0.00)* |
| `behavioral_competencies` | *N/A (0.00)* | *N/A (0.00)* | *N/A (0.00)* | **0.40** |
| **Sum** | **1.00** | **1.00** | **1.00** | **1.00** |

### 3.3 Weight Normalization Formula
When calculating scores across applicable criteria $C$:
$$W_i = \frac{w_i}{\sum_{j \in C} w_j}$$
guaranteeing $\sum_{i \in C} W_i = 1.00$ even under customized or omitted criteria.

---

## 4. Standardized 0–4 Scoring Scale & Calculations

### 4.1 Documented Rubric Scale
Scores strictly represent rubric judgments anchored to observable answer evidence:
- **0**: *No relevant evidence in the answer* (absent, unrelated, or adversarial).
- **1**: *Limited relevant evidence* (minimal or superficial detail).
- **2**: *Partial evidence* (touches upon topic but lacks depth or trade-offs).
- **3**: *Strong evidence* (substantive, clear terminology, and cause-and-effect reasoning).
- **4**: *Thorough, relevant evidence* (comprehensive, production patterns, and precise terminology).

### 4.2 Transparent Scoring Formulas
- **Rubric Average (0–4 scale)**:
  $$\text{Rubric Score} = \sum_{i \in C} (\text{score}_i \times W_i)$$
- **Proficiency Score (0–100% scale)**:
  $$\text{Overall Score} = \left( \frac{\text{Rubric Score}}{4.0} \right) \times 100$$

### 4.3 Insufficient Evidence and Missing Answers
- **Absent Answers**: Text is empty or whitespace-only $\rightarrow$ Status `completed`, criterion scores 0, overall score `0.0%`.
- **Insufficient Evidence**: Brief non-responsive answers (e.g., "idk", "pass", "no idea", keyboard smashing) $\rightarrow$ Status `requires_review`, overall score `None`. Arbitrary credit is never awarded.
- **Adversarial Input**: Primary text attempts evaluator prompt injection $\rightarrow$ Status `requires_review`, overall score `None`, flagged in provider metadata.

---

## 5. AI Provider Integration & Prompt Injection Defense

Implemented in `app.ai.provider`:

1. **Provider Abstraction Layer (`BaseEvaluationProvider`)**:
   Standardized `evaluate(request: EvaluationRequest) -> EvaluationResponse` interface validated by strict Pydantic schemas.
2. **Environment Configuration (`app.core.config.Settings`)**:
   - `AI_EVALUATION_PROVIDER`: Selects active provider (`"deterministic"`, `"mock"`, `"openai"`, `"gemini"`). Default: `"deterministic"`.
   - `AI_EVALUATION_TIMEOUT_SECONDS`: Strict 15-second ceiling preventing hanging requests.
3. **Deterministic Evaluation Engine (`DeterministicEvaluationProvider`)**:
   - Zero external API dependencies for development and automated testing.
   - Grounded in curated technical taxonomies and structural discourse analysis.
   - Deterministic and repeatable: identical candidate inputs produce identical scores and evidence quotes.
   - Labeled transparently as `evaluator_type: "deterministic"` so fallbacks are never misrepresented as LLM outputs.
4. **Prompt Injection Containment**:
   - Scans candidate text against regex patterns (`ignore previous instructions`, `give me 4`, `override rubric`).
   - Replaces injection phrases with `[FILTERED_INSTRUCTION_OVERRIDE_ATTEMPT]`.
   - Candidate responses and job requirements are treated as untrusted data, never as system instructions.
5. **Provider Failure & Timeout Containment**:
   - Upstream outages (HTTP 503) or timeouts persist `status: "failed"` with clear error metadata.
   - Evaluator never fabricates scores when upstream providers are unavailable.

---

## 6. Evaluation Lifecycle & API Endpoints

All endpoints are versioned under `/api/v1/evaluations` and require a valid Bearer JWT.

```
       Candidate submits Answer (rev 1)
                     │
                     ▼
          [POST /answers/{id}] ───────────────> AnswerEvaluation (rev 1, is_active=True)
                     │
     Candidate revises Answer (rev 2)
                     │
                     ▼
          [POST /answers/{id}] ───────────────> AnswerEvaluation (rev 2, is_active=True)
                                                (rev 1 archived, is_active=False)
```

| Method | Endpoint | Authorization | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/evaluations/answers/{answer_id}` | Owner / Recruiter / Admin | Triggers rubric evaluation for an authorized answer. Idempotent: returns existing evaluation unless `force_reevaluate: true`. |
| `GET` | `/api/v1/evaluations/answers/{answer_id}` | Owner / Recruiter / Admin | Retrieves current active rubric evaluation for an authorized answer. |
| `POST` | `/api/v1/evaluations/sessions/{session_id}/evaluate` | Owner / Recruiter / Admin | Batch evaluates all candidate answers in a completed session. Rejects uncompleted sessions with HTTP 400. |
| `GET` | `/api/v1/evaluations/sessions/{session_id}/report` | Owner / Recruiter / Admin | Retrieves aggregated session report with average score, per-question criteria, strengths, growth areas, and disclaimer. |

### 6.1 Authorization & Privacy Rules
- **Candidate Isolation**: Candidates can only evaluate or retrieve reports for interview sessions they own. Cross-candidate access returns `HTTP 403 Forbidden`.
- **Recruiter Boundaries**: Recruiters can only access evaluation reports for candidate sessions submitted to job postings they manage. Cross-recruiter access returns `HTTP 403 Forbidden`.
- **No Client-Supplied Scores**: Clients cannot supply custom scores; all evaluations are calculated server-side.

---

## 7. Flutter Integration

1. **Data Models (`frontend/lib/models/evaluation_model.dart`)**:
   - `CriterionScoreModel`: Per-criterion score, weight, explanation, and evidence quote.
   - `AnswerEvaluationModel`: Complete evaluation record with status getters (`isCompleted`, `requiresReview`, `isFailed`).
   - `SessionEvaluationReportModel`: Aggregated report with average proficiency percentage and rubric score.
2. **Evaluation Service & Riverpod State (`frontend/lib/services/` & `frontend/lib/providers/`)**:
   - `EvaluationService`: Dio HTTP client communicating with `/api/v1/evaluations`.
   - `sessionEvaluationReportProvider`: FutureProvider loading session evaluation report by session ID.
   - `sessionEvaluationNotifierProvider`: State management for triggering evaluation or re-evaluation.
3. **User Interface (`frontend/lib/features/evaluation/screens/interview_evaluation_screen.dart`)**:
   - Circular percentage score gauge with responsive color coding (green for 80+, blue for 60–79, amber for 40–59, red for <40).
   - Prominent **Evaluation Limitations Disclaimer** box.
   - Dual-card layout for **Demonstrated Strengths** and **Growth Opportunities**.
   - Per-question cards displaying question prompt, skill chips, criteria progress bars, and verbatim candidate quote blocks.
   - Navigation actions: "Re-evaluate", "Back to Interviews".
4. **Router & Screen Connections**:
   - Added `/interviews/:sessionId/evaluation` route in `AppRouter`.
   - Updated `InterviewCompletionScreen` with direct "View AI Evaluation Report" button.
   - Updated `InterviewListScreen` with "Evaluation" button for completed interviews.

---

## 8. Automated Test Results

### 8.1 Backend Test Suite (`pytest -v tests/`)
```powershell
.\.venv\Scripts\pytest -v tests/
============================= 79 passed in 11.58s =============================
```
- **Phase 7 Evaluation Tests (`tests/test_evaluations.py`)** — 18 tests:
  1. `test_rubric_category_weights_and_normalization` (**PASSED**)
  2. `test_score_boundaries_validation` (**PASSED**)
  3. `test_overall_score_calculation_accuracy` (**PASSED**)
  4. `test_prompt_injection_detection_and_neutralization` (**PASSED**)
  5. `test_adversarial_sole_input_flags_requires_review` (**PASSED**)
  6. `test_insufficient_and_absent_evidence_states` (**PASSED**)
  7. `test_deterministic_evaluator_consistency` (**PASSED**)
  8. `test_provider_timeout_handling` (**PASSED**)
  9. `test_provider_failure_handling` (**PASSED**)
  10. `test_duplicate_evaluation_prevention` (**PASSED**)
  11. `test_revised_answer_preserves_evaluation_history` (**PASSED**)
  12. `test_post_evaluate_answer_endpoint` (**PASSED**)
  13. `test_get_answer_evaluation_endpoint` (**PASSED**)
  14. `test_candidate_cross_access_forbidden` (**PASSED**)
  15. `test_recruiter_can_view_evaluation_for_their_job` (**PASSED**)
  16. `test_other_recruiter_cross_job_access_forbidden` (**PASSED**)
  17. `test_batch_session_evaluation_and_report` (**PASSED**)
  18. `test_incomplete_session_batch_evaluation_rejected` (**PASSED**)
- **Regression Tests (Phases 1–6)** — 61 tests:
  - Auth, token refresh, and RBAC (11 tests passed).
  - Database config and health checks (7 tests passed).
  - API liveness and CORS (6 tests passed).
  - Adaptive interview session engine (16 tests passed).
  - Alembic migrations with `answer_evaluations` discovery (2 tests passed).
  - Resume extraction and matching engine (16 tests passed).
  - Session commit/rollback lifecycle (3 tests passed).

### 8.2 Frontend Code Analysis (`flutter analyze`)
```powershell
flutter analyze
Analyzing frontend...
No issues found! (ran in 2.8s)
```

### 8.3 Frontend Test Suite (`flutter test`)
```powershell
flutter test
00:10 +39: All tests passed!
```
- **Total Frontend Tests**: 39 passed (0 failed).
- Coverage includes:
  - `evaluation_models_test.dart` (3 tests passed)
  - `evaluation_screens_test.dart` (2 widget tests passed)
  - `interview_models_test.dart` (5 tests passed)
  - `interview_screens_test.dart` (5 tests passed)
  - All existing Phase 1–5 tests (24 tests passed).

---

## 9. Known Limitations & Ethical Safeguards

1. **Rubric Judgments vs. Objective Truth**:
   The engine evaluates submitted text against predefined rubric criteria. It does not certify that unstated claims are false or that stated claims are independently verified.
2. **Text-Based Assessment**:
   Scoring is confined strictly to typed text responses. Voice prosody, body language, facial recognition, and emotional state inference are intentionally not implemented.
3. **Prompt Injection Containment**:
   While adversarial commands are filtered and flagged for human review, human recruiters remain ultimate decision-makers in hiring pipelines.

---

## 10. Stop Condition & Next Phase

Phase 7 is fully implemented, verified, and documented. No features from Phase 8 (PDF export, identity verification, anti-cheating telemetry) have been started.

Awaiting user review and approval before proceeding to Phase 8.
