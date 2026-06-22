from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.security import get_password_hash, validate_password_strength, verify_password
from app.db.session import get_db
from app.models.user import User, UserPushDevice, UserRole
from app.routers.deps import get_current_user
from app.schemas.common import MessageResponse
from app.schemas.user import (
    PasswordChangeRequest,
    PushDeviceRead,
    PushDeviceRegisterRequest,
    UserRead,
    UserStatusUpdate,
    UserUpdate,
)
from app.services.auth_audit import log_auth_event


router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserRead)
def me(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    return current_user


@router.put("/me", response_model=UserRead)
def update_me(
    payload: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    current_user.full_name = payload.full_name.strip()
    current_user.phone = payload.phone
    current_user.profile_image_url = payload.profile_image_url.strip() if payload.profile_image_url else None
    current_user.hometown = payload.hometown.strip() if payload.hometown else None
    current_user.graduation_year = payload.graduation_year
    current_user.weight_class = payload.weight_class.strip() if payload.weight_class else None
    current_user.bio = payload.bio.strip() if payload.bio else None
    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    return current_user


@router.put("/me/password", response_model=MessageResponse)
def change_password(
    payload: PasswordChangeRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not verify_password(payload.current_password, current_user.password_hash):
        from fastapi import HTTPException

        raise HTTPException(status_code=400, detail="Current password is incorrect")

    validate_password_strength(payload.new_password)
    current_user.password_hash = get_password_hash(payload.new_password)
    db.add(current_user)
    db.commit()
    return MessageResponse(message="Password updated successfully")


@router.patch("/{user_id}/status", response_model=UserRead)
def update_user_status(
    user_id: int,
    payload: UserStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.role != UserRole.admin:
        raise HTTPException(status_code=403, detail="Only admins can update user status")
    if current_user.id == user_id and not payload.is_active:
        raise HTTPException(status_code=400, detail="Admins cannot deactivate themselves")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.is_active = payload.is_active
    db.add(user)
    db.commit()
    db.refresh(user)
    log_auth_event(
        "user_status_updated",
        user_id=user.id,
        email=user.email,
        actor_id=current_user.id,
    )
    return user


@router.get("/me/push-devices", response_model=list[PushDeviceRead])
def list_my_push_devices(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(UserPushDevice)
        .filter(UserPushDevice.user_id == current_user.id)
        .order_by(UserPushDevice.updated_at.desc())
        .all()
    )


@router.post("/me/push-devices", response_model=PushDeviceRead)
def register_push_device(
    payload: PushDeviceRegisterRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    existing = db.query(UserPushDevice).filter(UserPushDevice.device_token == payload.device_token.strip()).first()
    if existing:
        existing.user_id = current_user.id
        existing.platform = payload.platform.strip().lower()
        existing.push_enabled = True
        existing.last_seen_at = datetime.utcnow()
        device = existing
    else:
        device = UserPushDevice(
            user_id=current_user.id,
            platform=payload.platform.strip().lower(),
            device_token=payload.device_token.strip(),
            push_enabled=True,
            last_seen_at=datetime.utcnow(),
        )
        db.add(device)
    db.commit()
    db.refresh(device)
    return device


@router.delete("/me/push-devices/{device_id}", response_model=MessageResponse)
def unregister_push_device(
    device_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    device = (
        db.query(UserPushDevice)
        .filter(UserPushDevice.id == device_id, UserPushDevice.user_id == current_user.id)
        .first()
    )
    if not device:
        raise HTTPException(status_code=404, detail="Push device not found")

    db.delete(device)
    db.commit()
    return MessageResponse(message="Push device removed")
