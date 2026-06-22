from __future__ import annotations

from contextlib import asynccontextmanager
from pathlib import Path
from time import perf_counter
from uuid import uuid4

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text

from app.core.config import settings, validate_runtime_settings
from app.core.logging import configure_logging, get_logger
from app.db.base import *
from app.db.session import Base, SessionLocal, engine
from app.routers.ai_replay import router as ai_replay_router
from app.routers.auth import router as auth_router
from app.routers.branding import router as branding_router
from app.routers.merch import router as merch_router
from app.routers.messages import router as messages_router
from app.routers.nutrition import router as nutrition_router
from app.routers.recruiting import router as recruiting_router
from app.routers.roster import router as roster_router
from app.routers.schedule import router as schedule_router
from app.routers.store import router as store_router
from app.routers.stats import router as stats_router
from app.routers.team_members import router as team_members_router
from app.routers.teams import router as teams_router
from app.routers.tournaments import router as tournaments_router
from app.routers.uploads import router as uploads_router
from app.routers.users import router as users_router
from app.routers.weights import router as weights_router
from app.seed.demo_seed import seed_demo_data
from app.services.monitoring import report_exception


logger = get_logger("app.main")


@asynccontextmanager
async def lifespan(_: FastAPI):
    configure_logging()
    validate_runtime_settings()
    Path(settings.media_dir).mkdir(parents=True, exist_ok=True)
    logger.info("application_starting", extra={"request_id": "startup"})

    if settings.auto_create_schema:
        logger.warning(
            "auto_create_schema_enabled",
            extra={
                "request_id": "startup",
                "environment": settings.environment,
                "database_url": settings.database_url,
            },
        )
        Base.metadata.create_all(bind=engine)

    if settings.seed_demo_data_on_startup:
        with SessionLocal() as db:
            seed_demo_data(db)
    yield
    logger.info("application_stopping", extra={"request_id": "shutdown"})


app = FastAPI(title=settings.app_name, lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def request_context_logging(request: Request, call_next):
    request_id = request.headers.get("X-Request-ID") or uuid4().hex
    request.state.request_id = request_id
    started_at = perf_counter()
    try:
        response = await call_next(request)
    except Exception as exc:
        duration_ms = round((perf_counter() - started_at) * 1000, 2)
        logger.exception(
            "request_failed",
            extra={
                "request_id": request_id,
                "method": request.method,
                "path": request.url.path,
                "duration_ms": duration_ms,
            },
        )
        raise exc

    duration_ms = round((perf_counter() - started_at) * 1000, 2)
    response.headers["X-Request-ID"] = request_id
    logger.info(
        "request_completed",
        extra={
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
            "status_code": response.status_code,
            "duration_ms": duration_ms,
        },
    )
    return response


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    request_id = getattr(request.state, "request_id", None)
    report_exception(exc, request_id=request_id)
    logger.error(
        "unhandled_exception_response",
        extra={"request_id": request_id, "path": request.url.path},
    )
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error", "request_id": request_id},
    )


@app.get("/")
def root():
    return {"name": "Pin IQ API", "status": "ready"}


@app.get("/health/live")
def live_health():
    return {"status": "ok"}


@app.get("/health/ready")
def ready_health():
    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))
    return {"status": "ok", "database": "reachable"}


app.include_router(auth_router, prefix=settings.api_v1_str)
app.include_router(users_router, prefix=settings.api_v1_str)
app.include_router(teams_router, prefix=settings.api_v1_str)
app.include_router(roster_router, prefix=settings.api_v1_str)
app.include_router(messages_router, prefix=settings.api_v1_str)
app.include_router(nutrition_router, prefix=settings.api_v1_str)
app.include_router(recruiting_router, prefix=settings.api_v1_str)
app.include_router(team_members_router, prefix=settings.api_v1_str)
app.include_router(branding_router, prefix=settings.api_v1_str)
app.include_router(uploads_router, prefix=settings.api_v1_str)
app.include_router(weights_router, prefix=settings.api_v1_str)
app.include_router(schedule_router, prefix=settings.api_v1_str)
app.include_router(stats_router, prefix=settings.api_v1_str)
app.include_router(store_router, prefix=settings.api_v1_str)
app.include_router(merch_router, prefix=settings.api_v1_str)
app.include_router(tournaments_router, prefix=settings.api_v1_str)
app.include_router(ai_replay_router, prefix=settings.api_v1_str)
app.mount("/media", StaticFiles(directory=settings.media_dir), name="media")
