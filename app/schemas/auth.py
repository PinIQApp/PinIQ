from __future__ import annotations

from pydantic import BaseModel, EmailStr, Field

from app.models.user import UserRole
from app.services.phone_numbers import phone_number_field_validator


class Token(BaseModel):
    access_token: str
    refresh_token: str | None = None
    token_type: str = "bearer"


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    full_name: str = Field(min_length=2, max_length=120)
    role: UserRole
    phone: str | None = None
    profile_image_url: str | None = Field(default=None, max_length=500)
    hometown: str | None = Field(default=None, max_length=120)
    graduation_year: int | None = Field(default=None, ge=2000, le=2100)
    weight_class: str | None = Field(default=None, max_length=30)
    bio: str | None = Field(default=None, max_length=500)

    _normalize_phone = phone_number_field_validator("phone")


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class PasswordResetRequest(BaseModel):
    email: EmailStr


class PasswordResetConfirm(BaseModel):
    token: str
    new_password: str = Field(min_length=8)


class PasswordResetResponse(BaseModel):
    message: str
    reset_token: str | None = None


class EmailVerificationRequest(BaseModel):
    email: EmailStr


class EmailVerificationConfirm(BaseModel):
    token: str


class EmailVerificationResponse(BaseModel):
    message: str
    verification_token: str | None = None
