"""Interview Session, Question, and Answer Pydantic Schemas."""
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field


class InterviewSessionCreate(BaseModel):
    """Payload to initiate a new interview session."""
    job_id: str = Field(..., description="Target job description UUID")
    resume_id: Optional[str] = Field(None, description="Optional attached candidate resume UUID")
    total_questions: int = Field(default=5, ge=1, le=15, description="Number of questions in session")
    mode: Optional[str] = Field(default="mixed", description="Interview mode: technical, behavioral, or mixed")


class InterviewQuestionResponse(BaseModel):
    """Question item representation in an interview session."""
    id: str
    session_id: str
    question_text: str
    category: str
    skill: str
    difficulty: str
    question_order: int
    question_source: str
    selection_reason: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class InterviewAnswerSubmit(BaseModel):
    """Payload when submitting an answer to the current question."""
    answer_text: str = Field(
        ...,
        min_length=1,
        max_length=10000,
        description="Candidate's typed answer",
    )
    question_id: Optional[str] = Field(
        None,
        description="Optional question ID to verify submission alignment with active question in this session",
    )



class InterviewAnswerResponse(BaseModel):
    """Submitted answer record."""
    id: str
    session_id: str
    question_id: str
    answer_text: str
    word_count: int
    char_count: int
    submitted_at: datetime
    revision_number: int

    model_config = ConfigDict(from_attributes=True)


class InterviewSessionResponse(BaseModel):
    """Complete interview session state details."""
    id: str
    user_id: str
    job_id: str
    resume_id: Optional[str] = None
    status: str
    current_question_index: int
    total_question_count: int
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    job_title: Optional[str] = None
    company: Optional[str] = None
    current_question: Optional[InterviewQuestionResponse] = None

    model_config = ConfigDict(from_attributes=True)


class InterviewSessionSummary(BaseModel):
    """Lightweight session summary for lists and dashboards."""
    id: str
    job_id: str
    job_title: str
    company: Optional[str] = None
    status: str
    current_question_index: int
    total_question_count: int
    answered_count: int
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class InterviewNextResult(BaseModel):
    """Result of advancing to next question or completing session."""
    session: InterviewSessionResponse
    is_completed: bool
    next_question: Optional[InterviewQuestionResponse] = None
    adaptation_note: Optional[str] = None
