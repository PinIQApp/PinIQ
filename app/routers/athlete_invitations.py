from __future__ import annotations

from datetime import datetime, timedelta

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from sqlalchemy import func, or_
from sqlalchemy.orm import Session, joinedload

from app.core.config import settings
from app.core.security import generate_opaque_token, get_password_hash
from app.db.session import get_db
from app.models.messaging import ParentLink
from app.models.team import (
    AthleteInvitationStatus,
    AthleteParentInvitation,
    Team,
    TeamMember,
    TeamMemberStatus,
)
from app.models.user import User, UserRole
from app.routers.deps import get_current_user
from app.schemas.team import AthleteInvitationCreate, AthleteInvitationRead
from app.services.email_tasks import send_athlete_parent_invitation_email
from app.services.permissions import require_team_manager
from app.services.phone_numbers import normalize_phone_number
from app.services.sms_alerts import send_sms_message


router = APIRouter(tags=["athlete-invitations"])


def _load_team(db: Session, team_id: int) -> Team:
    team = (
        db.query(Team)
        .options(joinedload(Team.memberships).joinedload(TeamMember.user))
        .filter(Team.id == team_id)
        .first()
    )
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
    return team


def _load_invitation(db: Session, invitation_id: int) -> AthleteParentInvitation:
    invitation = (
        db.query(AthleteParentInvitation)
        .options(
            joinedload(AthleteParentInvitation.team),
            joinedload(AthleteParentInvitation.athlete_user),
        )
        .filter(AthleteParentInvitation.id == invitation_id)
        .first()
    )
    if not invitation:
        raise HTTPException(status_code=404, detail="Invitation not found")
    return invitation


def _to_read(invitation: AthleteParentInvitation) -> AthleteInvitationRead:
    athlete_email = invitation.athlete_user.email
    parent_email = invitation.parent_email
    return AthleteInvitationRead(
        id=invitation.id,
        team_id=invitation.team_id,
        team_name=invitation.team.name,
        athlete_user_id=invitation.athlete_user_id,
        athlete_full_name=invitation.athlete_user.full_name,
        athlete_email=None if _is_internal_email(athlete_email) else athlete_email,
        parent_email=None if _is_internal_email(parent_email) else parent_email,
        parent_phone=invitation.parent_phone,
        relationship_label=invitation.relationship_label,
        status=invitation.status,
        invited_by_user_id=invitation.invited_by_user_id,
        expires_at=invitation.expires_at,
        accepted_at=invitation.accepted_at,
        created_at=invitation.created_at,
    )


def _normalized(value: str) -> str:
    return value.strip().lower()


def _is_internal_email(value: str) -> bool:
    return value.endswith("@athletes.piniq.invalid") or value.endswith("@invites.piniq.invalid")


def _athlete_placeholder_email() -> str:
    return f"athlete-{generate_opaque_token().lower()}@athletes.piniq.invalid"


def _phone_invitation_email(phone: str) -> str:
    return f"phone-{phone.lstrip('+')}@invites.piniq.invalid"


def _phone_for_user(user: User) -> str | None:
    try:
        return normalize_phone_number(user.phone)
    except ValueError:
        return None


def _invitation_belongs_to_parent(invitation: AthleteParentInvitation, parent: User) -> bool:
    if invitation.parent_phone:
        return _phone_for_user(parent) == invitation.parent_phone
    return _normalized(parent.email) == invitation.parent_email


@router.post(
    "/teams/{team_id}/athlete-invitations",
    response_model=AthleteInvitationRead,
    status_code=status.HTTP_201_CREATED,
)
def invite_athlete_parent(
    team_id: int,
    payload: AthleteInvitationCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = _load_team(db, team_id)
    membership = next((item for item in team.memberships if item.user_id == current_user.id), None)
    require_team_manager(current_user, team, membership)

    athlete_email = _normalized(str(payload.athlete_email)) if payload.athlete_email else None
    parent_email = _normalized(str(payload.parent_email)) if payload.parent_email else None
    parent_phone = payload.parent_phone
    if athlete_email and parent_email and athlete_email == parent_email:
        raise HTTPException(status_code=400, detail="Athlete and parent must use different email addresses")

    existing_parent = None
    if parent_phone:
        existing_parent = db.query(User).filter(User.phone == parent_phone).first()
    elif parent_email:
        existing_parent = db.query(User).filter(User.email == parent_email).first()
    if existing_parent and existing_parent.role != UserRole.parent:
        raise HTTPException(status_code=400, detail="Parent contact belongs to a non-parent account")

    athlete = None
    if athlete_email:
        athlete = db.query(User).filter(User.email == athlete_email).first()
    else:
        athlete = (
            db.query(User)
            .join(TeamMember, TeamMember.user_id == User.id)
            .filter(
                TeamMember.team_id == team_id,
                User.role == UserRole.athlete,
                func.lower(User.full_name) == payload.athlete_full_name.strip().lower(),
            )
            .first()
        )
    if athlete and athlete.role != UserRole.athlete:
        raise HTTPException(status_code=400, detail="Athlete email belongs to a non-athlete account")

    if athlete is None:
        athlete = User(
            email=athlete_email or _athlete_placeholder_email(),
            password_hash=get_password_hash(generate_opaque_token()),
            full_name=payload.athlete_full_name.strip(),
            role=UserRole.athlete,
            phone=payload.phone,
            hometown=payload.hometown.strip() if payload.hometown else None,
            graduation_year=payload.graduation_year,
            weight_class=payload.weight_class.strip() if payload.weight_class else None,
        )
        db.add(athlete)
        db.flush()

    athlete_membership = (
        db.query(TeamMember)
        .filter(TeamMember.team_id == team_id, TeamMember.user_id == athlete.id)
        .first()
    )
    if athlete_membership is None:
        athlete_membership = TeamMember(
            team_id=team_id,
            user_id=athlete.id,
            role_label="Athlete",
            is_staff=False,
            status=TeamMemberStatus.approved,
        )
        db.add(athlete_membership)
    else:
        athlete_membership.role_label = "Athlete"
        athlete_membership.is_staff = False
        athlete_membership.status = TeamMemberStatus.approved
    if athlete.primary_team_id is None:
        athlete.primary_team_id = team_id

    invitation_query = db.query(AthleteParentInvitation).filter(
        AthleteParentInvitation.team_id == team_id,
        AthleteParentInvitation.athlete_user_id == athlete.id,
    )
    if parent_phone:
        invitation_query = invitation_query.filter(AthleteParentInvitation.parent_phone == parent_phone)
    else:
        invitation_query = invitation_query.filter(AthleteParentInvitation.parent_email == parent_email)
    invitation = invitation_query.first()
    if invitation and invitation.status == AthleteInvitationStatus.accepted:
        raise HTTPException(status_code=400, detail="This parent already manages the athlete")

    expires_at = datetime.utcnow() + timedelta(days=14)
    if invitation is None:
        invitation = AthleteParentInvitation(
            team_id=team_id,
            athlete_user_id=athlete.id,
            parent_email=parent_email or _phone_invitation_email(parent_phone),
            parent_phone=parent_phone,
            relationship_label=payload.relationship_label.strip(),
            status=AthleteInvitationStatus.pending,
            invited_by_user_id=current_user.id,
            expires_at=expires_at,
        )
        db.add(invitation)
    else:
        invitation.relationship_label = payload.relationship_label.strip()
        invitation.parent_email = parent_email or _phone_invitation_email(parent_phone)
        invitation.parent_phone = parent_phone
        invitation.status = AthleteInvitationStatus.pending
        invitation.invited_by_user_id = current_user.id
        invitation.accepted_by_user_id = None
        invitation.accepted_at = None
        invitation.expires_at = expires_at

    db.commit()
    invitation = _load_invitation(db, invitation.id)
    if parent_phone:
        background_tasks.add_task(
            send_sms_message,
            phone_number=parent_phone,
            message=(
                f"{team.name} invited you to manage {athlete.full_name} in Pin IQ. "
                f"Open {settings.frontend_origin}, sign in to a parent account with this phone number, "
                "and accept the invitation."
            ),
            team_id=team.id,
            user_id=current_user.id,
        )
    else:
        background_tasks.add_task(
            send_athlete_parent_invitation_email,
            email=parent_email,
            team_name=team.name,
            athlete_name=athlete.full_name,
            frontend_origin=settings.frontend_origin,
        )
    return _to_read(invitation)


@router.get(
    "/teams/{team_id}/athlete-invitations",
    response_model=list[AthleteInvitationRead],
)
def list_team_athlete_invitations(
    team_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = _load_team(db, team_id)
    membership = next((item for item in team.memberships if item.user_id == current_user.id), None)
    require_team_manager(current_user, team, membership)
    invitations = (
        db.query(AthleteParentInvitation)
        .options(
            joinedload(AthleteParentInvitation.team),
            joinedload(AthleteParentInvitation.athlete_user),
        )
        .filter(AthleteParentInvitation.team_id == team_id)
        .order_by(AthleteParentInvitation.created_at.desc())
        .all()
    )
    return [_to_read(invitation) for invitation in invitations]


@router.get("/athlete-invitations/mine", response_model=list[AthleteInvitationRead])
def list_my_athlete_invitations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != UserRole.parent:
        return []
    parent_phone = _phone_for_user(current_user)
    contact_filters = [AthleteParentInvitation.parent_email == _normalized(current_user.email)]
    if parent_phone:
        contact_filters.append(AthleteParentInvitation.parent_phone == parent_phone)
    invitations = (
        db.query(AthleteParentInvitation)
        .options(
            joinedload(AthleteParentInvitation.team),
            joinedload(AthleteParentInvitation.athlete_user),
        )
        .filter(
            or_(*contact_filters),
            AthleteParentInvitation.status == AthleteInvitationStatus.pending,
            AthleteParentInvitation.expires_at > datetime.utcnow(),
        )
        .order_by(AthleteParentInvitation.created_at.asc())
        .all()
    )
    return [_to_read(invitation) for invitation in invitations]


@router.post("/athlete-invitations/{invitation_id}/accept", response_model=AthleteInvitationRead)
def accept_athlete_invitation(
    invitation_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    invitation = _load_invitation(db, invitation_id)
    if current_user.role != UserRole.parent or not _invitation_belongs_to_parent(invitation, current_user):
        raise HTTPException(status_code=403, detail="This invitation belongs to a different parent")
    if invitation.status == AthleteInvitationStatus.accepted:
        if invitation.accepted_by_user_id == current_user.id:
            return _to_read(invitation)
        raise HTTPException(status_code=400, detail="Invitation has already been accepted")
    if invitation.status != AthleteInvitationStatus.pending:
        raise HTTPException(status_code=400, detail="Invitation is no longer available")
    if invitation.expires_at <= datetime.utcnow():
        raise HTTPException(status_code=400, detail="Invitation has expired; ask the coach to resend it")

    parent_membership = (
        db.query(TeamMember)
        .filter(TeamMember.team_id == invitation.team_id, TeamMember.user_id == current_user.id)
        .first()
    )
    if parent_membership is None:
        db.add(
            TeamMember(
                team_id=invitation.team_id,
                user_id=current_user.id,
                role_label="Parent",
                is_staff=False,
                status=TeamMemberStatus.approved,
            )
        )
    else:
        parent_membership.role_label = "Parent"
        parent_membership.is_staff = False
        parent_membership.status = TeamMemberStatus.approved
    if current_user.primary_team_id is None:
        current_user.primary_team_id = invitation.team_id

    link = (
        db.query(ParentLink)
        .filter(
            ParentLink.team_id == invitation.team_id,
            ParentLink.parent_user_id == current_user.id,
            ParentLink.athlete_user_id == invitation.athlete_user_id,
        )
        .first()
    )
    if link is None:
        db.add(
            ParentLink(
                team_id=invitation.team_id,
                parent_user_id=current_user.id,
                athlete_user_id=invitation.athlete_user_id,
                relationship_label=invitation.relationship_label,
                is_active=True,
                visibility_flags={"accepted_invitation_id": invitation.id},
            )
        )
    else:
        link.relationship_label = invitation.relationship_label
        link.is_active = True
        link.audit_version += 1

    invitation.status = AthleteInvitationStatus.accepted
    invitation.accepted_by_user_id = current_user.id
    invitation.accepted_at = datetime.utcnow()
    db.commit()
    return _to_read(_load_invitation(db, invitation.id))


@router.post("/athlete-invitations/{invitation_id}/decline", response_model=AthleteInvitationRead)
def decline_athlete_invitation(
    invitation_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    invitation = _load_invitation(db, invitation_id)
    if current_user.role != UserRole.parent or not _invitation_belongs_to_parent(invitation, current_user):
        raise HTTPException(status_code=403, detail="This invitation belongs to a different parent")
    if invitation.status != AthleteInvitationStatus.pending:
        raise HTTPException(status_code=400, detail="Invitation is no longer available")
    invitation.status = AthleteInvitationStatus.declined
    db.commit()
    return _to_read(_load_invitation(db, invitation.id))
