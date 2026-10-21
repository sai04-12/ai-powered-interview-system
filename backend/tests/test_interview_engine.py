"""Comprehensive Automated Tests for Phase 6: Adaptive Interview Session Engine."""
from datetime import datetime, timezone
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from app.api.deps import get_db
from app.core.security import create_access_token, hash_password
from app.main import app
from app.models.base import Base
from app.models.interview import (
    InterviewAnswer,
    InterviewQuestion,
    InterviewSession,
    QuestionCategory,
    QuestionDifficulty,
    QuestionSource,
    SessionStatus,
)
from app.models.resume import JobDescription, Resume
from app.models.user import User, UserRole
from app.services.interview_service import InterviewService, InterviewStateError


@pytest.fixture
def db_session():
    """Create isolated in-memory SQLite database for integration tests."""
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    TestingSession = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    session = TestingSession()

    def override_get_db():
        s = TestingSession()
        try:
            yield s
        finally:
            s.close()

    app.dependency_overrides[get_db] = override_get_db
    yield session
    session.close()
    app.dependency_overrides.clear()
    Base.metadata.drop_all(bind=engine)
    engine.dispose()


@pytest.fixture
def test_setup(db_session):
    """Setup standard candidate, recruiter, and job entities for tests."""
    candidate = User(
        email="candidate_tester@example.com",
        hashed_password=hash_password("Password123!"),
        role=UserRole.CANDIDATE.value,
        is_active=True,
    )
    other_candidate = User(
        email="other_candidate@example.com",
        hashed_password=hash_password("Password123!"),
        role=UserRole.CANDIDATE.value,
        is_active=True,
    )
    recruiter = User(
        email="recruiter_interviewer@example.com",
        hashed_password=hash_password("Password123!"),
        role=UserRole.RECRUITER.value,
        is_active=True,
    )
    db_session.add_all([candidate, other_candidate, recruiter])
    db_session.commit()

    job = JobDescription(
        recruiter_id=recruiter.id,
        title="Full Stack Python & Flutter Engineer",
        company="NexTech AI",
        description="Build scalable microservices and cross-platform Flutter applications.",
        required_skills=["Python", "FastAPI", "Flutter"],
        preferred_skills=["Docker", "PostgreSQL"],
        min_experience_years=3,
    )
    db_session.add(job)

    # Resume owned by candidate
    resume = Resume(
        user_id=candidate.id,
        filename="candidate_cv.pdf",
        storage_key="cv_123.pdf",
        file_type="application/pdf",
        file_size=1024,
        extraction_status="completed",
        raw_text="Experienced in Python, FastAPI, and Flutter.",
        structured_data={"skills": ["Python", "FastAPI", "Flutter"], "total_experience_years": 3.5},
    )
    # Resume owned by other_candidate
    other_resume = Resume(
        user_id=other_candidate.id,
        filename="other_cv.pdf",
        storage_key="cv_other.pdf",
        file_type="application/pdf",
        file_size=1024,
        extraction_status="completed",
        raw_text="Other candidate resume.",
        structured_data={"skills": ["Java"], "total_experience_years": 1.0},
    )
    db_session.add_all([resume, other_resume])
    db_session.commit()

    return {
        "candidate": candidate,
        "other_candidate": other_candidate,
        "recruiter": recruiter,
        "job": job,
        "resume": resume,
        "other_resume": other_resume,
        "cand_token": create_access_token(candidate.id, candidate.role),
        "other_cand_token": create_access_token(other_candidate.id, other_candidate.role),
        "rec_token": create_access_token(recruiter.id, recruiter.role),
    }


# -----------------------------------------------------------------------------
# Unit Tests: Question Generation & Adaptive Service Layer
# -----------------------------------------------------------------------------

def test_question_generation_balancing_and_uniqueness(test_setup):
    """Verify question generation generates planned count without duplicate texts."""
    job = test_setup["job"]
    resume = test_setup["resume"]

    questions = InterviewService.generate_initial_questions(
        job=job,
        resume=resume,
        total_questions=5,
        mode="mixed",
    )

    assert len(questions) == 5
    texts = [q["question_text"] for q in questions]
    assert len(set(texts)) == 5  # No duplicates

    # Check order starts at 0 and increments
    for idx, q in enumerate(questions):
        assert q["question_order"] == idx
        assert q["category"] in [
            QuestionCategory.TECHNICAL.value,
            QuestionCategory.PROBLEM_SOLVING.value,
            QuestionCategory.PROJECT_EXPERIENCE.value,
            QuestionCategory.BEHAVIORAL.value,
        ]
        assert q["difficulty"] in [
            QuestionDifficulty.EASY.value,
            QuestionDifficulty.MEDIUM.value,
            QuestionDifficulty.HARD.value,
        ]
        assert len(q["selection_reason"]) > 0


def test_adaptive_difficulty_progression_rules():
    """Verify adaptive engine adjusts next question difficulty based on answer substance."""
    session = InterviewSession(
        id="s-1",
        user_id="u-1",
        job_id="j-1",
        status=SessionStatus.IN_PROGRESS.value,
        current_question_index=0,
        total_question_count=3,
    )
    current_q = InterviewQuestion(
        id="q-1",
        session_id="s-1",
        question_text="Describe Python decorators.",
        category=QuestionCategory.TECHNICAL.value,
        skill="Python",
        difficulty=QuestionDifficulty.MEDIUM.value,
        question_order=0,
    )
    next_q = InterviewQuestion(
        id="q-2",
        session_id="s-1",
        question_text="Explain GIL in Python.",
        category=QuestionCategory.TECHNICAL.value,
        skill="Python",
        difficulty=QuestionDifficulty.MEDIUM.value,
        question_order=1,
    )

    # 1. Very brief answer (< 30 characters) -> downgrades next difficulty to EASY
    brief_answer = InterviewAnswer(
        session_id="s-1",
        question_id="q-1",
        answer_text="Functions returning functions.",
    )
    note = InterviewService.adapt_next_question(session, brief_answer, current_q, next_q)
    assert next_q.difficulty == QuestionDifficulty.EASY.value
    assert "calibrated to 'easy'" in note.lower()

    # 2. Detailed technical answer (>= 150 chars, >= 20 words) -> upgrades next difficulty to HARD
    next_q.difficulty = QuestionDifficulty.MEDIUM.value
    thorough_answer = InterviewAnswer(
        session_id="s-1",
        question_id="q-1",
        answer_text=(
            "In Python, decorators are higher-order callable objects that accept a function or class "
            "as an argument and return a modified closure or wrapper. They are extensively used in FastAPI "
            "for route registration and dependency declaration, as well as logging and caching wrappers."
        ),
    )
    note = InterviewService.adapt_next_question(session, thorough_answer, current_q, next_q)
    assert next_q.difficulty == QuestionDifficulty.HARD.value
    assert "stepped up to 'hard'" in note.lower()


# -----------------------------------------------------------------------------
# Integration Tests: Endpoints, Lifecycle, Ownership & Attack Defense
# -----------------------------------------------------------------------------

def test_session_creation_success(client: TestClient, test_setup):
    """Verify candidate can create a draft interview session for an active job."""
    res = client.post(
        "/api/v1/interviews/",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={
            "job_id": test_setup["job"].id,
            "resume_id": test_setup["resume"].id,
            "total_questions": 5,
            "mode": "mixed",
        },
    )
    assert res.status_code == 201
    data = res.json()
    assert data["status"] == "draft"
    assert data["total_question_count"] == 5
    assert data["current_question_index"] == 0
    assert data["job_title"] == test_setup["job"].title


def test_session_creation_invalid_job_id(client: TestClient, test_setup):
    """Verify session creation fails with HTTP 404 if job_id does not exist."""
    res = client.post(
        "/api/v1/interviews/",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"job_id": "non-existent-job-uuid", "total_questions": 5},
    )
    assert res.status_code == 404
    assert "Job description not found" in res.json()["detail"]


def test_session_creation_unauthorized_resume(client: TestClient, test_setup):
    """Verify candidate cannot attach another candidate's resume (HTTP 403)."""
    res = client.post(
        "/api/v1/interviews/",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={
            "job_id": test_setup["job"].id,
            "resume_id": test_setup["other_resume"].id,  # Owned by other_candidate
            "total_questions": 5,
        },
    )
    assert res.status_code == 403
    assert "cannot attach a resume owned by another candidate" in res.json()["detail"]


def test_session_ownership_access_control(client: TestClient, test_setup):
    """Verify Candidate B cannot access Candidate A's session."""
    # Candidate A creates session
    post_res = client.post(
        "/api/v1/interviews/",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"job_id": test_setup["job"].id, "total_questions": 3},
    )
    session_id = post_res.json()["id"]

    # Candidate B attempts to GET session -> HTTP 403
    get_res = client.get(
        f"/api/v1/interviews/{session_id}",
        headers={"Authorization": f"Bearer {test_setup['other_cand_token']}"},
    )
    assert get_res.status_code == 403

    # Candidate B attempts to start session -> HTTP 403
    start_res = client.post(
        f"/api/v1/interviews/{session_id}/start",
        headers={"Authorization": f"Bearer {test_setup['other_cand_token']}"},
    )
    assert start_res.status_code == 403


def test_session_lifecycle_start_and_duplicate_start(client: TestClient, test_setup):
    """Verify draft session can be started once, but duplicate start calls fail."""
    create_res = client.post(
        "/api/v1/interviews/",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"job_id": test_setup["job"].id, "total_questions": 3},
    )
    session_id = create_res.json()["id"]

    # 1. Start draft session -> 200 OK
    start_res = client.post(
        f"/api/v1/interviews/{session_id}/start",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
    )
    assert start_res.status_code == 200
    data = start_res.json()
    assert data["status"] == "in_progress"
    assert data["started_at"] is not None
    assert data["current_question"] is not None

    # 2. Duplicate start attempt on in_progress session -> HTTP 400
    dup_res = client.post(
        f"/api/v1/interviews/{session_id}/start",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
    )
    assert dup_res.status_code == 400
    assert "already in progress" in dup_res.json()["detail"]


def test_get_current_question_lifecycle(client: TestClient, test_setup):
    """Verify current question endpoint enforces in_progress status and returns valid question."""
    create_res = client.post(
        "/api/v1/interviews/",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"job_id": test_setup["job"].id, "total_questions": 3},
    )
    session_id = create_res.json()["id"]

    # Querying question while still draft -> HTTP 400
    q_draft = client.get(
        f"/api/v1/interviews/{session_id}/questions/current",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
    )
    assert q_draft.status_code == 400

    # Start session
    client.post(
        f"/api/v1/interviews/{session_id}/start",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
    )

    # Querying question after start -> 200 OK
    q_active = client.get(
        f"/api/v1/interviews/{session_id}/questions/current",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
    )
    assert q_active.status_code == 200
    data = q_active.json()
    assert data["question_order"] == 0
    assert len(data["question_text"]) > 10


def test_answer_submission_and_revision(client: TestClient, test_setup):
    """Verify answer submission validates content and allows revisions for current question."""
    create_res = client.post(
        "/api/v1/interviews/",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"job_id": test_setup["job"].id, "total_questions": 3},
    )
    session_id = create_res.json()["id"]
    client.post(
        f"/api/v1/interviews/{session_id}/start",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
    )

    # 1. Blank whitespace answer -> HTTP 400
    blank_res = client.post(
        f"/api/v1/interviews/{session_id}/answers",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"answer_text": "     \n   "},
    )
    assert blank_res.status_code == 400

    # 2. Valid answer submission -> 201 Created
    ans_res = client.post(
        f"/api/v1/interviews/{session_id}/answers",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"answer_text": "This is my initial comprehensive explanation of the architecture."},
    )
    assert ans_res.status_code == 201
    ans_data = ans_res.json()
    assert ans_data["revision_number"] == 1
    assert ans_data["word_count"] == 9

    # 3. Revising the answer before moving to next question increments revision_number
    rev_res = client.post(
        f"/api/v1/interviews/{session_id}/answers",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"answer_text": "Updated answer with deeper details on asynchronous pipelines and error handling."},
    )
    assert rev_res.status_code == 201
    rev_data = rev_res.json()
    assert rev_data["revision_number"] == 2
    assert rev_data["id"] == ans_data["id"]  # Same answer record updated


def test_advance_without_answering_rejected(client: TestClient, test_setup):
    """Verify candidate cannot skip questions without submitting an answer."""
    create_res = client.post(
        "/api/v1/interviews/",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"job_id": test_setup["job"].id, "total_questions": 3},
    )
    session_id = create_res.json()["id"]
    client.post(
        f"/api/v1/interviews/{session_id}/start",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
    )

    # Try to advance without submitting answer -> HTTP 400
    adv_res = client.post(
        f"/api/v1/interviews/{session_id}/next",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
    )
    assert adv_res.status_code == 400
    assert "submit an answer" in adv_res.json()["detail"]


def test_advance_progression_and_adaptive_calibration(client: TestClient, test_setup):
    """Verify candidate answers Question 1, advances to Question 2, and receives adaptive note."""
    create_res = client.post(
        "/api/v1/interviews/",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"job_id": test_setup["job"].id, "total_questions": 3},
    )
    session_id = create_res.json()["id"]
    client.post(
        f"/api/v1/interviews/{session_id}/start",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
    )

    # Submit detailed answer
    client.post(
        f"/api/v1/interviews/{session_id}/answers",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={
            "answer_text": (
                "In my production applications, I isolate dependencies using factory patterns and context managers. "
                "For I/O-bound concurrency, I prefer asyncio with Semaphore limiting to avoid socket starvation."
            )
        },
    )

    # Advance to Question 2
    next_res = client.post(
        f"/api/v1/interviews/{session_id}/next",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
    )
    assert next_res.status_code == 200
    data = next_res.json()
    assert data["is_completed"] is False
    assert data["next_question"]["question_order"] == 1
    assert data["session"]["current_question_index"] == 1
    assert data["adaptation_note"] is not None


def test_session_full_completion(client: TestClient, test_setup):
    """Verify answering all questions completes the session."""
    total_q = 2
    create_res = client.post(
        "/api/v1/interviews/",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"job_id": test_setup["job"].id, "total_questions": total_q},
    )
    session_id = create_res.json()["id"]
    client.post(
        f"/api/v1/interviews/{session_id}/start",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
    )

    # Answer Question 1 (index 0)
    client.post(
        f"/api/v1/interviews/{session_id}/answers",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"answer_text": "Answer 1 for first question."},
    )
    # Advance to Question 2
    client.post(
        f"/api/v1/interviews/{session_id}/next",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
    )

    # Answer Question 2 (index 1)
    client.post(
        f"/api/v1/interviews/{session_id}/answers",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"answer_text": "Answer 2 for final question."},
    )
    # Advance from final question -> triggers completion
    comp_res = client.post(
        f"/api/v1/interviews/{session_id}/next",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
    )
    assert comp_res.status_code == 200
    comp_data = comp_res.json()
    assert comp_data["is_completed"] is True
    assert comp_data["session"]["status"] == "completed"
    assert comp_data["session"]["completed_at"] is not None


def test_session_abandonment(client: TestClient, test_setup):
    """Verify active session can be abandoned, after which no answers or advances are permitted."""
    create_res = client.post(
        "/api/v1/interviews/",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"job_id": test_setup["job"].id, "total_questions": 3},
    )
    session_id = create_res.json()["id"]
    client.post(
        f"/api/v1/interviews/{session_id}/start",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
    )

    # Abandon session -> 200 OK
    aband_res = client.post(
        f"/api/v1/interviews/{session_id}/abandon",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
    )
    assert aband_res.status_code == 200
    assert aband_res.json()["status"] == "abandoned"

    # Attempt to submit answer to abandoned session -> HTTP 400
    ans_res = client.post(
        f"/api/v1/interviews/{session_id}/answers",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"answer_text": "Trying to answer abandoned session."},
    )
    assert ans_res.status_code == 400

    # Attempt to start abandoned session -> HTTP 400
    start_res = client.post(
        f"/api/v1/interviews/{session_id}/start",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
    )
    assert start_res.status_code == 400


def test_recruiter_can_view_session_summary(client: TestClient, test_setup):
    """Verify recruiter who posted the job can view session summary."""
    create_res = client.post(
        "/api/v1/interviews/",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"job_id": test_setup["job"].id, "total_questions": 3},
    )
    session_id = create_res.json()["id"]

    # Recruiter accesses session details
    rec_view = client.get(
        f"/api/v1/interviews/{session_id}",
        headers={"Authorization": f"Bearer {test_setup['rec_token']}"},
    )
    assert rec_view.status_code == 200
    assert rec_view.json()["id"] == session_id

    # Recruiter lists sessions for their job
    rec_list = client.get(
        "/api/v1/interviews/",
        headers={"Authorization": f"Bearer {test_setup['rec_token']}"},
    )
    assert rec_list.status_code == 200
    session_ids = [s["id"] for s in rec_list.json()]
    assert session_id in session_ids


def test_cross_session_question_id_attack(client: TestClient, test_setup):
    """Verify candidate cannot submit an answer containing a question_id from another session."""
    # Create and start Session 1
    res1 = client.post(
        "/api/v1/interviews/",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"job_id": test_setup["job"].id, "total_questions": 3},
    )
    s1_id = res1.json()["id"]
    client.post(f"/api/v1/interviews/{s1_id}/start", headers={"Authorization": f"Bearer {test_setup['cand_token']}"})

    # Create and start Session 2
    res2 = client.post(
        "/api/v1/interviews/",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={"job_id": test_setup["job"].id, "total_questions": 3},
    )
    s2_id = res2.json()["id"]
    s2_start = client.post(f"/api/v1/interviews/{s2_id}/start", headers={"Authorization": f"Bearer {test_setup['cand_token']}"})
    s2_q_id = s2_start.json()["current_question"]["id"]

    # Submit to Session 1 referencing question_id from Session 2 -> HTTP 400
    attack_res = client.post(
        f"/api/v1/interviews/{s1_id}/answers",
        headers={"Authorization": f"Bearer {test_setup['cand_token']}"},
        json={
            "answer_text": "Attempting to inject cross-session answer text.",
            "question_id": s2_q_id,
        },
    )
    assert attack_res.status_code == 400
    assert "Cross-session or invalid question ID" in attack_res.json()["detail"]


def test_question_unique_order_constraint(db_session, test_setup):
    """Verify database enforces UniqueConstraint('session_id', 'question_order')."""
    from sqlalchemy.exc import IntegrityError

    session = InterviewSession(
        user_id=test_setup["candidate"].id,
        job_id=test_setup["job"].id,
        status=SessionStatus.DRAFT.value,
        total_question_count=2,
    )
    db_session.add(session)
    db_session.commit()

    q1 = InterviewQuestion(
        session_id=session.id,
        question_text="First question text.",
        category=QuestionCategory.TECHNICAL.value,
        skill="Python",
        difficulty=QuestionDifficulty.EASY.value,
        question_order=0,
    )
    q2 = InterviewQuestion(
        session_id=session.id,
        question_text="Conflicting order question text.",
        category=QuestionCategory.TECHNICAL.value,
        skill="Python",
        difficulty=QuestionDifficulty.EASY.value,
        question_order=0,  # Duplicate question_order for same session
    )
    db_session.add(q1)
    db_session.commit()

    db_session.add(q2)
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()
