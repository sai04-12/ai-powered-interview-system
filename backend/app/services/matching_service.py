"""Deterministic Resume-to-Job Matching and Skill Gap Analysis Service."""
import re
from typing import Any, Dict, List, Optional, Set, Tuple
from app.models.resume import JobDescription, Resume


class MatchingError(Exception):
    """Sanitized exception for matching engine errors."""
    pass


class MatchingService:
    """Service evaluating candidates against job description requirements transparently and deterministically."""

    @staticmethod
    def _normalize_skill(skill: str) -> str:
        """Normalize a skill token for fuzzy and case-insensitive comparison."""
        cleaned = re.sub(r"[^\w\+\#\.]", "", skill.strip().lower())
        return cleaned

    @classmethod
    def calculate_match(
        cls,
        resume: Resume,
        job: JobDescription,
    ) -> Dict[str, Any]:
        """
        Evaluate candidate resume against a job description.
        Returns complete breakdown of scores, matched skills, missing skills, explanation, and limitations.
        """
        # 1. Validation of Extraction State
        if resume.extraction_status != "completed" or not resume.raw_text:
            raise MatchingError(
                "Cannot perform job matching: resume text extraction is incomplete, pending, or failed."
            )

        structured_data = resume.structured_data or {}
        extracted_skills = structured_data.get("skills", [])
        resume_text_lower = (resume.raw_text or "").lower()

        # Normalized set of candidate skills
        candidate_skill_tokens: Set[str] = {
            cls._normalize_skill(s) for s in extracted_skills if s.strip()
        }

        # 2. Skill Matching (Required vs Preferred)
        required_skills = job.required_skills or []
        preferred_skills = job.preferred_skills or []

        matched_skills: List[Dict[str, Any]] = []
        missing_skills: List[str] = []

        # Check required skills
        matched_required_count = 0
        for req in required_skills:
            norm_req = cls._normalize_skill(req)
            # Direct token match or substring in text
            if norm_req in candidate_skill_tokens or re.search(rf"\b{re.escape(norm_req)}\b", resume_text_lower):
                matched_required_count += 1
                matched_skills.append({
                    "skill": req,
                    "is_required": True,
                    "evidence": f"Identified in resume skills or profile text matching '{req}'",
                })
            else:
                missing_skills.append(req)

        # Check preferred skills
        matched_preferred_count = 0
        for pref in preferred_skills:
            norm_pref = cls._normalize_skill(pref)
            if norm_pref in candidate_skill_tokens or re.search(rf"\b{re.escape(norm_pref)}\b", resume_text_lower):
                matched_preferred_count += 1
                matched_skills.append({
                    "skill": pref,
                    "is_required": False,
                    "evidence": f"Identified preferred skill '{pref}'",
                })

        # Calculate Skill Score (75% weight on required, 25% weight on preferred)
        if required_skills:
            req_ratio = matched_required_count / len(required_skills)
        else:
            req_ratio = 1.0

        if preferred_skills:
            pref_ratio = matched_preferred_count / len(preferred_skills)
        else:
            pref_ratio = req_ratio

        skill_score = round(((req_ratio * 0.75) + (pref_ratio * 0.25)) * 100.0, 1)

        # 3. Experience Score
        candidate_years = structured_data.get("total_experience_years")
        min_years = job.min_experience_years

        if min_years is not None and min_years > 0:
            if candidate_years is not None:
                if candidate_years >= min_years:
                    experience_score = 100.0
                else:
                    # Partial credit proportional to years documented
                    experience_score = round(min(100.0, (candidate_years / min_years) * 100.0), 1)
            else:
                # Experience is unverified/unspecified
                experience_score = 50.0
        else:
            # No specific experience duration required by job
            experience_score = 100.0 if candidate_years is not None else 80.0

        # 4. Education Score (if job specifies education requirement)
        education_score: Optional[float] = None
        education_items = structured_data.get("education", [])
        if job.education_requirements:
            req_edu_lower = job.education_requirements.lower()
            if any(
                req_edu_lower in (edu.get("degree", "") or "").lower() or
                req_edu_lower in (edu.get("field_of_study", "") or "").lower()
                for edu in education_items
            ) or (education_items and any("degree" in (e.get("degree", "") or "").lower() or "bachelor" in (e.get("degree", "") or "").lower() for e in education_items)):
                education_score = 100.0
            elif education_items:
                education_score = 75.0
            else:
                education_score = 50.0

        # 5. Overall Match Score Calculation
        # Weights: Skills = 60%, Experience = 25%, Education = 15% (or 70% skills / 30% exp if no edu required)
        if education_score is not None:
            overall_score = round(
                (skill_score * 0.60) + (experience_score * 0.25) + (education_score * 0.15),
                1
            )
        else:
            overall_score = round(
                (skill_score * 0.70) + (experience_score * 0.30),
                1
            )

        # 6. Detailed Explanation
        explanation_lines = [
            f"Overall Match: {overall_score}% based on documented skills and qualifications.",
            f"Skill Match: {skill_score}% — matched {matched_required_count} of {len(required_skills)} required skills, and {matched_preferred_count} of {len(preferred_skills)} preferred skills.",
        ]
        if min_years:
            doc_exp = f"{candidate_years} years" if candidate_years is not None else "Unspecified"
            explanation_lines.append(
                f"Experience: {experience_score}% — target requirement is {min_years}+ years; resume indicates {doc_exp}."
            )
        if education_score is not None:
            explanation_lines.append(
                f"Education: {education_score}% — evaluated against requirement '{job.education_requirements}'."
            )
        if missing_skills:
            explanation_lines.append(
                f"Missing or Unverified Required Skills: {', '.join(missing_skills)}."
            )

        explanation = "\n".join(explanation_lines)

        # 7. Limitations & Ethical Notice
        limitations = (
            "Notice & Limitations:\n"
            "1. This match score is computed using transparent keyword heuristics and resume section analysis.\n"
            "2. The absence of a skill keyword does not guarantee the candidate lacks competency, only that it is not documented in the submitted resume file.\n"
            "3. Match scores do not predict actual interview or job performance and must never be used as an automated basis for adverse employment decisions.\n"
            "4. Protected personal demographics and characteristics are excluded from evaluation."
        )

        return {
            "overall_score": overall_score,
            "skill_score": skill_score,
            "experience_score": experience_score,
            "education_score": education_score,
            "matched_skills": matched_skills,
            "missing_skills": missing_skills,
            "explanation": explanation,
            "limitations": limitations,
        }
