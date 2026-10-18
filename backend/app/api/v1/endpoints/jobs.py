"""Job Description Management API Endpoints."""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.api.deps import get_current_active_user, get_db, require_role
from app.models.resume import JobDescription
from app.models.user import User, UserRole
from app.schemas.job import JobCreate, JobResponse, JobUpdate

router = APIRouter()


@router.post(
    "/",
    response_model=JobResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new job description (Recruiter/Admin only)",
)
def create_job(
    job_in: JobCreate,
    current_user: User = Depends(require_role(UserRole.RECRUITER.value, UserRole.ADMIN.value)),
    db: Session = Depends(get_db),
) -> JobDescription:
    """Create a new job posting with skill criteria and experience requirements."""
    job = JobDescription(
        recruiter_id=current_user.id,
        title=job_in.title,
        company=job_in.company,
        description=job_in.description,
        required_skills=job_in.required_skills,
        preferred_skills=job_in.preferred_skills,
        min_experience_years=job_in.min_experience_years,
        education_requirements=job_in.education_requirements,
    )
    db.add(job)
    db.commit()
    db.refresh(job)
    return job


@router.get(
    "/",
    response_model=List[JobResponse],
    summary="List available job descriptions",
)
def list_jobs(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> List[JobDescription]:
    """
    List jobs accessible to the current user.
    Candidates and recruiters can view all active job postings.
    """
    return db.query(JobDescription).order_by(JobDescription.created_at.desc()).all()


@router.get(
    "/{job_id}",
    response_model=JobResponse,
    summary="Get job description by ID",
)
def get_job(
    job_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> JobDescription:
    """Retrieve detailed job requirements."""
    job = db.query(JobDescription).filter(JobDescription.id == job_id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job description not found")
    return job


@router.patch(
    "/{job_id}",
    response_model=JobResponse,
    summary="Update a job description (Owner recruiter or admin only)",
)
def update_job(
    job_id: str,
    job_in: JobUpdate,
    current_user: User = Depends(require_role(UserRole.RECRUITER.value, UserRole.ADMIN.value)),
    db: Session = Depends(get_db),
) -> JobDescription:
    """Update an existing job description."""
    job = db.query(JobDescription).filter(JobDescription.id == job_id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job description not found")

    if job.recruiter_id != current_user.id and current_user.role != UserRole.ADMIN.value:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to update this job description.",
        )

    update_data = job_in.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(job, field, val)

    db.commit()
    db.refresh(job)
    return job


@router.delete(
    "/{job_id}",
    summary="Delete a job description (Owner recruiter or admin only)",
)
def delete_job(
    job_id: str,
    current_user: User = Depends(require_role(UserRole.RECRUITER.value, UserRole.ADMIN.value)),
    db: Session = Depends(get_db),
) -> dict:
    """Delete a job description."""
    job = db.query(JobDescription).filter(JobDescription.id == job_id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job description not found")

    if job.recruiter_id != current_user.id and current_user.role != UserRole.ADMIN.value:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to delete this job description.",
        )

    db.delete(job)
    db.commit()
    return {"message": "Job description deleted successfully"}
