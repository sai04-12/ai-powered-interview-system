"""Resume Management and Resume-to-Job Matching API Endpoints."""
import os
from typing import List
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session
from app.api.deps import get_current_active_user, get_db
from app.core.config import settings
from app.models.resume import JobDescription, Resume, ResumeJobMatch
from app.models.user import User, UserRole
from app.schemas.match import MatchResponse
from app.schemas.resume import ResumeResponse
from app.services.matching_service import MatchingError, MatchingService
from app.services.resume_service import ResumeParsingError, ResumeService

router = APIRouter()


@router.post(
    "/upload",
    response_model=ResumeResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload and process a PDF or DOCX resume",
)
async def upload_resume(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> Resume:
    """
    Upload and extract text/skills from a candidate resume file.
    Validates file extension, magic bytes, size limits, and sanitizes input.
    """
    try:
        content = await file.read()
        storage_key, mime_type, file_size, status_val, raw_text, structured_data = ResumeService.process_resume(
            filename=file.filename or "resume.pdf",
            content=content,
            upload_dir=settings.UPLOAD_DIR,
        )
    except ResumeParsingError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

    resume = Resume(
        user_id=current_user.id,
        filename=os.path.basename(file.filename or "resume.pdf"),
        storage_key=storage_key,
        file_type=mime_type,
        file_size=file_size,
        extraction_status=status_val,
        raw_text=raw_text,
        structured_data=structured_data,
    )
    db.add(resume)
    db.commit()
    db.refresh(resume)
    return resume


@router.get(
    "/",
    response_model=List[ResumeResponse],
    summary="List resumes owned by the current user",
)
def list_my_resumes(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> List[Resume]:
    """Retrieve all resumes uploaded by the current authenticated user."""
    if current_user.role == UserRole.ADMIN.value:
        return db.query(Resume).order_by(Resume.created_at.desc()).all()
    return db.query(Resume).filter(Resume.user_id == current_user.id).order_by(Resume.created_at.desc()).all()


@router.get(
    "/{resume_id}",
    response_model=ResumeResponse,
    summary="Get resume details and extraction status",
)
def get_resume(
    resume_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> Resume:
    """Retrieve an authorized resume by ID."""
    resume = db.query(Resume).filter(Resume.id == resume_id).first()
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found")

    # Access control: candidate can only view own resume; recruiters and admins can view
    if current_user.role not in [UserRole.RECRUITER.value, UserRole.ADMIN.value]:
        if resume.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to access this resume.",
            )

    return resume


@router.delete(
    "/{resume_id}",
    summary="Delete an owned resume and its stored file",
)
def delete_resume(
    resume_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> dict:
    """Delete a resume document and its underlying storage file."""
    resume = db.query(Resume).filter(Resume.id == resume_id).first()
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found")

    # Only owner or admin can delete
    if resume.user_id != current_user.id and current_user.role != UserRole.ADMIN.value:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to delete this resume.",
        )

    # Remove stored physical file safely
    file_path = os.path.join(settings.UPLOAD_DIR, resume.storage_key)
    if os.path.exists(file_path):
        try:
            os.remove(file_path)
        except OSError:
            pass

    db.delete(resume)
    db.commit()
    return {"message": "Resume deleted successfully"}


@router.post(
    "/{resume_id}/match/{job_id}",
    response_model=MatchResponse,
    summary="Calculate transparent match score between resume and job description",
)
def match_resume_to_job(
    resume_id: str,
    job_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> dict:
    """Evaluate candidate resume against a job description requirements."""
    resume = db.query(Resume).filter(Resume.id == resume_id).first()
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found")

    job = db.query(JobDescription).filter(JobDescription.id == job_id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job description not found")

    # Authorization: Owner candidate, recruiter owner of job, or admin
    is_owner_candidate = resume.user_id == current_user.id
    is_job_recruiter = job.recruiter_id == current_user.id
    is_admin = current_user.role == UserRole.ADMIN.value

    if not (is_owner_candidate or is_job_recruiter or is_admin):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to match this resume with the specified job.",
        )

    try:
        match_data = MatchingService.calculate_match(resume, job)
    except MatchingError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    # Persist or update match record
    match_record = db.query(ResumeJobMatch).filter(
        ResumeJobMatch.resume_id == resume_id,
        ResumeJobMatch.job_id == job_id,
    ).first()

    if not match_record:
        match_record = ResumeJobMatch(
            resume_id=resume_id,
            job_id=job_id,
            overall_score=match_data["overall_score"],
            skill_score=match_data["skill_score"],
            experience_score=match_data["experience_score"],
            education_score=match_data["education_score"],
            matched_skills=match_data["matched_skills"],
            missing_skills=match_data["missing_skills"],
            explanation=match_data["explanation"],
            limitations=match_data["limitations"],
        )
        db.add(match_record)
    else:
        match_record.overall_score = match_data["overall_score"]
        match_record.skill_score = match_data["skill_score"]
        match_record.experience_score = match_data["experience_score"]
        match_record.education_score = match_data["education_score"]
        match_record.matched_skills = match_data["matched_skills"]
        match_record.missing_skills = match_data["missing_skills"]
        match_record.explanation = match_data["explanation"]
        match_record.limitations = match_data["limitations"]

    db.commit()
    db.refresh(match_record)

    return {
        "id": match_record.id,
        "resume_id": match_record.resume_id,
        "job_id": match_record.job_id,
        "job_title": job.title,
        "candidate_id": resume.user_id,
        "overall_score": match_record.overall_score,
        "skill_score": match_record.skill_score,
        "experience_score": match_record.experience_score,
        "education_score": match_record.education_score,
        "matched_skills": match_record.matched_skills,
        "missing_skills": match_record.missing_skills,
        "explanation": match_record.explanation,
        "limitations": match_record.limitations,
        "created_at": match_record.created_at,
    }
