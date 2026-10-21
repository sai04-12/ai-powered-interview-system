"""Interview Session Lifecycle and Adaptive Execution API Endpoints."""
from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.api.deps import get_current_active_user, get_db
from app.models.interview import (
    InterviewAnswer,
    InterviewQuestion,
    InterviewSession,
    SessionStatus,
)
from app.models.resume import JobDescription, Resume
from app.models.user import User, UserRole
from app.schemas.interview import (
    InterviewAnswerResponse,
    InterviewAnswerSubmit,
    InterviewNextResult,
    InterviewQuestionResponse,
    InterviewSessionCreate,
    InterviewSessionResponse,
    InterviewSessionSummary,
)
from app.services.interview_service import InterviewService, InterviewStateError

router = APIRouter()


def _get_session_or_404(session_id: str, db: Session) -> InterviewSession:
    """Retrieve an InterviewSession by ID or raise HTTP 404."""
    session = db.query(InterviewSession).filter(InterviewSession.id == session_id).first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interview session not found.",
        )
    return session


def _check_session_candidate_owner(session: InterviewSession, current_user: User) -> None:
    """Verify that current user is the candidate who owns the session."""
    if session.user_id != current_user.id and current_user.role != UserRole.ADMIN.value:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to access or modify this interview session.",
        )


def _build_session_response(session: InterviewSession, db: Session) -> InterviewSessionResponse:
    """Helper constructing an InterviewSessionResponse with current question if in_progress."""
    current_q_resp: Optional[InterviewQuestionResponse] = None
    if session.status == SessionStatus.IN_PROGRESS.value and session.questions:
        for q in session.questions:
            if q.question_order == session.current_question_index:
                current_q_resp = InterviewQuestionResponse.model_validate(q)
                break

    job_title = session.job.title if session.job else None
    company = session.job.company if session.job else None

    return InterviewSessionResponse(
        id=session.id,
        user_id=session.user_id,
        job_id=session.job_id,
        resume_id=session.resume_id,
        status=session.status,
        current_question_index=session.current_question_index,
        total_question_count=session.total_question_count,
        started_at=session.started_at,
        completed_at=session.completed_at,
        created_at=session.created_at,
        updated_at=session.updated_at,
        job_title=job_title,
        company=company,
        current_question=current_q_resp,
    )


@router.post(
    "/",
    response_model=InterviewSessionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new interview session for an authorized job",
)
def create_interview_session(
    session_in: InterviewSessionCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> InterviewSessionResponse:
    """
    Initialize a new draft interview session linked to an existing job description.
    Validates job existence and candidate resume ownership if provided.
    Generates balanced, deterministic initial interview questions.
    """
    # 1. Validate Job Description
    job = db.query(JobDescription).filter(JobDescription.id == session_in.job_id).first()
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job description not found.",
        )

    # 2. Validate Attached Resume if specified
    resume: Optional[Resume] = None
    if session_in.resume_id:
        resume = db.query(Resume).filter(Resume.id == session_in.resume_id).first()
        if not resume:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Attached resume not found.",
            )
        # Ensure candidate owns the attached resume
        if resume.user_id != current_user.id and current_user.role != UserRole.ADMIN.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You cannot attach a resume owned by another candidate.",
            )

    # 3. Create Session Record
    session = InterviewSession(
        user_id=current_user.id,
        job_id=job.id,
        resume_id=resume.id if resume else None,
        status=SessionStatus.DRAFT.value,
        current_question_index=0,
        total_question_count=session_in.total_questions,
    )
    db.add(session)
    db.flush()

    # 4. Generate Balanced Initial Questions
    generated_questions = InterviewService.generate_initial_questions(
        job=job,
        resume=resume,
        total_questions=session_in.total_questions,
        mode=session_in.mode or "mixed",
    )

    for q_data in generated_questions:
        q = InterviewQuestion(
            session_id=session.id,
            question_text=q_data["question_text"],
            category=q_data["category"],
            skill=q_data["skill"],
            difficulty=q_data["difficulty"],
            question_order=q_data["question_order"],
            question_source=q_data["question_source"],
            selection_reason=q_data["selection_reason"],
        )
        db.add(q)

    db.commit()
    db.refresh(session)
    return _build_session_response(session, db)


@router.get(
    "/",
    response_model=List[InterviewSessionSummary],
    summary="List candidate's interview sessions",
)
def list_interview_sessions(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> List[InterviewSessionSummary]:
    """Retrieve all interview sessions associated with the current user."""
    query = db.query(InterviewSession).order_by(InterviewSession.created_at.desc())

    if current_user.role == UserRole.CANDIDATE.value:
        query = query.filter(InterviewSession.user_id == current_user.id)
    elif current_user.role == UserRole.RECRUITER.value:
        # Recruiters can view sessions applied to their jobs
        recruiter_job_ids = [
            j.id for j in db.query(JobDescription.id).filter(JobDescription.recruiter_id == current_user.id).all()
        ]
        query = query.filter(InterviewSession.job_id.in_(recruiter_job_ids))

    sessions = query.all()
    summaries: List[InterviewSessionSummary] = []
    for s in sessions:
        answered = len(s.answers)
        summaries.append(
            InterviewSessionSummary(
                id=s.id,
                job_id=s.job_id,
                job_title=s.job.title if s.job else "Untitled Position",
                company=s.job.company if s.job else None,
                status=s.status,
                current_question_index=s.current_question_index,
                total_question_count=s.total_question_count,
                answered_count=answered,
                started_at=s.started_at,
                completed_at=s.completed_at,
                created_at=s.created_at,
            )
        )
    return summaries


@router.get(
    "/{session_id}",
    response_model=InterviewSessionResponse,
    summary="Retrieve session details and active question progress",
)
def get_interview_session(
    session_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> InterviewSessionResponse:
    """Retrieve detailed state of a specific interview session."""
    session = _get_session_or_404(session_id, db)

    # Access control
    if current_user.role == UserRole.CANDIDATE.value:
        if session.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to view this interview session.",
            )
    elif current_user.role == UserRole.RECRUITER.value:
        if not session.job or session.job.recruiter_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to view sessions for this job opening.",
            )

    return _build_session_response(session, db)


@router.post(
    "/{session_id}/start",
    response_model=InterviewSessionResponse,
    summary="Start a draft interview session",
)
def start_interview_session(
    session_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> InterviewSessionResponse:
    """Transitions a draft interview session to 'in_progress' and records started_at timestamp."""
    session = _get_session_or_404(session_id, db)
    _check_session_candidate_owner(session, current_user)

    try:
        InterviewService.validate_session_start(session)
    except InterviewStateError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    session.status = SessionStatus.IN_PROGRESS.value
    session.started_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(session)
    return _build_session_response(session, db)


@router.get(
    "/{session_id}/questions/current",
    response_model=InterviewQuestionResponse,
    summary="Retrieve the current active question for an in-progress session",
)
def get_current_question(
    session_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> InterviewQuestionResponse:
    """Returns the question corresponding to current_question_index."""
    session = _get_session_or_404(session_id, db)
    _check_session_candidate_owner(session, current_user)

    if session.status != SessionStatus.IN_PROGRESS.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Interview session is currently '{session.status}' (must be 'in_progress' to view active questions).",
        )

    for q in session.questions:
        if q.question_order == session.current_question_index:
            return InterviewQuestionResponse.model_validate(q)

    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="No question found for the current question index.",
    )


@router.post(
    "/{session_id}/answers",
    response_model=InterviewAnswerResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit candidate answer for the current question",
)
def submit_answer(
    session_id: str,
    answer_in: InterviewAnswerSubmit,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> InterviewAnswerResponse:
    """
    Record or revise candidate answer for the current active question.
    Validates session state, current question alignment, and answer text payload.
    """
    session = _get_session_or_404(session_id, db)
    _check_session_candidate_owner(session, current_user)

    # Locate current question
    current_q: Optional[InterviewQuestion] = None
    for q in session.questions:
        if q.question_order == session.current_question_index:
            current_q = q
            break

    try:
        InterviewService.validate_answer_submission(session, current_q)
    except InterviewStateError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    if answer_in.question_id and current_q and answer_in.question_id != current_q.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cross-session or invalid question ID: submitted question_id does not match the active question for this session.",
        )

    clean_text = answer_in.answer_text.strip()
    if not clean_text:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Answer text cannot be blank or whitespace-only.",
        )

    words = clean_text.split()
    word_count = len(words)
    char_count = len(clean_text)

    # Check if answer record already exists for this (session_id, question_id)
    answer_record = db.query(InterviewAnswer).filter(
        InterviewAnswer.session_id == session.id,
        InterviewAnswer.question_id == current_q.id,
    ).first()

    now_utc = datetime.now(timezone.utc)

    if answer_record:
        answer_record.answer_text = clean_text
        answer_record.word_count = word_count
        answer_record.char_count = char_count
        answer_record.submitted_at = now_utc
        answer_record.revision_number += 1
    else:
        answer_record = InterviewAnswer(
            session_id=session.id,
            question_id=current_q.id,
            answer_text=clean_text,
            word_count=word_count,
            char_count=char_count,
            submitted_at=now_utc,
            revision_number=1,
        )
        db.add(answer_record)

    db.commit()
    db.refresh(answer_record)
    return InterviewAnswerResponse.model_validate(answer_record)


@router.post(
    "/{session_id}/next",
    response_model=InterviewNextResult,
    summary="Advance to the next question or complete interview session",
)
def advance_to_next_question(
    session_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> InterviewNextResult:
    """
    Advance interview progression.
    Requires that the current question has been answered.
    Applies transparent adaptive difficulty calibration for the subsequent question.
    Completes session if advancing past the final question.
    """
    session = _get_session_or_404(session_id, db)
    _check_session_candidate_owner(session, current_user)

    # Locate current question
    current_q: Optional[InterviewQuestion] = None
    for q in session.questions:
        if q.question_order == session.current_question_index:
            current_q = q
            break

    # Locate answer for current question
    answer_record: Optional[InterviewAnswer] = None
    if current_q:
        answer_record = db.query(InterviewAnswer).filter(
            InterviewAnswer.session_id == session.id,
            InterviewAnswer.question_id == current_q.id,
        ).first()

    has_answered = answer_record is not None and len(answer_record.answer_text.strip()) > 0

    try:
        InterviewService.validate_next_transition(session, has_answered)
    except InterviewStateError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    next_index = session.current_question_index + 1
    adaptation_note: Optional[str] = None

    # Check if more questions remain
    if next_index < session.total_question_count:
        # Find next question
        next_q: Optional[InterviewQuestion] = None
        for q in session.questions:
            if q.question_order == next_index:
                next_q = q
                break

        if next_q and answer_record and current_q:
            # Calibrate next question adaptively based on answer metadata
            adaptation_note = InterviewService.adapt_next_question(
                session=session,
                last_answer=answer_record,
                current_question=current_q,
                next_question=next_q,
            )

        session.current_question_index = next_index
        db.commit()
        db.refresh(session)

        return InterviewNextResult(
            session=_build_session_response(session, db),
            is_completed=False,
            next_question=InterviewQuestionResponse.model_validate(next_q) if next_q else None,
            adaptation_note=adaptation_note,
        )
    else:
        # Final question answered -> transition session to completed
        session.status = SessionStatus.COMPLETED.value
        session.completed_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(session)

        return InterviewNextResult(
            session=_build_session_response(session, db),
            is_completed=True,
            next_question=None,
            adaptation_note="All planned questions completed. Interview session closed.",
        )


@router.post(
    "/{session_id}/abandon",
    summary="Abandon an in-progress or draft interview session",
)
def abandon_interview_session(
    session_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> dict:
    """Abandon an active interview session. Abandoned sessions cannot be resumed."""
    session = _get_session_or_404(session_id, db)
    _check_session_candidate_owner(session, current_user)

    try:
        InterviewService.validate_abandonment(session)
    except InterviewStateError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    session.status = SessionStatus.ABANDONED.value
    db.commit()
    return {
        "message": "Interview session abandoned.",
        "session_id": session.id,
        "status": session.status,
    }
