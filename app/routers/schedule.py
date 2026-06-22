from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.schedule import EventType
from app.routers.deps import get_current_user
from app.schemas.schedule import (
    EventCreate,
    EventRead,
    EventUpdate,
    PracticeAssignToDateRequest,
    PracticeAssignmentRead,
    PracticeDuplicateRequest,
    PracticePlanCreate,
    PracticePlanRead,
    PracticePlanSummaryRead,
    PracticePlanUpdate,
    PracticeTemplateCreate,
    PracticeTemplateRead,
    TeamScheduleRead,
)
from app.services.schedule_planner import (
    assign_practice_to_date,
    create_event,
    create_practice_plan,
    create_template,
    delete_event,
    duplicate_practice,
    list_events_for_team,
    list_practices_for_team,
    list_templates_for_team,
    load_practice,
    update_event,
    update_practice_plan,
)


router = APIRouter(tags=["schedule"])


@router.post("/events", response_model=EventRead, status_code=status.HTTP_201_CREATED)
def create_team_event(
    payload: EventCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    event = create_event(db, payload=payload, current_user=current_user)
    db.commit()
    return event


@router.get("/events/team/{team_id}", response_model=TeamScheduleRead)
def get_team_events(
    team_id: int,
    event_type: EventType | None = Query(default=None),
    starts_after: datetime | None = Query(default=None),
    ends_before: datetime | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    visible_as, events, summary = list_events_for_team(
        db,
        team_id=team_id,
        current_user=current_user,
        event_type=event_type,
        starts_after=starts_after,
        ends_before=ends_before,
    )
    return TeamScheduleRead(team_id=team_id, visible_as=visible_as, summary=summary, events=events)


@router.patch("/events/{event_id}", response_model=EventRead)
def patch_event(
    event_id: int,
    payload: EventUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    event = update_event(db, event_id=event_id, payload=payload, current_user=current_user)
    db.commit()
    return event


@router.delete("/events/{event_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_event(
    event_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    delete_event(db, event_id=event_id, current_user=current_user)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/practices", response_model=PracticePlanRead, status_code=status.HTTP_201_CREATED)
def create_practice(
    payload: PracticePlanCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    practice = create_practice_plan(db, payload=payload, current_user=current_user)
    db.commit()
    return practice


@router.get("/practices/team/{team_id}", response_model=list[PracticePlanSummaryRead])
def get_team_practices(
    team_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_practices_for_team(db, team_id=team_id, current_user=current_user)


@router.get("/practices/{practice_id}", response_model=PracticePlanRead)
def get_practice(
    practice_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return load_practice(db, practice_id, current_user=current_user)


@router.patch("/practices/{practice_id}", response_model=PracticePlanRead)
def patch_practice(
    practice_id: int,
    payload: PracticePlanUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    practice = update_practice_plan(db, practice_id=practice_id, payload=payload, current_user=current_user)
    db.commit()
    return practice


@router.post("/practice-templates", response_model=PracticeTemplateRead, status_code=status.HTTP_201_CREATED)
def create_practice_template(
    payload: PracticeTemplateCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    template = create_template(db, payload=payload, current_user=current_user)
    db.commit()
    return template


@router.get("/practice-templates/team/{team_id}", response_model=list[PracticeTemplateRead])
def get_team_templates(
    team_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_templates_for_team(db, team_id=team_id, current_user=current_user)


@router.post("/practices/{practice_id}/duplicate", response_model=PracticePlanRead, status_code=status.HTTP_201_CREATED)
def duplicate_existing_practice(
    practice_id: int,
    payload: PracticeDuplicateRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    practice = duplicate_practice(db, practice_id=practice_id, payload=payload, current_user=current_user)
    db.commit()
    return practice


@router.post("/practices/{practice_id}/assign-to-date", response_model=PracticeAssignmentRead)
def assign_practice(
    practice_id: int,
    payload: PracticeAssignToDateRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    practice, event = assign_practice_to_date(db, practice_id=practice_id, payload=payload, current_user=current_user)
    db.commit()
    return PracticeAssignmentRead(practice=practice, event=event)
