from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.team import TeamMemberStatus
from app.models.user import UserRole
from app.schemas.user import UserRead


class BrandingUpdate(BaseModel):
    school_name: str = Field(min_length=2, max_length=140)
    school_abbreviation: str | None = Field(default=None, max_length=12)
    mascot_name: str = Field(min_length=2, max_length=120)
    primary_color: str = Field(pattern=r"^#[0-9A-Fa-f]{6}$")
    secondary_color: str = Field(pattern=r"^#[0-9A-Fa-f]{6}$")
    accent_color: str = Field(pattern=r"^#[0-9A-Fa-f]{6}$")
    surface_color: str = Field(pattern=r"^#[0-9A-Fa-f]{6}$")
    logo_url: str | None = None
    tagline: str | None = Field(default=None, max_length=180)
    dark_mode: bool = True


class TeamCreate(BrandingUpdate):
    name: str = Field(min_length=2, max_length=120)
    slug: str = Field(min_length=2, max_length=120, pattern=r"^[a-z0-9-]+$")
    join_code: str = Field(min_length=4, max_length=12, pattern=r"^[A-Z0-9]+$")
    division: str | None = Field(default=None, max_length=50)
    season_label: str | None = Field(default=None, max_length=30)


class TeamMemberRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    role_label: str
    is_staff: bool
    status: TeamMemberStatus
    user: UserRead


class TeamRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    slug: str
    join_code: str
    school_name: str
    school_abbreviation: str | None
    mascot_name: str
    division: str | None
    season_label: str | None
    dark_mode: bool
    primary_color: str
    secondary_color: str
    accent_color: str
    surface_color: str
    logo_url: str | None
    tagline: str | None
    created_by_user_id: int
    created_at: datetime
    members: list[TeamMemberRead] = []


class TeamJoinRequest(BaseModel):
    join_code: str = Field(min_length=4, max_length=12, pattern=r"^[A-Z0-9]+$")


class TeamMembershipCreate(BaseModel):
    user_id: int
    role_label: str = Field(min_length=2, max_length=60)
    is_staff: bool = False


class TeamMemberStatusUpdate(BaseModel):
    status: TeamMemberStatus


class JoinCodeRotateResponse(BaseModel):
    join_code: str


class TeamLookupRead(BaseModel):
    id: int
    name: str
    school_name: str
    mascot_name: str
    division: str | None


class AthleteRosterProfile(BaseModel):
    user_id: int
    membership_id: int
    full_name: str
    role: UserRole
    role_label: str
    hometown: str | None
    graduation_year: int | None
    weight_class: str | None
    profile_image_url: str | None


class AthleteDetail(AthleteRosterProfile):
    email: str
    phone: str | None
    bio: str | None
    primary_team_id: int | None
    joined_team_at: datetime
