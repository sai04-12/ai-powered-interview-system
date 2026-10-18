from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.api.deps import get_current_active_user, get_db, require_role
from app.models.user import User, UserRole
from app.schemas.auth import (
    TokenRefreshRequest,
    TokenResponse,
    UserLogin,
    UserRegister,
    UserResponse,
)
from app.services.auth_service import AuthService

router = APIRouter()


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register new user account",
)
def register(
    user_data: UserRegister,
    db: Session = Depends(get_db),
) -> UserResponse:
    """Register a new candidate or recruiter account.
    
    Public self-registration as admin is prohibited.
    """
    user = AuthService.register_user(db, user_data)
    return UserResponse.model_validate(user)


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Authenticate and receive JWT tokens",
)
def login(
    login_data: UserLogin,
    db: Session = Depends(get_db),
) -> TokenResponse:
    """Verify credentials and issue access + refresh tokens."""
    user = AuthService.authenticate_user(db, login_data.email, login_data.password)
    return AuthService.create_token_response(db, user)


@router.post(
    "/refresh",
    response_model=TokenResponse,
    summary="Rotate refresh token and issue new access token",
)
def refresh_token(
    refresh_data: TokenRefreshRequest,
    db: Session = Depends(get_db),
) -> TokenResponse:
    """Exchange valid refresh token for a new access token and rotated refresh token."""
    return AuthService.rotate_refresh_token(db, refresh_data.refresh_token)


@router.post(
    "/logout",
    status_code=status.HTTP_200_OK,
    summary="Revoke refresh token and end session",
)
def logout(
    refresh_data: TokenRefreshRequest,
    db: Session = Depends(get_db),
):
    """Revoke refresh token on logout."""
    AuthService.revoke_token(db, refresh_data.refresh_token)
    return {"message": "Logged out successfully"}


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Retrieve current authenticated user profile",
)
def get_me(
    current_user: User = Depends(get_current_active_user),
) -> UserResponse:
    """Return profile of the currently logged-in user."""
    return UserResponse.model_validate(current_user)


@router.get(
    "/test-role/recruiter",
    summary="Recruiter & Admin protected verification endpoint",
)
def test_recruiter_endpoint(
    current_user: User = Depends(require_role(UserRole.RECRUITER.value, UserRole.ADMIN.value)),
):
    """Protected endpoint restricted to recruiter and admin roles."""
    return {
        "message": f"Authorized for role {current_user.role}",
        "user_id": current_user.id,
        "email": current_user.email,
        "role": current_user.role,
    }


@router.get(
    "/test-role/admin",
    summary="Admin-only protected verification endpoint",
)
def test_admin_endpoint(
    current_user: User = Depends(require_role(UserRole.ADMIN.value)),
):
    """Protected endpoint strictly restricted to administrators."""
    return {
        "message": "Welcome administrator",
        "user_id": current_user.id,
        "email": current_user.email,
        "role": current_user.role,
    }
