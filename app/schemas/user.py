from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models.user import UserRole
from app.services.phone_numbers import phone_number_field_validator


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    full_name: str
    role: UserRole
    phone: str | None
    profile_image_url: str | None
    hometown: str | None
    graduation_year: int | None
    weight_class: str | None
    bio: str | None
    is_active: bool
    email_verified: bool
    primary_team_id: int | None
    created_at: datetime


class UserUpdate(BaseModel):
    full_name: str = Field(min_length=2, max_length=120)
    phone: str | None = None
    profile_image_url: str | None = Field(default=None, max_length=500)
    hometown: str | None = Field(default=None, max_length=120)
    graduation_year: int | None = Field(default=None, ge=2000, le=2100)
    weight_class: str | None = Field(default=None, max_length=30)
    bio: str | None = Field(default=None, max_length=500)

    _normalize_phone = phone_number_field_validator("phone")


class PasswordChangeRequest(BaseModel):
    current_password: str
    new_password: str


class UserStatusUpdate(BaseModel):
    is_active: bool


class PushDeviceRegisterRequest(BaseModel):
    platform: str = Field(min_length=2, max_length=30)
    device_token: str = Field(min_length=8, max_length=255)


class PushDeviceRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    platform: str
    device_token: str
    push_enabled: bool
    created_at: datetime
    updated_at: datetime
    last_seen_at: datetime
