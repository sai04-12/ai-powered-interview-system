"""Pydantic Request & Response Schemas Package."""
from app.schemas.auth import (
    TokenRefreshRequest,
    TokenResponse,
    UserLogin,
    UserRegister,
    UserResponse,
)
from app.schemas.evaluation import (
    AnswerEvaluationRequest,
    AnswerEvaluationResponse,
    CriterionScoreResponse,
    SessionEvaluationReport,
    SessionQuestionEvaluationSummary,
)
from app.schemas.health import DatabaseHealthResponse, HealthResponse
from app.schemas.interview import (
    InterviewAnswerResponse,
    InterviewAnswerSubmit,
    InterviewNextResult,
    InterviewQuestionResponse,
    InterviewSessionCreate,
    InterviewSessionResponse,
    InterviewSessionSummary,
)
from app.schemas.job import JobCreate, JobResponse, JobUpdate
from app.schemas.match import MatchedSkillItem, MatchResponse
from app.schemas.resume import (
    EducationItem,
    ExperienceItem,
    ProjectItem,
    ResumeResponse,
    ResumeStructuredData,
)

__all__ = [
    "HealthResponse",
    "DatabaseHealthResponse",
    "UserRegister",
    "UserLogin",
    "TokenResponse",
    "TokenRefreshRequest",
    "UserResponse",
    "EducationItem",
    "ExperienceItem",
    "ProjectItem",
    "ResumeStructuredData",
    "ResumeResponse",
    "JobCreate",
    "JobUpdate",
    "JobResponse",
    "MatchedSkillItem",
    "MatchResponse",
    "InterviewSessionCreate",
    "InterviewQuestionResponse",
    "InterviewAnswerSubmit",
    "InterviewAnswerResponse",
    "InterviewSessionResponse",
    "InterviewSessionSummary",
    "InterviewNextResult",
    "CriterionScoreResponse",
    "AnswerEvaluationResponse",
    "AnswerEvaluationRequest",
    "SessionQuestionEvaluationSummary",
    "SessionEvaluationReport",
]
