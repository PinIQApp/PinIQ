from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import settings
from app.core.security import create_access_token, get_password_hash
from app.db.base import Base
from app.db.session import get_db
from app.main import app
from app.models.messaging import ParentLink
from app.models.store import Product, ProductCategory, ProductVisibility, StockStatus
from app.models.team import Team, TeamMember, TeamMemberStatus
from app.models.user import User, UserRole
from app.services.rate_limit import auth_rate_limiter


@pytest.fixture()
def client(tmp_path) -> Generator[TestClient, None, None]:
    database_path = tmp_path / "test.db"
    media_dir = tmp_path / "media"
    media_dir.mkdir(parents=True, exist_ok=True)

    engine = create_engine(
        f"sqlite:///{database_path}",
        connect_args={"check_same_thread": False},
    )
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)

    original_auto_create_schema = settings.auto_create_schema
    original_seed_demo_data = settings.seed_demo_data_on_startup
    original_media_dir = settings.media_dir
    original_max_upload_size = settings.max_upload_size_bytes
    original_environment = settings.environment
    original_rate_limit_attempts = settings.auth_rate_limit_attempts

    settings.environment = "test"
    settings.auto_create_schema = False
    settings.seed_demo_data_on_startup = False
    settings.media_dir = str(media_dir)
    settings.max_upload_size_bytes = 1024
    settings.auth_rate_limit_attempts = 3

    def override_get_db() -> Generator[Session, None, None]:
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.state.testing_session_local = TestingSessionLocal
    app.state.media_dir_override = str(media_dir)
    app.dependency_overrides[get_db] = override_get_db
    auth_rate_limiter.clear()

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()
    del app.state.media_dir_override
    del app.state.testing_session_local
    auth_rate_limiter.clear()
    settings.auto_create_schema = original_auto_create_schema
    settings.seed_demo_data_on_startup = original_seed_demo_data
    settings.media_dir = original_media_dir
    settings.max_upload_size_bytes = original_max_upload_size
    settings.environment = original_environment
    settings.auth_rate_limit_attempts = original_rate_limit_attempts
    Base.metadata.drop_all(bind=engine)


@pytest.fixture()
def db_session(client: TestClient) -> Generator[Session, None, None]:
    db = app.state.testing_session_local()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture()
def coach_auth_headers(db_session: Session) -> dict[str, str]:
    coach = User(
        email="coach@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Coach Carter",
        role=UserRole.coach,
    )
    db_session.add(coach)
    db_session.flush()

    team = Team(
        name="Varsity Wrestling",
        slug="varsity-wrestling",
        join_code="JOIN1234",
        school_name="Central High",
        school_abbreviation="CHS",
        mascot_name="Eagles",
        division="Division I",
        season_label="2026",
        dark_mode=True,
        primary_color="#112233",
        secondary_color="#445566",
        accent_color="#778899",
        surface_color="#000000",
        created_by_user_id=coach.id,
    )
    db_session.add(team)
    db_session.flush()

    membership = TeamMember(
        team_id=team.id,
        user_id=coach.id,
        role_label="Coach",
        is_staff=True,
        status=TeamMemberStatus.approved,
    )
    coach.primary_team_id = team.id
    db_session.add(membership)
    db_session.commit()

    token = create_access_token(coach.id)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def admin_auth_headers(db_session: Session) -> dict[str, str]:
    admin = User(
        email="admin@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Admin User",
        role=UserRole.admin,
    )
    db_session.add(admin)
    db_session.commit()

    token = create_access_token(admin.id)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def outsider_auth_headers(db_session: Session) -> dict[str, str]:
    outsider = User(
        email="outsider@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Outside User",
        role=UserRole.parent,
    )
    db_session.add(outsider)
    db_session.commit()
    return {"Authorization": f"Bearer {create_access_token(outsider.id)}"}


@pytest.fixture()
def store_product(db_session: Session) -> Product:
    category = ProductCategory(
        slug="medical",
        name="Medical",
        description="Medical supplies",
        icon_name="medical",
        sort_order=1,
        is_active=True,
    )
    db_session.add(category)
    db_session.flush()

    product = Product(
        category_id=category.id,
        name="Mat Tape",
        description="Roll of tape",
        sku="MAT-TAPE-1",
        cost_price=5,
        sell_price=9,
        stock_status=StockStatus.in_stock,
        visibility=ProductVisibility.both,
        is_active=True,
        is_featured=True,
        allow_backorder=False,
        inventory_count=10,
        inventory_tracked=True,
    )
    db_session.add(product)
    db_session.commit()
    return product


@pytest.fixture()
def messaging_team_members(db_session: Session) -> dict[str, int]:
    coach = db_session.query(User).filter(User.email == "coach@example.com").first()
    team = db_session.query(Team).filter(Team.id == coach.primary_team_id).first()

    athlete = User(
        email="athlete@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Athlete User",
        role=UserRole.athlete,
    )
    parent = User(
        email="parent@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Parent User",
        role=UserRole.parent,
    )
    db_session.add_all([athlete, parent])
    db_session.flush()

    db_session.add_all(
        [
            TeamMember(
                team_id=team.id,
                user_id=athlete.id,
                role_label="Athlete",
                is_staff=False,
                status=TeamMemberStatus.approved,
            ),
            TeamMember(
                team_id=team.id,
                user_id=parent.id,
                role_label="Parent",
                is_staff=False,
                status=TeamMemberStatus.approved,
            ),
        ]
    )
    db_session.commit()
    return {"team_id": team.id, "athlete_id": athlete.id, "parent_id": parent.id}


@pytest.fixture()
def parent_link(db_session: Session, messaging_team_members: dict[str, int]) -> ParentLink:
    link = ParentLink(
        team_id=messaging_team_members["team_id"],
        parent_user_id=messaging_team_members["parent_id"],
        athlete_user_id=messaging_team_members["athlete_id"],
        relationship_label="parent",
        is_active=True,
    )
    db_session.add(link)
    db_session.commit()
    return link
