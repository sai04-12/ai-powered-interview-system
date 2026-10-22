"""Pydantic schemas for Answer Evaluation and Session Evaluation Reports."""
from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field


class CriterionScoreResponse(BaseModel):
    """Evaluation score and explanation for an individual rubric criterion."""
    key: str
    name: str
    score: int = Field(..., ge=0, le=4, description="Score on 0-4 rubric scale")
    max_score: int = Field(default=4, description="Maximum possible score for criterion")
    base_weight: float
    normalized_weight: float
    explanation: str
    evidence_quote: Optional[str] = None
    is_applicable: bool = True

    model_config = ConfigDict(from_attributes=True)


class AnswerEvaluationResponse(BaseModel):
    """Complete rubric evaluation record for a candidate's submitted answer."""
    id: str
    session_id: str
    answer_id: str
    question_id: str
    answer_revision: int
    status: str
    rubric_version: str
    overall_score: Optional[float] = None
    normalized_score: Optional[float] = None
    criteria_scores: List[CriterionScoreResponse] = []
    evidence_excerpts: List[str] = []
    strengths: List[str] = []
    improvement_areas: List[str] = []
    evaluator_type: str
    provider_metadata: Optional[Dict[str, Any]] = None
    evaluation_limitations: Optional[str] = None
    feedback_summary: Optional[str] = None
    is_active: bool = True
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class AnswerEvaluationRequest(BaseModel):
    """Payload to trigger evaluation with optional forced re-evaluation."""
    force_reevaluate: bool = Field(
        default=False,
        description="Whether to supersede existing active evaluation and force fresh evaluation",
    )


class SessionQuestionEvaluationSummary(BaseModel):
    """Question item context paired with candidate answer and evaluation result."""
    question_id: str
    question_order: int
    question_text: str
    category: str
    skill: str
    difficulty: str
    answer_id: Optional[str] = None
    answer_revision: Optional[int] = None
    word_count: Optional[int] = None
    evaluation: Optional[AnswerEvaluationResponse] = None

    model_config = ConfigDict(from_attributes=True)


class SessionEvaluationReport(BaseModel):
    """Comprehensive interview session evaluation report."""
    session_id: str
    candidate_id: str
    job_id: str
    job_title: Optional[str] = None
    company: Optional[str] = None
    status: str
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    total_questions: int
    answered_questions: int
    evaluated_questions: int
    average_overall_score: Optional[float] = None  # 0.0 - 100.0
    average_rubric_score: Optional[float] = None   # 0.0 - 4.0
    question_evaluations: List[SessionQuestionEvaluationSummary] = []
    aggregated_strengths: List[str] = []
    aggregated_improvements: List[str] = []
    evaluation_limitations: str
    evaluator_type: str
    is_complete: bool = False

    model_config = ConfigDict(from_attributes=True)
