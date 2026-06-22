from __future__ import annotations

from pydantic import BaseModel, Field


class AiReplayFindingRead(BaseModel):
    timecode: str | None = None
    title: str
    right: str
    wrong: str
    fix: str
    drill: str
    confidence: float = Field(ge=0, le=1)


class AiReplayFilmStudyRead(BaseModel):
    film_source: str
    status: str
    analysis_mode: str
    coach_summary: str
    athlete_action_plan: str
    parent_summary: str
    findings: list[AiReplayFindingRead]
    frame_count: int
    media_url: str | None = None
