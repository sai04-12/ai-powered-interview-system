# Reference Repositories Technical Audit & Architectural Recommendations

## 1. Executive Summary

This document provides a comprehensive technical audit of the three reference repositories located under `C:\ai interviewer\reference-repos\`:
1. **`DeepInterview`** (`reference-repos/DeepInterview`)
2. **`FoloUp`** (`reference-repos/FoloUp`)
3. **`AI-Interviewer-Pro`** (`reference-repos/AI-Interviewer-Pro`)

The goal of this audit is to identify proven patterns, inspect dependencies, verify actual vs. claimed functionality, identify architectural compatibility risks with our target stack (**Flutter Web/Desktop + FastAPI + SQLAlchemy/PostgreSQL**), and provide concrete implementation recommendations for **Phases 5 through 9**.

> [!IMPORTANT]
> **Audit Integrity Principle**: All assessments below are based strictly on inspected source code, configuration files, and package manifests. Where repositories claim capabilities that are not substantiated by their actual code (e.g. claiming "eye contact tracking" while executing only basic binary face detection), these gaps are explicitly documented.

---

## 2. Repository Profiles

### 2.1 DeepInterview
- **Directory**: [`reference-repos/DeepInterview`](file:///c:/ai%20interviewer/reference-repos/DeepInterview)
- **License**: Apache License 2.0 (Permissive commercial use with trademark reservation and state changes notice)
- **Primary Languages**: Python 3.11+, TypeScript
- **Target Frameworks**:
  - **Backend / Agent**: FastAPI 0.140+, Uvicorn 0.51+, Pydantic 2.13+, LangGraph 1.2+, LangChain-core 1.5+, `markitdown` 0.1.6 (Microsoft document parser), LiveKit Agents 1.6+
  - **Frontend**: Next.js 16 (React 19), Tailwind CSS 4, `@livekit/components-react`, Supabase SSR
  - **Database**: Supabase PostgreSQL with RLS, JSONB payloads
- **Architecture Highlights**:
  - Implements a clean, decoupled 3-stage lifecycle: **Prep** (offline CV/JD analysis and question/rubric planning), **Live** (low-latency streaming voice worker with turn-taking guards), and **Post** (asynchronous answer evaluation and adversarial score verification).
  - Uses Microsoft `markitdown` for document text extraction with an OCR fallback to Gemini multimodal document understanding for scanned PDFs.
  - Implements a two-pass evaluation pipeline: initial 0–5 rubric scoring followed by an adversarial second-pass verifier (`verify_score_prompts`) to prevent LLM hallucinations.

### 2.2 FoloUp
- **Directory**: [`reference-repos/FoloUp`](file:///c:/ai%20interviewer/reference-repos/FoloUp)
- **License**: MIT License (Permissive)
- **Primary Languages**: TypeScript
- **Target Frameworks**:
  - **Full-Stack Application**: Next.js (App Router), React 18, Tailwind CSS, Radix UI, `@nextui-org/react`, Framer Motion
  - **Authentication**: Managed Clerk (`@clerk/nextjs`)
  - **Database**: Supabase PostgreSQL + Prisma ORM (`@prisma/client` 5.6.0)
  - **Voice / Telephony**: Proprietary SaaS Retell AI (`retell-sdk` 4.19.0, `retell-client-js-sdk` 2.0.0)
  - **AI Provider**: Direct OpenAI API (`openai` 4.6.0)
- **Architecture Highlights**:
  - Completely outsources real-time voice handling to Retell AI's managed cloud infrastructure.
  - Tracks candidate session telemetry (`tab_switch_count`, `duration`, `candidate_status`) directly in the PostgreSQL `response` table.
  - Includes focused, structured prompts for interview question generation, communication clarity assessment, and overall response analytics.

### 2.3 AI-Interviewer-Pro
- **Directory**: [`reference-repos/AI-Interviewer-Pro`](file:///c:/ai%20interviewer/reference-repos/AI-Interviewer-Pro)
- **License**: MIT License (Permissive)
- **Primary Languages**: Python 3.10+, JavaScript
- **Target Frameworks**:
  - **Backend**: FastAPI 0.115.0, Uvicorn 0.32.0, SQLAlchemy 2.0.36, Alembic 1.14.1, `psycopg[binary]` 3.2.2, Pydantic 2.9.1, `python-jose`, `passlib[bcrypt]`
  - **Document & PDF**: `pdfplumber` 0.11.4, `python-docx` 1.1.2, `reportlab` 4.2.2
  - **Speech & Vision**: `openai-whisper` (base model), `opencv-python-headless` 4.10.0, `mediapipe` 0.10.21, `torch` 2.3.1
  - **Frontend**: Next.js 14, Tailwind CSS, Chart.js
- **Architecture Highlights**:
  - **Highest backend stack alignment**: Uses FastAPI, SQLAlchemy 2.x, Alembic, Pydantic, and PostgreSQL.
  - Contains a comprehensive 734-line ReportLab PDF generator ([`pdf_generator.py`](file:///c:/ai%20interviewer/reference-repos/AI-Interviewer-Pro/ai%20interviewer%20chatbot/backend/app/services/pdf_generator.py)) producing production-quality interview reports with score progress bars and breakdown tables.
  - Includes a local OpenAI Whisper endpoint ([`transcribe.py`](file:///c:/ai%20interviewer/reference-repos/AI-Interviewer-Pro/ai%20interviewer%20chatbot/backend/app/routers/transcribe.py)) for speech-to-text.
  - **Critical Audit Finding**: Gaze/eye tracking is misleadingly implemented. In [`eye_tracker.py`](file:///c:/ai%20interviewer/reference-repos/AI-Interviewer-Pro/ai%20interviewer%20chatbot/backend/app/services/eye_tracker.py), the code simply checks if MediaPipe detects *any* face landmarks; if a face is detected, it returns a score of 100, and if no face is detected, 0. It does not measure gaze angle, iris position, or attention direction.

---

## 3. Feature Comparison Matrix

| Feature Dimension | DeepInterview | FoloUp | AI-Interviewer-Pro | Our Target System |
| :--- | :--- | :--- | :--- | :--- |
| **Backend Language & Framework** | Python (FastAPI) | TypeScript (Next.js) | Python (FastAPI) | **Python (FastAPI)** |
| **ORM & Migrations** | Supabase SQL migrations | Prisma ORM | SQLAlchemy 2.x + Alembic | **SQLAlchemy 2.x + Alembic** |
| **Frontend Framework** | Next.js 16 (React 19) | Next.js (React 18) | Next.js 14 (React) | **Flutter Web & Desktop (Dart)** |
| **State Management** | React hooks / Zustand | React hooks / React Query | React hooks | **Riverpod** |
| **Authentication** | Supabase Auth (JWT) | Clerk (Proprietary SaaS) | JWT (`python-jose`) + bcrypt | **JWT (`pyjwt`) + Argon2id** |
| **Resume Text Extraction** | Microsoft `markitdown` + Gemini OCR fallback | `pdfjs-dist` (client-side) | `pdfplumber` + `python-docx` | **Modular (`pdfplumber` / `python-docx` / fallback)** |
| **Skill Matching & Gap Analysis** | LLM-driven structured prompt (`gap_matching_prompts`) | Direct keyword extraction | Hardcoded dictionary (`KNOWN_SKILLS`, `ROLE_SKILLS`) | **Semantic overlap + transparent keyword rubric** |
| **Question Generation** | LangGraph dynamic question planner (`nodes.py`) | OpenAI prompt (`generate-questions.ts`) | Company prompt JSON (`company_prompts.json`) | **Stateful adaptive engine + Pydantic schema** |
| **Answer Evaluation** | Rubric-weighted (0–5) + adversarial 2nd pass verification | Multi-metric analytics prompt | Rule-based rubric + Gemini prompt | **Rubric dimensions + evidence verification** |
| **PDF Report Generation** | None (web scorecard only) | None (web dashboard only) | ReportLab (`pdf_generator.py`, 734 lines) | **Backend ReportLab downloadable PDF** |
| **Voice / Speech-to-Text** | LiveKit Agents (Deepgram / Cartesia / ElevenLabs) | Retell AI SaaS | Local OpenAI Whisper | **Modular adapter: Local Whisper / Web Audio fallback** |
| **Integrity & Telemetry** | Session timeouts & flusher | Tab switch count + duration | MediaPipe face presence check | **Consent-based observations (tab, pause, presence)** |

---

## 4. Exact Reusable File Paths & Asset Inventory

The following source files contain valuable reference logic, prompt templates, and styling blueprints:

### 4.1 Document Extraction & Resume Analysis
1. [`reference-repos/DeepInterview/apps/agent/src/deepinterview_agent/prep/cv_extract.py`](file:///c:/ai%20interviewer/reference-repos/DeepInterview/apps/agent/src/deepinterview_agent/prep/cv_extract.py)
   - **Reusable Concept**: Safe, non-crashing document text extraction pipeline with MIME-detection, thread pooling, and multimodal LLM OCR fallback for scanned PDFs.
2. [`reference-repos/AI-Interviewer-Pro/ai interviewer chatbot/backend/app/resume_analyzer.py`](file:///c:/ai%20interviewer/reference-repos/AI-Interviewer-Pro/ai%20interviewer%20chatbot/backend/app/resume_analyzer.py)
   - **Reusable Concept**: Practical regex patterns for identifying projects, certifications, education markers, and calculating transparent resume completeness scores without fabricating credentials.

### 4.2 Prompt Engineering & Rubric Structures
1. [`reference-repos/DeepInterview/apps/agent/src/deepinterview_agent/prep/prompts.py`](file:///c:/ai%20interviewer/reference-repos/DeepInterview/apps/agent/src/deepinterview_agent/prep/prompts.py)
   - **Reusable Concept**: `cv_analysis_prompts`, `jd_analysis_prompts`, and `gap_matching_prompts` enforcing strict adherence to source text and structured JSON outputs.
2. [`reference-repos/DeepInterview/apps/agent/src/deepinterview_agent/post/prompts.py`](file:///c:/ai%20interviewer/reference-repos/DeepInterview/apps/agent/src/deepinterview_agent/post/prompts.py)
   - **Reusable Concept**: `evaluate_answer_prompts` and `verify_score_prompts` (adversarial auditor prompt) for evidence-grounded scoring.
3. [`reference-repos/FoloUp/src/lib/prompts/generate-questions.ts`](file:///c:/ai%20interviewer/reference-repos/FoloUp/src/lib/prompts/generate-questions.ts)
   - **Reusable Concept**: Role and experience-tier tailored question generation prompt structure.
4. [`reference-repos/FoloUp/src/lib/prompts/communication-analysis.ts`](file:///c:/ai%20interviewer/reference-repos/FoloUp/src/lib/prompts/communication-analysis.ts)
   - **Reusable Concept**: Prompts isolating communication clarity and conciseness from factual technical correctness.

### 4.3 PDF Report Generation
1. [`reference-repos/AI-Interviewer-Pro/ai interviewer chatbot/backend/app/services/pdf_generator.py`](file:///c:/ai%20interviewer/reference-repos/AI-Interviewer-Pro/ai%20interviewer%20chatbot/backend/app/services/pdf_generator.py)
   - **Reusable Concept**: Complete, battle-tested ReportLab implementation including `create_progress_bar`, `TableStyle`, color grading based on scores, and multi-page layout.
2. [`reference-repos/AI-Interviewer-Pro/ai interviewer chatbot/backend/app/reporting.py`](file:///c:/ai%20interviewer/reference-repos/AI-Interviewer-Pro/ai%20interviewer%20chatbot/backend/app/reporting.py)
   - **Reusable Concept**: Data mapping from session database records into the PDF generator schema.

### 4.4 Speech-to-Text & Media Processing
1. [`reference-repos/AI-Interviewer-Pro/ai interviewer chatbot/backend/app/routers/transcribe.py`](file:///c:/ai%20interviewer/reference-repos/AI-Interviewer-Pro/ai%20interviewer%20chatbot/backend/app/routers/transcribe.py)
   - **Reusable Concept**: Lightweight Whisper model loader with `asyncio.to_thread` execution for audio chunk transcription.

---

## 5. Architectural Compatibility & Risk Analysis

### 5.1 Frontend Architecture Incompatibility (Flutter vs Next.js)
- **Finding**: All three reference repositories use Next.js/React (`DeepInterview` uses Next.js 16 + React 19; `FoloUp` uses Next.js + Radix UI; `AI-Interviewer-Pro` uses Next.js 14).
- **Risk**: None of their UI components, React hooks, or Next.js server actions can be directly copied into our Flutter frontend.
- **Mitigation**: We must maintain clean separation: adopt their REST API data contracts, JSON schemas, and prompt designs on the backend, while implementing the presentation layer natively in Flutter with Riverpod and custom widgets as established in Phase 1.

### 5.2 Third-Party SaaS Lock-in Risks
- **Finding**: `FoloUp` relies heavily on Clerk for authentication and Retell AI for voice. `DeepInterview`'s real-time voice pipeline requires LiveKit Cloud or an external self-hosted LiveKit WebRTC server cluster with paid API keys for Deepgram and Cartesia.
- **Risk**: Violates local development autonomy on Windows, creates vendor lock-in, and introduces external billing dependencies.
- **Mitigation**:
  - Authentication: Use our self-contained JWT + Argon2id backend implementation.
  - Voice: Implement a tiered approach starting with text-first interview mode, followed by backend Whisper STT / Web Speech API fallback, with modular provider abstractions for external voice services.

### 5.3 Exaggerated AI & CV Claims Risk
- **Finding**: `AI-Interviewer-Pro` advertises "eye contact tracking" and "anti-cheating", but the underlying implementation in `eye_tracker.py` merely executes a basic MediaPipe face mesh check and returns a binary 100 or 0 score.
- **Risk**: Misrepresents candidate behavior and violates Section 11 of our project charter ("Do not claim eye tracking, emotion recognition, liveness detection, or anti-cheating capabilities unless implemented and validated").
- **Mitigation**: Strictly implement session-integrity telemetry as **neutral, transparent observations** (e.g. `camera_interruption`, `long_pause_detected`, `tab_switch_count`) without making unverified psychological or honesty judgments.

---

## 6. Recommendations for Upcoming Phases

### Phase 5: Resume Parsing & Job Matching
1. **Extraction Engine**:
   - Adopt `pdfplumber` (as in `AI-Interviewer-Pro`) and `python-docx` for structured text extraction.
   - Follow `DeepInterview`'s non-crashing wrapper pattern (`_is_meaningful` heuristic + graceful warning return when a PDF contains scanned images or unreadable characters).
2. **Matching & Gap Analysis**:
   - Combine `AI-Interviewer-Pro`'s transparent keyword extraction with `DeepInterview`'s structured `gap_matching_prompts`.
   - Ensure the match score returned to the candidate clearly breaks down:
     - Matched skills with textual evidence.
     - Missing or unverified skills.
     - Limitations of automated matching.

### Phase 6: Adaptive AI Interview Engine
1. **Decoupled Prep & Session Flow**:
   - Adopt `DeepInterview`'s separation: generate the question pool and assessment rubrics before starting the session (`created` -> `ready`), then manage runtime state with low latency.
2. **State Machine & Dynamic Follow-ups**:
   - Enforce an explicit state machine: `created` -> `ready` -> `in_progress` -> `completed` (with explicit `cancelled` and `failed` handling).
   - Use dynamic follow-ups based on the candidate's actual answer length and completeness before transitioning to the next question.

### Phase 7: Answer Evaluation & Scoring
1. **Structured Rubric Validation**:
   - Score each answer against defined dimensions (technical correctness, reasoning, completeness, evidence-based clarity) on a normalized 0–5 scale using Pydantic validation.
2. **Adversarial Verification Pass**:
   - Adopt `DeepInterview`'s `verify_score_prompts` pattern: run a lightweight second verification pass over low or borderline scores to verify that deductions are strictly grounded in candidate transcript statements.

### Phase 8: PDF Performance Reports & Recruiter Workflows
1. **ReportLab Dossier Engine**:
   - Adapt `AI-Interviewer-Pro`'s `pdf_generator.py` (734 lines) into our `app/services/pdf_service.py`.
   - Incorporate:
     - Candidate metadata and interview duration.
     - Overall and category score progress bars with color grading.
     - Question-by-question breakdown with rubric scores, candidate answers, and feedback.
     - Strengths, areas for improvement, and transparent limitations disclaimer.

### Phase 9: Voice & Speech Integration
1. **Phased Voice Architecture**:
   - Keep text interview as the rock-solid baseline.
   - For audio input, provide a `/api/v1/interviews/{id}/transcribe` endpoint modeled on `AI-Interviewer-Pro`'s Whisper pipeline (`asyncio.to_thread` with base model or configurable cloud STT).
   - For audio output, support text-to-speech with browser synthesis or configurable provider fallback.
