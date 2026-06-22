from __future__ import annotations

import base64
import json
from pathlib import Path
import shutil
import subprocess
from uuid import uuid4

import httpx
from fastapi import HTTPException, UploadFile

from app.core.config import settings
from app.schemas.ai_replay import AiReplayFilmStudyRead, AiReplayFindingRead


def _safe_extension(filename: str | None) -> str:
    extension = Path(filename or "match.mp4").suffix.lower()
    if extension not in settings.allowed_video_extensions:
        raise HTTPException(status_code=400, detail="Only match video uploads are allowed")
    return extension


def _save_video_upload(upload: UploadFile) -> tuple[Path, str]:
    extension = _safe_extension(upload.filename)
    media_root = Path(settings.media_dir)
    film_dir = media_root / "film"
    film_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{uuid4().hex}{extension}"
    destination = film_dir / filename

    total_bytes = 0
    with destination.open("wb") as output:
        while True:
            chunk = upload.file.read(1024 * 1024)
            if not chunk:
                break
            total_bytes += len(chunk)
            if total_bytes > settings.max_video_upload_size_bytes:
                destination.unlink(missing_ok=True)
                raise HTTPException(
                    status_code=413,
                    detail=f"Video exceeds max upload size of {settings.max_video_upload_size_bytes} bytes",
                )
            output.write(chunk)

    return destination, f"{settings.media_base_url.rstrip('/')}/film/{filename}"


def _extract_frames(video_path: Path) -> list[Path]:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        return []

    frame_dir = video_path.parent / f"{video_path.stem}_frames"
    frame_dir.mkdir(parents=True, exist_ok=True)
    pattern = frame_dir / "frame_%03d.jpg"
    interval = max(settings.film_study_frame_interval_seconds, 1)
    command = [
        ffmpeg,
        "-hide_banner",
        "-loglevel",
        "error",
        "-i",
        str(video_path),
        "-vf",
        f"fps=1/{interval},scale=768:-1",
        "-frames:v",
        str(max(settings.film_study_frame_count, 1)),
        str(pattern),
    ]
    try:
        subprocess.run(command, check=True, timeout=45)
    except (subprocess.SubprocessError, OSError):
        return []
    return sorted(frame_dir.glob("frame_*.jpg"))[: settings.film_study_frame_count]


def _frame_data_url(frame: Path) -> str:
    encoded = base64.b64encode(frame.read_bytes()).decode("ascii")
    return f"data:image/jpeg;base64,{encoded}"


def _fallback_findings(*, filename: str, frame_count: int) -> AiReplayFilmStudyRead:
    findings = [
        AiReplayFindingRead(
            timecode="Early neutral",
            title="Stance height and first contact",
            right="The athlete is creating enough motion to start exchanges.",
            wrong="The first attack can happen before the opponent is moved out of position.",
            fix="Use a hand fake or level change first, then attack after the opponent steps.",
            drill="Motion-fake-single, 5 sets of 5 clean entries each side.",
            confidence=0.42,
        ),
        AiReplayFindingRead(
            timecode="First finish",
            title="Finish through contact",
            right="The athlete is getting to scoring positions often enough to build from.",
            wrong="Pressure can stop after contact, giving the opponent time to square hips.",
            fix="Pick one immediate finish and keep the feet moving through the corner.",
            drill="Single-leg shelf to cut-corner chain, 12 reps each side.",
            confidence=0.4,
        ),
        AiReplayFindingRead(
            timecode="Late match",
            title="Late-period stance reset",
            right="The athlete keeps competing through extended exchanges.",
            wrong="Hands and hips can rise late, making defense reactive.",
            fix="Reset stance after every whistle and win the next hand touch.",
            drill="30-second stance-motion, sprawl on call, shot on call, 6 rounds.",
            confidence=0.38,
        ),
    ]
    return AiReplayFilmStudyRead(
        film_source=filename,
        status="ready",
        analysis_mode="beta_fallback",
        coach_summary=(
            "Film was uploaded and saved. Add OpenAI credentials for frame-level AI review; "
            "this beta fallback gives a coach-review starting point."
        ),
        athlete_action_plan="\n".join(f"{item.fix} Drill: {item.drill}" for item in findings),
        parent_summary="The match is ready for coach review. The first focus is stance, clean attacks, and finishing through contact.",
        findings=findings,
        frame_count=frame_count,
    )


def _json_from_response(data: dict) -> dict:
    pieces: list[str] = []
    for item in data.get("output", []):
        for content in item.get("content", []):
            text = content.get("text")
            if text:
                pieces.append(text)
    output_text = "\n".join(pieces).strip()
    if not output_text:
        output_text = data.get("output_text", "")
    start = output_text.find("{")
    end = output_text.rfind("}")
    if start == -1 or end == -1:
        raise ValueError("OpenAI response did not include JSON")
    return json.loads(output_text[start : end + 1])


def _openai_film_study(*, filename: str, frames: list[Path]) -> AiReplayFilmStudyRead | None:
    if not settings.openai_api_key or not frames:
        return None

    prompt = """
You are a wrestling film-study assistant for coaches. Analyze these sampled match frames.
Return strict JSON only with:
coach_summary, athlete_action_plan, parent_summary, findings.
Each finding must include: timecode, title, right, wrong, fix, drill, confidence.
Focus on wrestling-specific right vs wrong: stance, setup, shot, sprawl, finish, top pressure, bottom escape, pace.
Do not invent a score. If the camera angle is unclear, lower confidence and say what is uncertain.
"""
    content: list[dict] = [{"type": "input_text", "text": prompt}]
    for frame in frames:
        content.append({"type": "input_image", "image_url": _frame_data_url(frame)})

    try:
        response = httpx.post(
            "https://api.openai.com/v1/responses",
            headers={
                "Authorization": f"Bearer {settings.openai_api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": settings.openai_vision_model,
                "input": [{"role": "user", "content": content}],
            },
            timeout=90,
        )
        response.raise_for_status()
        payload = _json_from_response(response.json())
        findings = [
            AiReplayFindingRead(
                timecode=item.get("timecode"),
                title=item.get("title") or "Film-study finding",
                right=item.get("right") or "Positive position was visible.",
                wrong=item.get("wrong") or "Technical correction needed.",
                fix=item.get("fix") or "Review with a coach and drill the corrected position.",
                drill=item.get("drill") or "Coach-selected situational reps.",
                confidence=float(item.get("confidence", 0.5)),
            )
            for item in payload.get("findings", [])[:6]
        ]
        if not findings:
            return None
        return AiReplayFilmStudyRead(
            film_source=filename,
            status="ready",
            analysis_mode="openai_vision",
            coach_summary=payload.get("coach_summary") or "AI film study generated.",
            athlete_action_plan=payload.get("athlete_action_plan") or "\n".join(item.fix for item in findings),
            parent_summary=payload.get("parent_summary") or "Coaches have a film-study plan ready.",
            findings=findings,
            frame_count=len(frames),
        )
    except (httpx.HTTPError, ValueError, KeyError, TypeError, json.JSONDecodeError):
        return None


def analyze_match_film(upload: UploadFile) -> AiReplayFilmStudyRead:
    if upload.content_type and not upload.content_type.startswith("video/"):
        extension = Path(upload.filename or "").suffix.lower()
        if extension not in settings.allowed_video_extensions:
            raise HTTPException(status_code=400, detail="Only match video uploads are allowed")

    video_path, media_url = _save_video_upload(upload)
    frames = _extract_frames(video_path)
    analysis = _openai_film_study(filename=upload.filename or video_path.name, frames=frames)
    if analysis is None:
        analysis = _fallback_findings(filename=upload.filename or video_path.name, frame_count=len(frames))
    return analysis.model_copy(update={"media_url": media_url})
