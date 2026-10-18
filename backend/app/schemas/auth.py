from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator
from app.models.user import UserRole


class UserRegister(BaseModel):
    """Registration schema with email normalization and privilege escalation prevention."""
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128, description="User password (min 8 characters)")
    full_name: Optional[str] = Field(default=None, max_length=150)
    role: str = Field(default=UserRole.CANDIDATE.value, description="Assigned role (candidate or recruiter)")

    @field_validator("email")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.strip().lower()

    @field_validator("role")
    @classmethod
    def validate_public_registration_role(cls, v: str) -> str:
        role_lower = v.strip().lower()
        allowed = {UserRole.CANDIDATE.value, UserRole.RECRUITER.value}
        if role_lower not in allowed:
            raise ValueError(f"Role must be one of {allowed}. Public registration as admin is prohibited.")
        return role_lower


class UserLogin(BaseModel):
    """User login request schema."""
    email: EmailStr
    password: str = Field(..., min_length=1, max_length=128)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.strip().lower()


class TokenResponse(BaseModel):
    """JWT access token and refresh token response schema."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int = Field(description="Access token lifespan in seconds")


class TokenRefreshRequest(BaseModel):
    """Refresh token rotation request schema."""
    refresh_token: str = Field(..., min_length=1)


class UserResponse(BaseModel):
    """Public user profile schema."""
    id: str
    email: str
    full_name: Optional[str] = None
    role: str
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
