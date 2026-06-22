from __future__ import annotations

from datetime import datetime, timedelta

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import (
    create_access_token,
    generate_opaque_token,
    get_password_hash,
    hash_opaque_token,
    validate_password_strength,
    verify_password,
)
from app.db.session import get_db
from app.models.user import EmailVerificationToken, PasswordResetToken, RefreshToken, User
from app.schemas.auth import (
    EmailVerificationConfirm,
    EmailVerificationRequest,
    EmailVerificationResponse,
    LoginRequest,
    PasswordResetConfirm,
    PasswordResetRequest,
    PasswordResetResponse,
    RefreshTokenRequest,
    RegisterRequest,
    Token,
)
from app.schemas.common import MessageResponse
from app.schemas.user import UserRead
from app.services.auth_audit import log_auth_event
from app.services.email_tasks import send_email_verification_email, send_password_reset_email
from app.services.rate_limit import auth_rate_limiter


router = APIRouter(prefix="/auth", tags=["auth"])


def _client_identifier(request: Request) -> str:
    return request.client.host if request.client else "unknown"


def _issue_refresh_token(db: Session, user: User) -> str:
    raw_token = generate_opaque_token()
    refresh_token = RefreshToken(
        user_id=user.id,
        token_hash=hash_opaque_token(raw_token),
        expires_at=datetime.utcnow() + timedelta(minutes=settings.refresh_token_expire_minutes),
    )
    db.add(refresh_token)
    db.flush()
    return raw_token


def _issue_email_verification_token(db: Session, user: User) -> str:
    raw_token = generate_opaque_token()
    verification_token = EmailVerificationToken(
        user_id=user.id,
        token_hash=hash_opaque_token(raw_token),
        expires_at=datetime.utcnow() + timedelta(minutes=settings.password_reset_token_expire_minutes),
    )
    db.add(verification_token)
    db.flush()
    return raw_token


@router.post("/register", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def register(
    payload: RegisterRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    existing = db.query(User).filter(User.email == payload.email.lower()).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    validate_password_strength(payload.password)

    user = User(
        email=payload.email.lower(),
        password_hash=get_password_hash(payload.password),
        full_name=payload.full_name,
        role=payload.role,
        phone=payload.phone,
        profile_image_url=payload.profile_image_url,
        hometown=payload.hometown,
        graduation_year=payload.graduation_year,
        weight_class=payload.weight_class,
        bio=payload.bio,
    )
    db.add(user)
    db.flush()
    if settings.environment in {"local", "test"}:
        preview_verification_token = _issue_email_verification_token(db, user)
    else:
        preview_verification_token = None
    db.commit()
    db.refresh(user)
    background_tasks.add_task(
        send_email_verification_email,
        email=user.email,
        verification_token=preview_verification_token,
    )
    log_auth_event("user_registered", user_id=user.id, email=user.email)
    return user


@router.post("/login", response_model=Token)
def login(payload: LoginRequest, request: Request, db: Session = Depends(get_db)):
    auth_rate_limiter.hit(
        db,
        f"login:{_client_identifier(request)}:{payload.email.lower()}",
        limit=settings.auth_rate_limit_attempts,
        window_seconds=settings.auth_rate_limit_window_seconds,
    )
    user = db.query(User).filter(User.email == payload.email.lower()).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=400, detail="Invalid email or password")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="User account is inactive")
    refresh_token = _issue_refresh_token(db, user)
    db.commit()
    log_auth_event("user_logged_in", user_id=user.id, email=user.email)
    return Token(access_token=create_access_token(user.id), refresh_token=refresh_token)


@router.post("/refresh", response_model=Token)
def refresh_access_token(payload: RefreshTokenRequest, db: Session = Depends(get_db)):
    token_hash = hash_opaque_token(payload.refresh_token)
    stored_token = (
        db.query(RefreshToken)
        .filter(RefreshToken.token_hash == token_hash)
        .first()
    )
    if not stored_token or stored_token.revoked_at is not None or stored_token.expires_at <= datetime.utcnow():
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    user = db.query(User).filter(User.id == stored_token.user_id).first()
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="Invalid refresh token")

    stored_token.revoked_at = datetime.utcnow()
    new_refresh_token = _issue_refresh_token(db, user)
    db.commit()
    log_auth_event("refresh_token_rotated", user_id=user.id, email=user.email)
    return Token(access_token=create_access_token(user.id), refresh_token=new_refresh_token)


@router.post("/logout", response_model=MessageResponse)
def logout(payload: RefreshTokenRequest, db: Session = Depends(get_db)):
    token_hash = hash_opaque_token(payload.refresh_token)
    stored_token = db.query(RefreshToken).filter(RefreshToken.token_hash == token_hash).first()
    if stored_token and stored_token.revoked_at is None:
        stored_token.revoked_at = datetime.utcnow()
        log_auth_event("user_logged_out", user_id=stored_token.user_id)
        db.commit()
    return MessageResponse(message="Logged out successfully")


@router.post("/password-reset/request", response_model=PasswordResetResponse)
def request_password_reset(
    payload: PasswordResetRequest,
    request: Request,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    auth_rate_limiter.hit(
        db,
        f"password-reset:{_client_identifier(request)}:{payload.email.lower()}",
        limit=settings.auth_rate_limit_attempts,
        window_seconds=settings.auth_rate_limit_window_seconds,
    )
    user = db.query(User).filter(User.email == payload.email.lower()).first()
    preview_token: str | None = None
    if user and user.is_active:
        raw_token = generate_opaque_token()
        reset_token = PasswordResetToken(
            user_id=user.id,
            token_hash=hash_opaque_token(raw_token),
            expires_at=datetime.utcnow() + timedelta(minutes=settings.password_reset_token_expire_minutes),
        )
        db.add(reset_token)
        db.commit()
        if settings.environment in {"local", "test"}:
            preview_token = raw_token
        background_tasks.add_task(send_password_reset_email, email=user.email, reset_token=preview_token)
        log_auth_event("password_reset_requested", user_id=user.id, email=user.email)

    return PasswordResetResponse(
        message="If an account exists for that email, reset instructions have been generated.",
        reset_token=preview_token,
    )


@router.post("/password-reset/confirm", response_model=MessageResponse)
def confirm_password_reset(payload: PasswordResetConfirm, db: Session = Depends(get_db)):
    validate_password_strength(payload.new_password)
    token_hash = hash_opaque_token(payload.token)
    reset_token = (
        db.query(PasswordResetToken)
        .filter(PasswordResetToken.token_hash == token_hash)
        .first()
    )
    if not reset_token or reset_token.used_at is not None or reset_token.expires_at <= datetime.utcnow():
        raise HTTPException(status_code=400, detail="Invalid or expired password reset token")

    user = db.query(User).filter(User.id == reset_token.user_id).first()
    if not user or not user.is_active:
        raise HTTPException(status_code=400, detail="Invalid or expired password reset token")

    user.password_hash = get_password_hash(payload.new_password)
    reset_token.used_at = datetime.utcnow()
    for refresh_token in user.refresh_tokens:
        if refresh_token.revoked_at is None:
            refresh_token.revoked_at = datetime.utcnow()
    db.commit()
    log_auth_event("password_reset_completed", user_id=user.id, email=user.email)
    return MessageResponse(message="Password has been reset successfully")


@router.post("/email-verification/request", response_model=EmailVerificationResponse)
def request_email_verification(
    payload: EmailVerificationRequest,
    request: Request,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    auth_rate_limiter.hit(
        db,
        f"email-verification:{_client_identifier(request)}:{payload.email.lower()}",
        limit=settings.auth_rate_limit_attempts,
        window_seconds=settings.auth_rate_limit_window_seconds,
    )
    user = db.query(User).filter(User.email == payload.email.lower()).first()
    preview_token: str | None = None
    if user and user.is_active and not user.email_verified:
        preview_token = _issue_email_verification_token(db, user)
        db.commit()
        if settings.environment not in {"local", "test"}:
            preview_token = None
        background_tasks.add_task(
            send_email_verification_email,
            email=user.email,
            verification_token=preview_token,
        )
        log_auth_event("email_verification_requested", user_id=user.id, email=user.email)

    return EmailVerificationResponse(
        message="If an account exists for that email, verification instructions have been generated.",
        verification_token=preview_token,
    )


@router.post("/email-verification/confirm", response_model=MessageResponse)
def confirm_email_verification(payload: EmailVerificationConfirm, db: Session = Depends(get_db)):
    token_hash = hash_opaque_token(payload.token)
    verification_token = (
        db.query(EmailVerificationToken)
        .filter(EmailVerificationToken.token_hash == token_hash)
        .first()
    )
    if (
        not verification_token
        or verification_token.used_at is not None
        or verification_token.expires_at <= datetime.utcnow()
    ):
        raise HTTPException(status_code=400, detail="Invalid or expired email verification token")

    user = db.query(User).filter(User.id == verification_token.user_id).first()
    if not user or not user.is_active:
        raise HTTPException(status_code=400, detail="Invalid or expired email verification token")

    user.email_verified = True
    verification_token.used_at = datetime.utcnow()
    db.commit()
    log_auth_event("email_verified", user_id=user.id, email=user.email)
    return MessageResponse(message="Email verified successfully")
