"""Answer Evaluation and Transparent Scoring API Endpoints."""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_active_user, get_db
from app.models.interview import (
    AnswerEvaluation,
    InterviewAnswer,
    InterviewSession,
    SessionStatus,
)
from app.models.user import User, UserRole
from app.schemas.evaluation import (
    AnswerEvaluationRequest,
    AnswerEvaluationResponse,
    SessionEvaluationReport,
)
from app.services.evaluation_service import EvaluationService

router = APIRouter()


def _get_answer_or_404(answer_id: str, db: Session) -> InterviewAnswer:
    """Retrieve InterviewAnswer or raise HTTP 404."""
    answer = db.query(InterviewAnswer).filter(InterviewAnswer.id == answer_id).first()
    if not answer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interview answer not found.",
        )
    return answer


def _get_session_or_404(session_id: str, db: Session) -> InterviewSession:
    """Retrieve InterviewSession or raise HTTP 404."""
    session = db.query(InterviewSession).filter(InterviewSession.id == session_id).first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interview session not found.",
        )
    return session


def _check_evaluation_access(session: InterviewSession, current_user: User) -> None:
    """Enforce authorization boundaries for accessing answer evaluations and reports."""
    if current_user.role == UserRole.ADMIN.value:
        return

    if current_user.role == UserRole.CANDIDATE.value:
        if session.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to view or evaluate answers for this interview session.",
            )
        return

    if current_user.role == UserRole.RECRUITER.value:
        if not session.job or session.job.recruiter_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to access evaluations for candidate sessions on this job opening.",
            )
        return

    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Unauthorized user role for evaluation access.",
    )


@router.post(
    "/answers/{answer_id}",
    response_model=AnswerEvaluationResponse,
    status_code=status.HTTP_200_OK,
    summary="Request rubric evaluation for a submitted answer",
)
def evaluate_answer(
    answer_id: str,
    payload: Optional[AnswerEvaluationRequest] = None,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> AnswerEvaluationResponse:
    """
    Trigger rubric-based AI evaluation for an authorized candidate answer.
    Guarantees idempotency: returns existing active evaluation unless force_reevaluate=True.
    """
    answer = _get_answer_or_404(answer_id, db)
    _check_evaluation_access(answer.session, current_user)

    force = payload.force_reevaluate if payload else False
    evaluation = EvaluationService.evaluate_answer(
        db=db,
        answer=answer,
        force_reevaluate=force,
    )
    return AnswerEvaluationResponse.model_validate(evaluation)


@router.get(
    "/answers/{answer_id}",
    response_model=AnswerEvaluationResponse,
    summary="Retrieve active evaluation for a submitted answer",
)
def get_answer_evaluation(
    answer_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> AnswerEvaluationResponse:
    """
    Retrieve current active rubric evaluation for an authorized answer.
    """
    answer = _get_answer_or_404(answer_id, db)
    _check_evaluation_access(answer.session, current_user)

    evaluation = EvaluationService.get_evaluation_for_answer(db, answer_id)
    if not evaluation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No evaluation found for this answer. Please request an evaluation first.",
        )
    return AnswerEvaluationResponse.model_validate(evaluation)


@router.post(
    "/sessions/{session_id}/evaluate",
    response_model=SessionEvaluationReport,
    summary="Batch evaluate eligible answers in a completed interview session",
)
def evaluate_session_answers(
    session_id: str,
    payload: Optional[AnswerEvaluationRequest] = None,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> SessionEvaluationReport:
    """
    Batch evaluate all candidate answers for a completed interview session.
    Requires session to be completed.
    """
    session = _get_session_or_404(session_id, db)
    _check_evaluation_access(session, current_user)

    if session.status != SessionStatus.COMPLETED.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Interview session must be in 'completed' status to evaluate session report (current: '{session.status}').",
        )

    force = payload.force_reevaluate if payload else False
    report = EvaluationService.evaluate_session_answers(
        db=db,
        session=session,
        force_reevaluate=force,
    )
    return report


@router.get(
    "/sessions/{session_id}/report",
    response_model=SessionEvaluationReport,
    summary="Retrieve structured evaluation report for an interview session",
)
def get_session_evaluation_report(
    session_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> SessionEvaluationReport:
    """
    Retrieve comprehensive evaluation report with aggregate scores, per-criterion breakdowns,
    and transparent limitations disclaimer.
    """
    session = _get_session_or_404(session_id, db)
    _check_evaluation_access(session, current_user)

    return EvaluationService.get_session_evaluation_report(db, session)
