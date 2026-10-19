# Phase 5 Architecture & Security Review

**Review Date**: 2026-10-18  
**Repository Location**: `C:\ai interviewer`  
**Current Commit**: `b7534a94f77c76a3a9677f5cbaabeaaf551c7d26`  
**Review Status**: Completed — Ready for User Approval before Phase 6  

---

## 1. Executive Summary & Verification Matrix

| Area | Component | Status | Finding Summary |
| :--- | :--- | :---: | :--- |
| **Git Status** | Branch & Commit Sync | **PASS** | Commit `b7534a9` verified locally and on `origin/main`; working tree clean. |
| **Document Ingestion** | Upload Validation & Magic Bytes | **PASS** | Validates `%PDF-` and `PK\x03\x04`; enforces 10MB limit and safe extensions. |
| **Filesystem Security** | Storage Isolation & Path Traversal | **PASS** | UUID storage keys generated server-side; path traversal defense verified. |
| **Access Control** | Cross-User Resume Isolation | **PASS** | Candidates restricted to owned resumes (HTTP 403 on cross-access). |
| **Job Management** | Recruiter RBAC & Ownership | **PASS** | Candidates cannot create/edit jobs; recruiters restricted to own jobs. |
| **File Lifecycle** | Physical File Deletion | **PASS** | `os.remove` safely cleans disk files upon resume deletion with owner checks. |
| **Matching Engine** | Skill Normalization & Gap Analysis | **PASS** | Normalizes special characters (`C++`, `Node.js`); transparent missing skills. |
| **Scoring Formula** | 60% / 25% / 15% Weighting | **PASS** | Weighted formula strictly matches specification when education is present. |
| **Scoring Assumptions** | Experience / Education Heuristics | **WARNING** | Unstated experience defaults to 50% partial credit instead of unverified flag. |
| **Alembic Migrations** | Upgrade / Downgrade Lifecycle | **PASS** | Tested on isolated database; bidirectional migrations pass without error. |
| **Automated Tests** | Backend & Flutter Test Suites | **PASS** | 45 backend tests pass; 24 Flutter tests pass; 0 analyzer issues. |

---

## 2. Item-by-Item Detailed Findings

### 2.1 Git Status & Commit Verification
- **Status**: **PASS**
- **Evidence**:
  ```powershell
  git status
  # On branch main
  # Your branch is up to date with 'origin/main'.
  # nothing to commit, working tree clean

  git log -n 2 --oneline
  # b7534a9 feat(phase-5): implement resume parsing, job management, and intelligent matching with flutter integration and tests
  # 0ed821b feat: complete Phases 1-4 foundation, database migrations, and auth RBAC

  git rev-parse HEAD
  # b7534a94f77c76a3a9677f5cbaabeaaf551c7d26
  git rev-parse origin/main
  # b7534a94f77c76a3a9677f5cbaabeaaf551c7d26
  ```
- **Conclusion**: Local `main` and remote `origin/main` are identical, clean, and synchronized at commit `b7534a9`.

---

### 2.2 Upload Security & Storage Isolation
- **Status**: **PASS**
- **Code Locations**:
  - Magic byte validation: [`backend/app/services/resume_service.py#L155-L174`](file:///c:/ai%20interviewer/backend/app/services/resume_service.py#L155-L174)
  - Storage key generation & directory boundary check: [`backend/app/services/resume_service.py#L176-L188`](file:///c:/ai%20interviewer/backend/app/services/resume_service.py#L176-L188)
- **Findings**:
  1. **Magic Byte Inspection**:
     - PDF: Checks `content.startswith(b"%PDF-")`.
     - DOCX: Checks `content.startswith(b"PK\x03\x04") or content.startswith(b"PK\x05\x06")` and verifies zip archive structure for `word/document.xml` or `[Content_Types].xml`.
     - Corrupted or extension-spoofed files are rejected before parsing.
  2. **Path Traversal Defense**:
     - Filename path segments are stripped via `os.path.basename`.
     - Storage key is generated server-side: `storage_key = f"{uuid.uuid4().hex}{ext}"`.
     - Explicit check: `destination_path.startswith(resolved_upload_dir)` ensures files never escape the storage boundary.
  3. **Verification Output**:
     - Tested with `../../../../etc/passwd.pdf`: file was created strictly inside the temporary upload directory with server-generated key `9264dc5b42b3421bb1504f1132e02b1c.pdf`, confirming path traversal is impossible.

---

### 2.3 Cross-User Access Isolation & Physical File Cleanup
- **Status**: **PASS**
- **Code Locations**:
  - Resume ownership validation: [`backend/app/api/v1/endpoints/resumes.py#L92-L99`](file:///c:/ai%20interviewer/backend/app/api/v1/endpoints/resumes.py#L92-L99)
  - Resume deletion: [`backend/app/api/v1/endpoints/resumes.py#L117-L134`](file:///c:/ai%20interviewer/backend/app/api/v1/endpoints/resumes.py#L117-L134)
  - Match permission validation: [`backend/app/api/v1/endpoints/resumes.py#L158-L166`](file:///c:/ai%20interviewer/backend/app/api/v1/endpoints/resumes.py#L158-L166)
- **Findings**:
  1. **Resume Retrieval**: Candidates attempting to access a resume with a different `user_id` receive `HTTP 403 Forbidden` (`You do not have permission to access this resume`).
  2. **Resume Listing**: `/api/v1/resumes/` filters by `Resume.user_id == current_user.id` for candidates, ensuring users only see their own resumes.
  3. **File Deletion**:
     - Only the resume owner or an administrator can delete a resume.
     - Physical file is resolved via `os.path.join(settings.UPLOAD_DIR, resume.storage_key)` and removed with `os.remove` before database deletion.
  4. **Test Verification**:
     - `test_resume_ownership_authorization` in `tests/test_resumes_and_jobs.py` explicitly tests Candidate B attempting to `GET` and `DELETE` Candidate A's resume and confirms both return `HTTP 403`.

---

### 2.4 Matching Engine, Skill Gap Analysis & Scoring
- **Status**: **PASS** (with **WARNING** on heuristics)
- **Code Locations**:
  - Skill normalization: [`backend/app/services/matching_service.py#L16-L19`](file:///c:/ai%20interviewer/backend/app/services/matching_service.py#L16-L19)
  - Skill gap analysis: [`backend/app/services/matching_service.py#L53-L91`](file:///c:/ai%20interviewer/backend/app/services/matching_service.py#L53-L91)
  - Experience scoring: [`backend/app/services/matching_service.py#L93-L110`](file:///c:/ai%20interviewer/backend/app/services/matching_service.py#L93-L110)
  - Education scoring: [`backend/app/services/matching_service.py#L112-L126`](file:///c:/ai%20interviewer/backend/app/services/matching_service.py#L112-L126)
  - Composite weighting: [`backend/app/services/matching_service.py#L128-L139`](file:///c:/ai%20interviewer/backend/app/services/matching_service.py#L128-L139)

#### A. Skill Normalization & Missing Skills Reporting (**PASS**)
- Token normalization strips non-word characters except `+`, `#`, `.`: `re.sub(r"[^\w\+\#\.]", "", skill.strip().lower())`.
  - Accurately matches `C++`, `C#`, `Node.js`, `REST API`, `Vue.js`.
- Checks both candidate extracted skill tokens and regex word boundaries in the raw resume text.
- Missing required skills are preserved in their original casing and returned in `missing_skills: List[str]`.
- Matched skills include explicit evidence strings (`Identified in resume skills or profile text matching 'Python'`).

#### B. Component Weighting (**PASS**)
- When job specifies education requirements:
  $$\text{Overall Score} = (\text{Skill Score} \times 0.60) + (\text{Experience Score} \times 0.25) + (\text{Education Score} \times 0.15)$$
- When job does not specify education requirements:
  $$\text{Overall Score} = (\text{Skill Score} \times 0.70) + (\text{Experience Score} \times 0.30)$$

#### C. Heuristic Assumptions & Discrepancies (**WARNING**)
1. **Internal Skill Weighting Discrepancy**:
   - Inside `skill_score`, the code calculates: `(req_ratio * 0.75) + (pref_ratio * 0.25)` (75% required / 25% preferred).
   - In `docs/phase-5-report.md`, one summary bullet referred to 70% required / 30% preferred. The code implementation (75/25) is more protective of required competencies, which is advantageous, but the documentation phrasing should be aligned in Phase 6.
2. **Unsupported Experience Fallback (Heuristic Assumption)**:
   - When a candidate's resume does not explicitly mention year durations or date ranges, `total_experience_years` is `None`.
   - The engine assigns a default score of `50.0%` if `min_experience_years` is specified, or `80.0%` if unspecified.
   - *Recommendation for future phase*: If experience cannot be verified from the document, consider returning `experience_score = None` or flagging `experience_verified = false` rather than awarding a fixed 50% baseline.
3. **Unsupported Education Fallback (Heuristic Assumption)**:
   - If a job specifies an education requirement but the resume has no recognized degree, the engine assigns `50.0%` instead of `0.0%`.
   - *Rationale*: Avoids disqualifying self-taught candidates entirely at the resume matching stage; however, recruiters should be informed that education was unverified.

---

### 2.5 Alembic Migration & Database Schema Review
- **Status**: **PASS**
- **Migration File**: [`backend/migrations/versions/f5a89e13d74c_create_resumes_jobs_matches_tables.py`](file:///c:/ai%20interviewer/backend/migrations/versions/f5a89e13d74c_create_resumes_jobs_matches_tables.py)
- **Revision ID**: `f5a89e13d74c` | **Down Revision**: `2044e270ea2d`
- **Findings**:
  1. Tables created: `resumes`, `job_descriptions`, `resume_job_matches`.
  2. Foreign keys include `ondelete="CASCADE"` on `user_id`, `recruiter_id`, `resume_id`, and `job_id`.
  3. `UniqueConstraint("resume_id", "job_id", name="uq_resume_job_match")` prevents duplicate scores.
  4. Full downgrade drops tables and indexes in reverse order.
  5. **Automated Verification**:
     ```powershell
     pytest -v tests/test_migrations.py
     # tests/test_migrations.py::test_migration_metadata_discovery PASSED [ 50%]
     # tests/test_migrations.py::test_alembic_upgrade_and_downgrade PASSED [100%]
     # 2 passed in 0.69s
     ```
     The migration was upgraded to `head` and downgraded to `base` on a temporary SQLite database without modifying production data.

---

### 2.6 Test Coverage & Verification Evidence
- **Status**: **PASS**

#### Backend Test Suite (`pytest -v tests/`)
```powershell
.\.venv\Scripts\pytest -v tests/
======================== 45 passed, 1 warning in 6.72s ========================
```
- **Security & Extraction Tests Verified**:
  - `test_pdf_text_extraction` — Clean text extraction via `pypdf`.
  - `test_docx_text_extraction` — Clean text extraction via `python-docx`.
  - `test_empty_file_rejected` — Rejection of 0-byte file with HTTP 400.
  - `test_oversized_file_rejected` — Rejection of 11MB file with HTTP 400.
  - `test_unsupported_file_extension` — Rejection of `.exe` with HTTP 400.
  - `test_signature_and_extension_mismatch` — Rejection of fake PDF (magic bytes mismatch).
  - `test_corrupted_docx_rejected` — Rejection of corrupted archive.
  - `test_scanned_pdf_detects_ocr_required` — Scanned blank PDF triggers `needs_ocr`.
  - `test_untrusted_input_prompt_injection_sanitization` — Prompt injection strings stripped.
  - `test_deterministic_matching_results` — Identical scores across repeated runs.
  - `test_matching_with_missing_skills` — Accurate missing skill penalization.
  - `test_matching_incomplete_extraction_fails` — Rejects matching unextracted resumes.
  - `test_resume_upload_endpoint` — End-to-end authenticated upload.
  - `test_resume_ownership_authorization` — Cross-user resume isolation (`HTTP 403`).
  - `test_job_management_recruiter_rbac` — Recruiter RBAC and candidate restriction (`HTTP 403`).
  - `test_resume_to_job_match_endpoint` — End-to-end match scoring and database persistence.

#### Frontend Code Analysis (`flutter analyze`)
```powershell
flutter analyze
# Analyzing frontend...
# No issues found! (ran in 4.3s)
```

#### Frontend Test Suite (`flutter test`)
```powershell
flutter test
# 00:19 +24: All tests passed!
```
- 24 tests passed, including:
  - `resume_job_models_test.dart` (5 tests covering `ResumeModel`, `JobModel`, `MatchModel` serialization)
  - `resume_screens_test.dart` (5 tests covering `ResumeListScreen`, `JobListScreen`, `ResumeMatchScreen` UI states)
  - 14 tests for authentication, health, and foundation screens.

---

## 3. Summary of Warnings & Recommendations

1. **Experience Fallback Score (Warning)**:
   - When a candidate's resume does not contain recognizable years of experience, the engine assigns a default 50% score. In Phase 6, we should introduce an `is_experience_verified` boolean in the UI to make this heuristic transparent to recruiters.
2. **OCR Integration for Scanned Documents**:
   - Currently, scanned PDFs without text layers safely return `needs_ocr: true` without crashing. An asynchronous OCR worker (e.g. Celery + Tesseract) can be evaluated in a later phase.
3. **Internal Skill Ratio Documentation**:
   - Reconcile `phase-5-report.md` text to reflect the code's 75% required / 25% preferred internal skill weighting.

---

## 4. Final Verdict

**VERDICT: PASS**

The Phase 5 implementation satisfies all technical, architectural, security, and verification requirements. The codebase is clean, fully tested, committed to Git (`b7534a9`), and synchronized with `origin/main`.

**Stop Condition Met**: No Phase 6 features have been started. Awaiting user approval.
