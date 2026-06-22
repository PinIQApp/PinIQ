from __future__ import annotations

from fastapi import APIRouter, Depends, File, UploadFile

from app.models.user import User
from app.routers.deps import get_current_user
from app.schemas.ai_replay import AiReplayFilmStudyRead
from app.services.ai_replay_service import analyze_match_film


router = APIRouter(prefix="/ai-replay", tags=["ai-replay"])


@router.post("/analyze-video", response_model=AiReplayFilmStudyRead)
def post_analyze_video(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    return analyze_match_film(file)
