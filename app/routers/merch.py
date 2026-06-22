from __future__ import annotations

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.routers.deps import get_current_user
from app.schemas.merch import (
    MerchDesignCreate,
    MerchDesignRead,
    MerchDesignUpdate,
    MerchExportRequest,
    MerchProductRead,
    MerchPublishResponse,
    MerchTemplateRead,
)
from app.services.merch_service import (
    create_design,
    export_design,
    get_design,
    list_products,
    list_team_designs,
    list_templates,
    publish_design,
    update_design,
)


router = APIRouter(prefix="/merch", tags=["merch"])


@router.get("/products", response_model=list[MerchProductRead])
def get_merch_products(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_products(db)


@router.get("/templates", response_model=list[MerchTemplateRead])
def get_merch_templates(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_templates(db)


@router.post("/designs", response_model=MerchDesignRead, status_code=status.HTTP_201_CREATED)
def post_merch_design(
    payload: MerchDesignCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    design = create_design(db, payload=payload, current_user=current_user)
    db.commit()
    return design


@router.get("/designs/team/{team_id}", response_model=list[MerchDesignRead])
def get_team_merch_designs(
    team_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_team_designs(db, team_id=team_id, current_user=current_user)


@router.get("/designs/{design_id}", response_model=MerchDesignRead)
def get_merch_design(
    design_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return get_design(db, design_id=design_id, current_user=current_user)


@router.patch("/designs/{design_id}", response_model=MerchDesignRead)
def patch_merch_design(
    design_id: int,
    payload: MerchDesignUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    design = update_design(db, design_id=design_id, payload=payload, current_user=current_user)
    db.commit()
    return design


@router.post("/designs/{design_id}/publish", response_model=MerchPublishResponse)
def publish_team_merch_design(
    design_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    response = publish_design(db, design_id=design_id, current_user=current_user)
    db.commit()
    return response


@router.post("/designs/{design_id}/export", response_model=MerchDesignRead)
def create_merch_export(
    design_id: int,
    payload: MerchExportRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    design = export_design(db, design_id=design_id, payload=payload, current_user=current_user)
    db.commit()
    return design
