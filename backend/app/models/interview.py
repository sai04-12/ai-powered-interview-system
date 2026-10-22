"""InterviewSession, InterviewQuestion, and InterviewAnswer SQLAlchemy Models."""
from datetime import datetime, timezone
from enum import Enum
from typing import List, Optional
from sqlalchemy import (
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    JSON,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base, TimestampMixin, UUIDMixin


class SessionStatus(str, Enum):
    DRAFT = "draft"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    ABANDONED = "abandoned"


class EvaluationStatus(str, Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    FAILED = "failed"
    REQUIRES_REVIEW = "requires_review"


class QuestionDifficulty(str, Enum):
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"


class QuestionCategory(str, Enum):
    TECHNICAL = "technical"
    PROBLEM_SOLVING = "problem_solving"
    PROJECT_EXPERIENCE = "project_experience"
    BEHAVIORAL = "behavioral"


class QuestionSource(str, Enum):
    PREDEFINED = "predefined"
    GENERATED = "generated"
    ADAPTIVE_FOLLOW_UP = "adaptive_follow_up"


class InterviewSession(Base, UUIDMixin, TimestampMixin):
    """Interview session entity tracking candidate interview progression and question lifecycle."""
    __tablename__ = "interview_sessions"

    user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    job_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("job_descriptions.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    resume_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        ForeignKey("resumes.id", ondelete="SET NULL"),
        index=True,
        nullable=True,
    )
    status: Mapped[str] = mapped_column(
        String(50),
        default=SessionStatus.DRAFT.value,
        index=True,
        nullable=False,
    )
    current_question_index: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    total_question_count: Mapped[int] = mapped_column(Integer, default=5, nullable=False)
    started_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="interview_sessions")
    job: Mapped["JobDescription"] = relationship("JobDescription")
    resume: Mapped[Optional["Resume"]] = relationship("Resume")
    questions: Mapped[List["InterviewQuestion"]] = relationship(
        "InterviewQuestion",
        back_populates="session",
        cascade="all, delete-orphan",
        order_by="InterviewQuestion.question_order",
        lazy="selectin",
    )
    answers: Mapped[List["InterviewAnswer"]] = relationship(
        "InterviewAnswer",
        back_populates="session",
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    evaluations: Mapped[List["AnswerEvaluation"]] = relationship(
        "AnswerEvaluation",
        back_populates="session",
        cascade="all, delete-orphan",
        lazy="selectin",
    )

    def __repr__(self) -> str:
        return f"<InterviewSession id='{self.id}' user_id='{self.user_id}' status='{self.status}'>"


class InterviewQuestion(Base, UUIDMixin):
    """Question item assigned to a specific interview session with order and category metadata."""
    __tablename__ = "interview_questions"
    __table_args__ = (
        UniqueConstraint("session_id", "question_order", name="uq_session_question_order"),
    )

    session_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("interview_sessions.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    question_text: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[str] = mapped_column(String(50), nullable=False)
    skill: Mapped[str] = mapped_column(String(100), nullable=False)
    difficulty: Mapped[str] = mapped_column(
        String(20),
        default=QuestionDifficulty.MEDIUM.value,
        nullable=False,
    )
    question_order: Mapped[int] = mapped_column(Integer, nullable=False)
    question_source: Mapped[str] = mapped_column(
        String(50),
        default=QuestionSource.PREDEFINED.value,
        nullable=False,
    )
    selection_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    parent_question_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        ForeignKey("interview_questions.id", ondelete="SET NULL"),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    session: Mapped["InterviewSession"] = relationship("InterviewSession", back_populates="questions")
    parent_question: Mapped[Optional["InterviewQuestion"]] = relationship(
        "InterviewQuestion",
        remote_side="InterviewQuestion.id",
    )
    answer: Mapped[Optional["InterviewAnswer"]] = relationship(
        "InterviewAnswer",
        back_populates="question",
        uselist=False,
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    evaluations: Mapped[List["AnswerEvaluation"]] = relationship(
        "AnswerEvaluation",
        back_populates="question",
        cascade="all, delete-orphan",
        lazy="selectin",
    )

    def __repr__(self) -> str:
        return f"<InterviewQuestion id='{self.id}' order={self.question_order} skill='{self.skill}'>"


class InterviewAnswer(Base, UUIDMixin):
    """Candidate's submitted response to a specific question in an interview session."""
    __tablename__ = "interview_answers"
    __table_args__ = (
        UniqueConstraint("session_id", "question_id", name="uq_session_question_answer"),
    )

    session_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("interview_sessions.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    question_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("interview_questions.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    answer_text: Mapped[str] = mapped_column(Text, nullable=False)
    word_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    char_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    submitted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    revision_number: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    # Relationships
    session: Mapped["InterviewSession"] = relationship("InterviewSession", back_populates="answers")
    question: Mapped["InterviewQuestion"] = relationship("InterviewQuestion", back_populates="answer")
    evaluations: Mapped[List["AnswerEvaluation"]] = relationship(
        "AnswerEvaluation",
        back_populates="answer",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="desc(AnswerEvaluation.created_at)",
    )

    def __repr__(self) -> str:
        return f"<InterviewAnswer id='{self.id}' session_id='{self.session_id}' question_id='{self.question_id}'>"


class AnswerEvaluation(Base, UUIDMixin, TimestampMixin):
    """Evaluation record capturing transparent scoring, rubric breakdown, and answer evidence."""
    __tablename__ = "answer_evaluations"
    __table_args__ = (
        UniqueConstraint("answer_id", "answer_revision", "rubric_version", name="uq_answer_eval_revision_rubric"),
    )

    session_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("interview_sessions.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    answer_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("interview_answers.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    question_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("interview_questions.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    answer_revision: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    status: Mapped[str] = mapped_column(
        String(50),
        default=EvaluationStatus.PENDING.value,
        index=True,
        nullable=False,
    )
    rubric_version: Mapped[str] = mapped_column(String(20), default="1.0.0", nullable=False)
    overall_score: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    normalized_score: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    criteria_scores: Mapped[list] = mapped_column(JSON, default=list, nullable=False)
    evidence_excerpts: Mapped[list] = mapped_column(JSON, default=list, nullable=False)
    strengths: Mapped[list] = mapped_column(JSON, default=list, nullable=False)
    improvement_areas: Mapped[list] = mapped_column(JSON, default=list, nullable=False)
    evaluator_type: Mapped[str] = mapped_column(String(50), default="deterministic", nullable=False)
    provider_metadata: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    evaluation_limitations: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    feedback_summary: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True, nullable=False)

    # Relationships
    session: Mapped["InterviewSession"] = relationship("InterviewSession", back_populates="evaluations")
    answer: Mapped["InterviewAnswer"] = relationship("InterviewAnswer", back_populates="evaluations")
    question: Mapped["InterviewQuestion"] = relationship("InterviewQuestion", back_populates="evaluations")

    def __repr__(self) -> str:
        return f"<AnswerEvaluation id='{self.id}' answer_id='{self.answer_id}' status='{self.status}' overall_score={self.overall_score}>"
