"""Resume, JobDescription, and ResumeJobMatch SQLAlchemy Models."""
from datetime import datetime, timezone
from enum import Enum
from typing import Any, Dict, List, Optional
from sqlalchemy import (
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.types import JSON
from app.models.base import Base, TimestampMixin, UUIDMixin


class ExtractionStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class Resume(Base, UUIDMixin, TimestampMixin):
    """Resume model storing uploaded candidate CV metadata, extracted text, and structured analysis."""
    __tablename__ = "resumes"

    user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    filename: Mapped[str] = mapped_column(String(255), nullable=False)
    storage_key: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    file_type: Mapped[str] = mapped_column(String(100), nullable=False)
    file_size: Mapped[int] = mapped_column(Integer, nullable=False)
    extraction_status: Mapped[str] = mapped_column(
        String(50),
        default=ExtractionStatus.PENDING.value,
        index=True,
        nullable=False,
    )
    raw_text: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    structured_data: Mapped[Optional[Dict[str, Any]]] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"),
        nullable=True,
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="resumes")
    matches: Mapped[List["ResumeJobMatch"]] = relationship(
        "ResumeJobMatch",
        back_populates="resume",
        cascade="all, delete-orphan",
        lazy="selectin",
    )

    def __repr__(self) -> str:
        return f"<Resume id='{self.id}' user_id='{self.user_id}' status='{self.extraction_status}'>"


class JobDescription(Base, UUIDMixin, TimestampMixin):
    """Job description entity managed by recruiters with skill requirements and criteria."""
    __tablename__ = "job_descriptions"

    recruiter_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    title: Mapped[str] = mapped_column(String(200), index=True, nullable=False)
    company: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    required_skills: Mapped[List[str]] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"),
        default=list,
        nullable=False,
    )
    preferred_skills: Mapped[List[str]] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"),
        default=list,
        nullable=False,
    )
    min_experience_years: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    education_requirements: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    # Relationships
    recruiter: Mapped["User"] = relationship("User", back_populates="job_descriptions")
    matches: Mapped[List["ResumeJobMatch"]] = relationship(
        "ResumeJobMatch",
        back_populates="job_description",
        cascade="all, delete-orphan",
        lazy="selectin",
    )

    def __repr__(self) -> str:
        return f"<JobDescription id='{self.id}' title='{self.title}' recruiter_id='{self.recruiter_id}'>"


class ResumeJobMatch(Base, UUIDMixin):
    """Evaluation match record between a parsed resume and target job opening."""
    __tablename__ = "resume_job_matches"
    __table_args__ = (
        UniqueConstraint("resume_id", "job_id", name="uq_resume_job_match"),
    )

    resume_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("resumes.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    job_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("job_descriptions.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    overall_score: Mapped[float] = mapped_column(Float, nullable=False)
    skill_score: Mapped[float] = mapped_column(Float, nullable=False)
    experience_score: Mapped[float] = mapped_column(Float, nullable=False)
    education_score: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    matched_skills: Mapped[List[Dict[str, Any]]] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"),
        default=list,
        nullable=False,
    )
    missing_skills: Mapped[List[str]] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"),
        default=list,
        nullable=False,
    )
    explanation: Mapped[str] = mapped_column(Text, nullable=False)
    limitations: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    resume: Mapped["Resume"] = relationship("Resume", back_populates="matches")
    job_description: Mapped["JobDescription"] = relationship("JobDescription", back_populates="matches")

    def __repr__(self) -> str:
        return f"<ResumeJobMatch id='{self.id}' resume_id='{self.resume_id}' job_id='{self.job_id}' score={self.overall_score}>"
