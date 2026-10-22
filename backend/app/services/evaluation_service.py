"""Evaluation Service orchestrating answer assessment, lifecycle, and report generation."""
import logging
from datetime import datetime, timezone
from typing import List, Optional

from sqlalchemy.orm import Session

from app.ai.provider import (
    BaseEvaluationProvider,
    EvaluationRequest,
    get_evaluation_provider,
)
from app.models.interview import (
    AnswerEvaluation,
    EvaluationStatus,
    InterviewAnswer,
    InterviewQuestion,
    InterviewSession,
    SessionStatus,
)
from app.schemas.evaluation import (
    AnswerEvaluationResponse,
    CriterionScoreResponse,
    SessionEvaluationReport,
    SessionQuestionEvaluationSummary,
)
from app.services.rubric_service import (
    RUBRIC_VERSION,
    STANDARD_LIMITATIONS_DISCLAIMER,
)

logger = logging.getLogger(__name__)


class EvaluationService:
    """Service handling answer evaluations and structured session reporting."""

    @staticmethod
    def evaluate_answer(
        db: Session,
        answer: InterviewAnswer,
        force_reevaluate: bool = False,
        provider: Optional[BaseEvaluationProvider] = None,
    ) -> AnswerEvaluation:
        """
        Evaluate an authorized submitted answer.
        Guarantees idempotency unless force_reevaluate is True.
        Preserves evaluation history across answer revisions.
        """
        active_eval = db.query(AnswerEvaluation).filter(
            AnswerEvaluation.answer_id == answer.id,
            AnswerEvaluation.answer_revision == answer.revision_number,
            AnswerEvaluation.rubric_version == RUBRIC_VERSION,
            AnswerEvaluation.is_active == True,
        ).first()

        if active_eval and not force_reevaluate:
            return active_eval

        # Deactivate any previous active evaluations for this answer
        db.query(AnswerEvaluation).filter(
            AnswerEvaluation.answer_id == answer.id,
            AnswerEvaluation.is_active == True,
        ).update({"is_active": False})

        question: InterviewQuestion = answer.question
        session: InterviewSession = answer.session

        job_title = session.job.title if session.job else None
        job_desc = session.job.description if session.job else None

        req = EvaluationRequest(
            question_text=question.question_text,
            category=question.category,
            skill=question.skill,
            difficulty=question.difficulty,
            answer_text=answer.answer_text,
            job_title=job_title,
            job_description=job_desc,
        )

        eval_provider = provider or get_evaluation_provider()

        now_utc = datetime.now(timezone.utc)

        try:
            eval_resp = eval_provider.evaluate(req)

            eval_record = AnswerEvaluation(
                session_id=session.id,
                answer_id=answer.id,
                question_id=question.id,
                answer_revision=answer.revision_number,
                status=eval_resp.status,
                rubric_version=eval_resp.rubric_version,
                overall_score=eval_resp.overall_score,
                normalized_score=eval_resp.normalized_score,
                criteria_scores=[c.model_dump() for c in eval_resp.criteria_scores],
                evidence_excerpts=eval_resp.evidence_excerpts,
                strengths=eval_resp.strengths,
                improvement_areas=eval_resp.improvement_areas,
                evaluator_type=eval_resp.evaluator_type,
                provider_metadata=eval_resp.provider_metadata,
                evaluation_limitations=eval_resp.evaluation_limitations,
                feedback_summary=eval_resp.feedback_summary,
                is_active=True,
                created_at=now_utc,
                updated_at=now_utc,
            )
        except TimeoutError as te:
            logger.warning(f"AI evaluation timeout for answer {answer.id}: {te}")
            eval_record = AnswerEvaluation(
                session_id=session.id,
                answer_id=answer.id,
                question_id=question.id,
                answer_revision=answer.revision_number,
                status=EvaluationStatus.FAILED.value,
                rubric_version=RUBRIC_VERSION,
                overall_score=None,
                normalized_score=None,
                criteria_scores=[],
                evidence_excerpts=[],
                strengths=[],
                improvement_areas=[],
                evaluator_type="system_timeout",
                provider_metadata={"error": "provider_timeout", "timeout_seconds": 15},
                evaluation_limitations=STANDARD_LIMITATIONS_DISCLAIMER,
                feedback_summary="Evaluation timed out. Please retry or flag for manual review.",
                is_active=True,
                created_at=now_utc,
                updated_at=now_utc,
            )
        except Exception as e:
            logger.error(f"AI evaluation error for answer {answer.id}: {e}", exc_info=True)
            eval_record = AnswerEvaluation(
                session_id=session.id,
                answer_id=answer.id,
                question_id=question.id,
                answer_revision=answer.revision_number,
                status=EvaluationStatus.FAILED.value,
                rubric_version=RUBRIC_VERSION,
                overall_score=None,
                normalized_score=None,
                criteria_scores=[],
                evidence_excerpts=[],
                strengths=[],
                improvement_areas=[],
                evaluator_type="system_error",
                provider_metadata={"error": "provider_failure", "error_type": type(e).__name__},
                evaluation_limitations=STANDARD_LIMITATIONS_DISCLAIMER,
                feedback_summary=f"Evaluation failed: {str(e)}",
                is_active=True,
                created_at=now_utc,
                updated_at=now_utc,
            )

        db.add(eval_record)
        db.commit()
        db.refresh(eval_record)
        return eval_record

    @staticmethod
    def get_evaluation_for_answer(db: Session, answer_id: str) -> Optional[AnswerEvaluation]:
        """Fetch active evaluation for answer."""
        return db.query(AnswerEvaluation).filter(
            AnswerEvaluation.answer_id == answer_id,
            AnswerEvaluation.is_active == True,
        ).first()

    @staticmethod
    def evaluate_session_answers(
        db: Session,
        session: InterviewSession,
        force_reevaluate: bool = False,
        provider: Optional[BaseEvaluationProvider] = None,
    ) -> SessionEvaluationReport:
        """
        Batch evaluate all eligible submitted answers in an interview session.
        """
        for question in session.questions:
            answer = db.query(InterviewAnswer).filter(
                InterviewAnswer.session_id == session.id,
                InterviewAnswer.question_id == question.id,
            ).first()

            if answer:
                EvaluationService.evaluate_answer(
                    db=db,
                    answer=answer,
                    force_reevaluate=force_reevaluate,
                    provider=provider,
                )

        return EvaluationService.get_session_evaluation_report(db, session)

    @staticmethod
    def get_session_evaluation_report(
        db: Session,
        session: InterviewSession,
    ) -> SessionEvaluationReport:
        """
        Construct structured session report aggregating per-question evaluations.
        """
        question_summaries: List[SessionQuestionEvaluationSummary] = []
        completed_scores_100: List[float] = []
        completed_scores_4: List[float] = []
        all_strengths: List[str] = []
        all_improvements: List[str] = []
        evaluator_types: List[str] = []

        total_questions = session.total_question_count
        answered_count = 0
        evaluated_count = 0

        for q in session.questions:
            answer = db.query(InterviewAnswer).filter(
                InterviewAnswer.session_id == session.id,
                InterviewAnswer.question_id == q.id,
            ).first()

            eval_model: Optional[AnswerEvaluationResponse] = None
            if answer:
                answered_count += 1
                active_eval = db.query(AnswerEvaluation).filter(
                    AnswerEvaluation.answer_id == answer.id,
                    AnswerEvaluation.is_active == True,
                ).first()

                if active_eval:
                    evaluated_count += 1
                    eval_model = AnswerEvaluationResponse.model_validate(active_eval)
                    if active_eval.overall_score is not None:
                        completed_scores_100.append(active_eval.overall_score)
                    if active_eval.normalized_score is not None:
                        completed_scores_4.append(active_eval.normalized_score)
                    all_strengths.extend(active_eval.strengths)
                    all_improvements.extend(active_eval.improvement_areas)
                    evaluator_types.append(active_eval.evaluator_type)

            question_summaries.append(
                SessionQuestionEvaluationSummary(
                    question_id=q.id,
                    question_order=q.question_order,
                    question_text=q.question_text,
                    category=q.category,
                    skill=q.skill,
                    difficulty=q.difficulty,
                    answer_id=answer.id if answer else None,
                    answer_revision=answer.revision_number if answer else None,
                    word_count=answer.word_count if answer else None,
                    evaluation=eval_model,
                )
            )

        avg_100 = round(sum(completed_scores_100) / len(completed_scores_100), 1) if completed_scores_100 else None
        avg_4 = round(sum(completed_scores_4) / len(completed_scores_4), 2) if completed_scores_4 else None

        # Deduplicate strengths and improvements maintaining order
        dedup_strengths = list(dict.fromkeys(all_strengths))[:5]
        dedup_improvements = list(dict.fromkeys(all_improvements))[:5]
        primary_evaluator = evaluator_types[0] if evaluator_types else "deterministic"

        job_title = session.job.title if session.job else None
        company = session.job.company if session.job else None

        return SessionEvaluationReport(
            session_id=session.id,
            candidate_id=session.user_id,
            job_id=session.job_id,
            job_title=job_title,
            company=company,
            status=session.status,
            started_at=session.started_at,
            completed_at=session.completed_at,
            total_questions=total_questions,
            answered_questions=answered_count,
            evaluated_questions=evaluated_count,
            average_overall_score=avg_100,
            average_rubric_score=avg_4,
            question_evaluations=question_summaries,
            aggregated_strengths=dedup_strengths,
            aggregated_improvements=dedup_improvements,
            evaluation_limitations=STANDARD_LIMITATIONS_DISCLAIMER,
            evaluator_type=primary_evaluator,
            is_complete=(session.status == SessionStatus.COMPLETED.value and evaluated_count >= total_questions),
        )
