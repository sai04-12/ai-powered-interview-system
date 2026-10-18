"""Resume-to-Job Match Pydantic Schemas."""
from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field


class MatchedSkillItem(BaseModel):
    skill: str
    is_required: bool = True
    evidence: Optional[str] = None


class MatchResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    resume_id: str
    job_id: str
    job_title: str
    candidate_id: str
    overall_score: float = Field(..., ge=0.0, le=100.0)
    skill_score: float = Field(..., ge=0.0, le=100.0)
    experience_score: float = Field(..., ge=0.0, le=100.0)
    education_score: Optional[float] = Field(None, ge=0.0, le=100.0)
    matched_skills: List[Dict[str, Any]] = Field(default_factory=list)
    missing_skills: List[str] = Field(default_factory=list)
    explanation: str
    limitations: str
    created_at: datetime
