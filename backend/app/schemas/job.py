"""Job Description Pydantic Schemas."""
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field


class JobCreate(BaseModel):
    title: str = Field(..., min_length=2, max_length=200)
    company: Optional[str] = Field(None, max_length=200)
    description: str = Field(..., min_length=10)
    required_skills: List[str] = Field(..., min_length=1)
    preferred_skills: List[str] = Field(default_factory=list)
    min_experience_years: Optional[int] = Field(None, ge=0)
    education_requirements: Optional[str] = Field(None, max_length=255)


class JobUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=2, max_length=200)
    company: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = Field(None, min_length=10)
    required_skills: Optional[List[str]] = None
    preferred_skills: Optional[List[str]] = None
    min_experience_years: Optional[int] = Field(None, ge=0)
    education_requirements: Optional[str] = Field(None, max_length=255)


class JobResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    recruiter_id: str
    title: str
    company: Optional[str] = None
    description: str
    required_skills: List[str] = Field(default_factory=list)
    preferred_skills: List[str] = Field(default_factory=list)
    min_experience_years: Optional[int] = None
    education_requirements: Optional[str] = None
    created_at: datetime
    updated_at: datetime
