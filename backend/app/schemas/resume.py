"""Resume Pydantic Schemas."""
from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field


class EducationItem(BaseModel):
    degree: Optional[str] = None
    field_of_study: Optional[str] = None
    institution: Optional[str] = None
    graduation_year: Optional[int] = None


class ExperienceItem(BaseModel):
    title: Optional[str] = None
    company: Optional[str] = None
    duration_years: Optional[float] = None
    description: Optional[str] = None


class ProjectItem(BaseModel):
    name: str
    description: Optional[str] = None
    technologies: List[str] = Field(default_factory=list)


class ResumeStructuredData(BaseModel):
    professional_summary: Optional[str] = None
    skills: List[str] = Field(default_factory=list)
    education: List[EducationItem] = Field(default_factory=list)
    work_experience: List[ExperienceItem] = Field(default_factory=list)
    projects: List[ProjectItem] = Field(default_factory=list)
    certifications: List[str] = Field(default_factory=list)
    total_experience_years: Optional[float] = None
    technologies: List[str] = Field(default_factory=list)
    missing_or_ambiguous: List[str] = Field(default_factory=list)
    requires_ocr: bool = False


class ResumeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    filename: str
    file_type: str
    file_size: int
    extraction_status: str
    raw_text: Optional[str] = None
    structured_data: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: datetime
