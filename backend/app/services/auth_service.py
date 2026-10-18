from datetime import datetime, timedelta, timezone
from typing import Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.security import (
    create_access_token,
    generate_refresh_token_pair,
    hash_password,
    hash_token_identifier,
    verify_password,
)
from app.models.user import RefreshToken, User
from app.schemas.auth import TokenResponse, UserRegister


class AuthService:
    """Authentication service managing registration, credential verification, and token rotation."""

    @staticmethod
    def register_user(db: Session, register_data: UserRegister) -> User:
        """Register a new candidate or recruiter user."""
        normalized_email = register_data.email.strip().lower()

        # Check existing user
        existing_user = db.query(User).filter(User.email == normalized_email).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="A user with this email address already exists.",
            )

        hashed_pw = hash_password(register_data.password)
        new_user = User(
            email=normalized_email,
            hashed_password=hashed_pw,
            full_name=register_data.full_name,
            role=register_data.role,
            is_active=True,
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        return new_user

    @staticmethod
    def authenticate_user(db: Session, email: str, password: str) -> User:
        """Verify credentials and return user.
        
        Returns generic error detail to avoid user enumeration.
        """
        normalized_email = email.strip().lower()
        user = db.query(User).filter(User.email == normalized_email).first()

        # Prevent timing attacks and user enumeration
        if not user or not verify_password(password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account has been deactivated. Please contact support.",
            )

        return user

    @staticmethod
    def create_token_response(db: Session, user: User) -> TokenResponse:
        """Issue an access token and create a persisted refresh token."""
        access_token = create_access_token(subject=user.id, role=user.role)
        raw_refresh, token_hash = generate_refresh_token_pair()

        refresh_record = RefreshToken(
            token_hash=token_hash,
            user_id=user.id,
            expires_at=datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
            is_revoked=False,
        )
        db.add(refresh_record)
        db.commit()

        return TokenResponse(
            access_token=access_token,
            refresh_token=raw_refresh,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        )

    @staticmethod
    def rotate_refresh_token(db: Session, raw_refresh_token: str) -> TokenResponse:
        """Rotate refresh token: revoke current token and issue new token pair.
        
        If a revoked token is presented, treats it as possible token theft and revokes all active tokens.
        """
        token_hash = hash_token_identifier(raw_refresh_token)
        record = db.query(RefreshToken).filter(RefreshToken.token_hash == token_hash).first()

        if not record:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or unrecognized refresh token.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # Check for token reuse / replay
        if record.is_revoked:
            # Revoke all tokens for this user for security
            db.query(RefreshToken).filter(
                RefreshToken.user_id == record.user_id,
                RefreshToken.is_revoked == False,
            ).update({"is_revoked": True})
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Revoked refresh token presented. All sessions have been terminated for security.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # Check expiry
        now = datetime.now(timezone.utc)
        record_expires_at = record.expires_at if record.expires_at.tzinfo else record.expires_at.replace(tzinfo=timezone.utc)
        if record_expires_at < now:
            record.is_revoked = True
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token has expired. Please log in again.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        user = db.query(User).filter(User.id == record.user_id).first()
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Associated user is invalid or inactive.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # Invalidate old token
        new_raw_refresh, new_token_hash = generate_refresh_token_pair()
        record.is_revoked = True
        record.replaced_by_hash = new_token_hash

        # Create new token record
        new_record = RefreshToken(
            token_hash=new_token_hash,
            user_id=user.id,
            expires_at=now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
            is_revoked=False,
        )
        db.add(new_record)
        db.commit()

        new_access_token = create_access_token(subject=user.id, role=user.role)
        return TokenResponse(
            access_token=new_access_token,
            refresh_token=new_raw_refresh,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        )

    @staticmethod
    def revoke_token(db: Session, raw_refresh_token: str) -> None:
        """Revoke a specific refresh token during logout."""
        token_hash = hash_token_identifier(raw_refresh_token)
        record = db.query(RefreshToken).filter(RefreshToken.token_hash == token_hash).first()
        if record and not record.is_revoked:
            record.is_revoked = True
            db.commit()
