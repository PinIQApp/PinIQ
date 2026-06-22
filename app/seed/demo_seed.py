from __future__ import annotations

from datetime import date, datetime, timedelta

from sqlalchemy.orm import Session

from app.core.security import get_password_hash
from app.models.messaging import (
    Announcement,
    AuditAction,
    Message,
    MessageAuditLog,
    MessageParticipant,
    MessageParticipantType,
    MessageThread,
    MessageThreadType,
    MessageType,
    ParentLink,
)
from app.models.schedule import Event, EventType, PracticeBlock, PracticeBlockType, PracticePlan
from app.models.recruiting import (
    RecruitingContactVisibility,
    RecruitingHighlight,
    RecruitingNote,
    RecruitingProfile,
    RecruitingTag,
    RecruitingVisibility,
    RecruitingVisibilityLevel,
    RecruitingWatchlist,
)
from app.models.store import (
    CartItem,
    Order,
    OrderItem,
    OrderStatus,
    OrderType,
    Product,
    ProductCategory,
    ProductImage,
    ProductVisibility,
    PurchaserRole,
    ShippingStatus,
    StockStatus,
    TeamStoreConfig,
    Vendor,
)
from app.models.stats import AthleteStatSnapshot, Match, MatchOutcome, MatchResultType, MatchStats
from app.models.team import Team, TeamMember, TeamMemberStatus
from app.models.tournament import (
    SavedTournament,
    TournamentExternal,
    TournamentExternalStatus,
    TournamentIngestionMode,
    TournamentSource,
    TournamentSourceType,
)
from app.models.user import User, UserRole
from app.models.weight import AthleteTarget, WeightAlert, WeightAlertType, WeightLog, WeightPlan, WeightPlanStatus
from app.services.schedule_planner import seed_default_templates
from app.services.weight_planning import calculate_plan


def seed_demo_data(db: Session) -> None:
    if db.query(User).filter(User.email == "coach@wrestlingos.com").first():
        return

    coach = User(
        email="coach@wrestlingos.com",
        password_hash=get_password_hash("Password123"),
        full_name="Jordan Blake",
        role=UserRole.coach,
        phone="555-0101",
    )
    athlete = User(
        email="athlete@wrestlingos.com",
        password_hash=get_password_hash("Password123"),
        full_name="Tyson Reed",
        role=UserRole.athlete,
        phone="555-0102",
        profile_image_url="https://placehold.co/400x400/png?text=Tyson+Reed",
        hometown="Riverdale, NY",
        graduation_year=2027,
        weight_class="144 lbs",
        bio="Explosive neutral wrestler focused on chain attacks and late-match pressure.",
    )
    parent = User(
        email="parent@wrestlingos.com",
        password_hash=get_password_hash("Password123"),
        full_name="Megan Reed",
        role=UserRole.parent,
        phone="555-0103",
    )
    assistant_coach = User(
        email="assistant@wrestlingos.com",
        password_hash=get_password_hash("Password123"),
        full_name="Avery Stone",
        role=UserRole.assistant_coach,
        phone="555-0104",
    )
    athlete_two = User(
        email="athlete2@wrestlingos.com",
        password_hash=get_password_hash("Password123"),
        full_name="Mason Cole",
        role=UserRole.athlete,
        phone="555-0105",
        profile_image_url="https://placehold.co/400x400/png?text=Mason+Cole",
        hometown="White Plains, NY",
        graduation_year=2026,
        weight_class="157 lbs",
        bio="Strong top wrestler with heavy hands and good mat returns.",
    )
    athlete_three = User(
        email="athlete3@wrestlingos.com",
        password_hash=get_password_hash("Password123"),
        full_name="Eli Navarro",
        role=UserRole.athlete,
        phone="555-0106",
        profile_image_url="https://placehold.co/400x400/png?text=Eli+Navarro",
        hometown="Yonkers, NY",
        graduation_year=2028,
        weight_class="132 lbs",
        bio="Scrappy pace wrestler with strong short offense and clean motion.",
    )
    parent_two = User(
        email="parent2@wrestlingos.com",
        password_hash=get_password_hash("Password123"),
        full_name="Derrick Cole",
        role=UserRole.parent,
        phone="555-0107",
    )
    db.add_all([coach, athlete, parent, assistant_coach, athlete_two, athlete_three, parent_two])
    db.flush()

    team = Team(
        name="Varsity Wrestling",
        slug="riverdale-varsity",
        join_code="RHS2026",
        school_name="Riverdale High",
        school_abbreviation="RHS",
        mascot_name="Ravens",
        division="High School Varsity",
        season_label="2026-2027",
        dark_mode=True,
        primary_color="#B80F0A",
        secondary_color="#F4A300",
        accent_color="#F7D354",
        surface_color="#161A20",
        logo_url="https://placehold.co/200x200/png?text=RHS",
        tagline="Built for the mat.",
        created_by_user_id=coach.id,
    )
    db.add(team)
    db.flush()

    coach.primary_team_id = team.id
    assistant_coach.primary_team_id = team.id
    athlete.primary_team_id = team.id
    athlete_two.primary_team_id = team.id
    athlete_three.primary_team_id = team.id
    parent.primary_team_id = team.id
    parent_two.primary_team_id = team.id
    db.add_all(
        [
            TeamMember(team_id=team.id, user_id=coach.id, role_label="Coach", is_staff=True),
            TeamMember(team_id=team.id, user_id=assistant_coach.id, role_label="Assistant Coach", is_staff=True),
            TeamMember(
                team_id=team.id,
                user_id=athlete.id,
                role_label="Athlete",
                is_staff=False,
                status=TeamMemberStatus.approved,
            ),
            TeamMember(
                team_id=team.id,
                user_id=athlete_two.id,
                role_label="Athlete",
                is_staff=False,
                status=TeamMemberStatus.approved,
            ),
            TeamMember(
                team_id=team.id,
                user_id=athlete_three.id,
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
            TeamMember(
                team_id=team.id,
                user_id=parent_two.id,
                role_label="Parent",
                is_staff=False,
                status=TeamMemberStatus.approved,
            ),
        ]
    )
    db.flush()

    parent_link = ParentLink(
        team_id=team.id,
        parent_user_id=parent.id,
        athlete_user_id=athlete.id,
        relationship_label="Mother",
        visibility_flags={"compliance_required": True},
    )
    db.add(parent_link)
    db.add(
        ParentLink(
            team_id=team.id,
            parent_user_id=parent_two.id,
            athlete_user_id=athlete_two.id,
            relationship_label="Father",
            visibility_flags={"compliance_required": True},
        )
    )
    db.flush()

    manual_source = TournamentSource(
        source_key=TournamentSourceType.manual,
        display_name="Manual",
        ingestion_mode=TournamentIngestionMode.manual_entry,
        supports_scraping=False,
        supports_api=False,
        notes="Coach-created tournaments.",
    )
    track_source = TournamentSource(
        source_key=TournamentSourceType.track,
        display_name="TrackWrestling",
        ingestion_mode=TournamentIngestionMode.hybrid_placeholder,
        base_url="https://www.trackwrestling.com",
        supports_scraping=True,
        supports_api=False,
        notes="Placeholder discovery source for scrape-first ingestion.",
    )
    flo_source = TournamentSource(
        source_key=TournamentSourceType.flo,
        display_name="FloWrestling",
        ingestion_mode=TournamentIngestionMode.hybrid_placeholder,
        base_url="https://www.flowrestling.org",
        supports_scraping=True,
        supports_api=False,
        notes="Placeholder discovery source for Flo event pages.",
    )
    usa_source = TournamentSource(
        source_key=TournamentSourceType.usa,
        display_name="USA Wrestling",
        ingestion_mode=TournamentIngestionMode.hybrid_placeholder,
        base_url="https://www.usawmembership.com",
        supports_scraping=True,
        supports_api=False,
        notes="Placeholder discovery source for sanctioned events.",
    )
    db.add_all([manual_source, track_source, flo_source, usa_source])
    db.flush()

    discovery_tournaments = [
        TournamentExternal(
            source_id=track_source.id,
            external_id="track-rumble-2026",
            name="Hudson Valley Spring Rumble",
            start_date=date.today() + timedelta(days=10),
            end_date=date.today() + timedelta(days=10),
            location_name="Hudson Valley Field House",
            city="Poughkeepsie",
            state="NY",
            latitude=41.7004,
            longitude=-73.9210,
            age_divisions=["High School Varsity", "JV"],
            weight_classes=["106", "113", "120", "126", "132", "138", "144", "150"],
            event_type="open",
            registration_link="https://www.trackwrestling.com/example/hudson-valley-spring-rumble",
            event_page_link="https://www.trackwrestling.com/example/hudson-valley-spring-rumble/details",
            source_label="TrackWrestling",
            contact_name="Chris Palmer",
            contact_email="events@hudsonvalleyrumble.org",
            contact_phone="555-2100",
            description="One-day early season open with varsity and JV brackets.",
            deadline=date.today() + timedelta(days=7),
            cost="$325 team / $40 individual",
            raw_payload={"source": "seed"},
            normalized_payload={"style": "open"},
            ingestion_status=TournamentExternalStatus.normalized,
            last_seen_at=datetime.utcnow(),
        ),
        TournamentExternal(
            source_id=flo_source.id,
            external_id="flo-northeast-duals-2026",
            name="Northeast Clash Duals",
            start_date=date.today() + timedelta(days=17),
            end_date=date.today() + timedelta(days=18),
            location_name="Albany Capital Center",
            city="Albany",
            state="NY",
            latitude=42.6526,
            longitude=-73.7562,
            age_divisions=["High School Varsity"],
            weight_classes=None,
            event_type="dual",
            registration_link="https://www.flowrestling.org/example/northeast-clash-duals/register",
            event_page_link="https://www.flowrestling.org/example/northeast-clash-duals",
            source_label="FloWrestling",
            contact_name="Dana Russell",
            contact_email="duals@northeastclash.com",
            contact_phone="555-2200",
            description="Two-day dual event for varsity lineups.",
            deadline=date.today() + timedelta(days=12),
            cost="$900 per team",
            raw_payload={"source": "seed"},
            normalized_payload={"style": "dual"},
            ingestion_status=TournamentExternalStatus.normalized,
            last_seen_at=datetime.utcnow(),
        ),
        TournamentExternal(
            source_id=usa_source.id,
            external_id="usa-freestyle-kids-2026",
            name="Empire State Freestyle Open",
            start_date=date.today() + timedelta(days=4),
            end_date=date.today() + timedelta(days=5),
            location_name="Rochester SportsPlex",
            city="Rochester",
            state="NY",
            latitude=43.1566,
            longitude=-77.6088,
            age_divisions=["8U", "10U", "12U", "14U", "16U"],
            weight_classes=["52", "58", "65", "74", "83", "92", "105", "120"],
            event_type="national",
            registration_link="https://www.usawmembership.com/example/empire-state-freestyle-open",
            event_page_link="https://www.usawmembership.com/example/empire-state-freestyle-open/details",
            source_label="USA Wrestling",
            contact_name="Kelsey Moore",
            contact_email="empirestate@usawny.org",
            contact_phone="555-2300",
            description="Freestyle-focused weekend event with novice and experienced divisions.",
            deadline=date.today() + timedelta(days=2),
            cost="$35 entry",
            raw_payload={"source": "seed"},
            normalized_payload={"style": "freestyle"},
            ingestion_status=TournamentExternalStatus.normalized,
            last_seen_at=datetime.utcnow(),
        ),
    ]
    db.add_all(discovery_tournaments)
    db.flush()
    db.add(
        SavedTournament(
            team_id=team.id,
            tournament_external_id=discovery_tournaments[0].id,
            saved_by_user_id=coach.id,
            notes="Strong local fit for early lineup testing.",
        )
    )
    db.flush()

    seed_default_templates(db, team_id=team.id, created_by_user_id=coach.id)
    db.flush()

    hard_practice = PracticePlan(
        team_id=team.id,
        created_by_user_id=coach.id,
        title="Thursday Hard Room",
        description="High pace varsity room focused on re-attacks and top pressure.",
        focus="Re-attack chains and hard mat returns",
        practice_date=date.today() + timedelta(days=1),
        notes="Bring heart-rate straps, ankle bands, and film notebooks.",
        template_name_snapshot="Hard Practice",
        is_template_based=True,
    )
    hard_practice.blocks = [
        PracticeBlock(
            block_order=1,
            block_type=PracticeBlockType.warm_up,
            title="Dynamic mat warm-up",
            duration_minutes=12,
        ),
        PracticeBlock(
            block_order=2,
            block_type=PracticeBlockType.stance_and_motion,
            title="Pressure stance motion",
            duration_minutes=10,
        ),
        PracticeBlock(
            block_order=3,
            block_type=PracticeBlockType.drilling,
            title="Re-attack finishes from ties",
            duration_minutes=18,
        ),
        PracticeBlock(
            block_order=4,
            block_type=PracticeBlockType.top_bottom,
            title="Top pressure into mat return finish",
            duration_minutes=18,
        ),
        PracticeBlock(
            block_order=5,
            block_type=PracticeBlockType.live_goes,
            title="Three hard goes",
            duration_minutes=24,
        ),
        PracticeBlock(
            block_order=6,
            block_type=PracticeBlockType.conditioning,
            title="Sprint ladder finisher",
            duration_minutes=12,
        ),
        PracticeBlock(
            block_order=7,
            block_type=PracticeBlockType.cool_down,
            title="Stretch and captains close",
            duration_minutes=8,
        ),
    ]
    hard_practice.total_duration_minutes = 102
    db.add(hard_practice)
    db.flush()

    pre_match_practice = PracticePlan(
        team_id=team.id,
        created_by_user_id=coach.id,
        title="Saturday Pre-Match Tune-Up",
        description="Short confidence session before the weekend dual.",
        focus="Clean first attacks and match starts",
        practice_date=date.today() + timedelta(days=3),
        notes="Light session. Athletes off the mat quickly for recovery.",
        template_name_snapshot="Pre-Match",
        is_template_based=True,
    )
    pre_match_practice.blocks = [
        PracticeBlock(
            block_order=1,
            block_type=PracticeBlockType.warm_up,
            title="Flow warm-up",
            duration_minutes=10,
        ),
        PracticeBlock(
            block_order=2,
            block_type=PracticeBlockType.drilling,
            title="Best attacks from each weight",
            duration_minutes=15,
        ),
        PracticeBlock(
            block_order=3,
            block_type=PracticeBlockType.live_goes,
            title="Short situational goes",
            duration_minutes=12,
        ),
        PracticeBlock(
            block_order=4,
            block_type=PracticeBlockType.cool_down,
            title="Stretch and reminders",
            duration_minutes=8,
        ),
    ]
    pre_match_practice.total_duration_minutes = 45
    db.add(pre_match_practice)
    db.flush()

    db.add_all(
        [
            Event(
                team_id=team.id,
                created_by_user_id=coach.id,
                practice_plan_id=hard_practice.id,
                title="Thursday Hard Room",
                description=hard_practice.description,
                event_type=EventType.practice,
                starts_at=(datetime.utcnow() + timedelta(days=1)).replace(hour=16, minute=0, second=0, microsecond=0),
                ends_at=(datetime.utcnow() + timedelta(days=1)).replace(hour=17, minute=45, second=0, microsecond=0),
                location="Riverdale Wrestling Room",
                notes="Varsity first. JV can stay for conditioning add-on.",
                checklist=["Headgear", "Practice gear", "Water jug", "Film notebook"],
            ),
            Event(
                team_id=team.id,
                created_by_user_id=coach.id,
                practice_plan_id=pre_match_practice.id,
                title="Saturday Pre-Match Tune-Up",
                description=pre_match_practice.description,
                event_type=EventType.practice,
                starts_at=(datetime.utcnow() + timedelta(days=3)).replace(hour=9, minute=0, second=0, microsecond=0),
                ends_at=(datetime.utcnow() + timedelta(days=3)).replace(hour=9, minute=50, second=0, microsecond=0),
                location="Riverdale Wrestling Room",
                notes="Short session before travel.",
                checklist=["Headgear", "Team warm-up shirt"],
            ),
            Event(
                team_id=team.id,
                created_by_user_id=coach.id,
                title="Riverdale vs. North Ridge",
                description="Home dual with full varsity lineup.",
                event_type=EventType.dual_meet,
                starts_at=(datetime.utcnow() + timedelta(days=4)).replace(hour=18, minute=30, second=0, microsecond=0),
                ends_at=(datetime.utcnow() + timedelta(days=4)).replace(hour=21, minute=0, second=0, microsecond=0),
                location="Riverdale Main Gym",
                notes="Lineup card due 45 minutes before first whistle.",
                checklist=["Singlet", "Headgear", "Warm-up gear"],
                weigh_in_note="Weigh-ins begin at 5:30 PM in the auxiliary locker room.",
            ),
            Event(
                team_id=team.id,
                created_by_user_id=coach.id,
                title="Bus Departure: North Ridge Dual",
                description="Travel load time for JV and varsity support group.",
                event_type=EventType.travel,
                starts_at=(datetime.utcnow() + timedelta(days=4)).replace(hour=16, minute=45, second=0, microsecond=0),
                ends_at=(datetime.utcnow() + timedelta(days=4)).replace(hour=17, minute=15, second=0, microsecond=0),
                location="Riverdale Bus Loop",
                notes="Roll call at 4:40 PM sharp.",
                checklist=["Team backpack", "Recovery snack"],
                bus_departure_note="Bus leaves at 4:50 PM. No late loading.",
            ),
            Event(
                team_id=team.id,
                created_by_user_id=coach.id,
                title="Booster Club Team Dinner",
                description="Fundraiser dinner with parents and alumni support.",
                event_type=EventType.fundraiser,
                starts_at=(datetime.utcnow() + timedelta(days=6)).replace(hour=18, minute=0, second=0, microsecond=0),
                ends_at=(datetime.utcnow() + timedelta(days=6)).replace(hour=20, minute=0, second=0, microsecond=0),
                location="Riverdale Commons",
                notes="Athletes wear school polos if attending.",
            ),
        ]
    )

    announcement_thread = MessageThread(
        team_id=team.id,
        title="Practice Schedule Update",
        thread_type=MessageThreadType.announcement,
        created_by_user_id=coach.id,
        parent_visibility_required=True,
        is_compliance_locked=True,
        visibility_flags={"announcement_scope": "team", "seeded": True},
    )
    db.add(announcement_thread)
    db.flush()

    db.add_all(
        [
            MessageParticipant(
                thread_id=announcement_thread.id,
                team_id=team.id,
                user_id=coach.id,
                participant_type=MessageParticipantType.member,
            ),
            MessageParticipant(
                thread_id=announcement_thread.id,
                team_id=team.id,
                user_id=athlete.id,
                participant_type=MessageParticipantType.member,
            ),
            MessageParticipant(
                thread_id=announcement_thread.id,
                team_id=team.id,
                user_id=parent.id,
                participant_type=MessageParticipantType.parent_visibility,
                visibility_flags={"auto_included_reason": "auto-added for athlete Tyson Reed"},
            ),
        ]
    )
    db.flush()

    announcement_message = Message(
        thread_id=announcement_thread.id,
        team_id=team.id,
        sender_id=coach.id,
        body="Practice moves to 6:00 PM on Thursday. Parents can pick up from the wrestling room entrance.",
        message_type=MessageType.announcement,
        visibility_flags={"announcement": True, "seeded": True},
    )
    db.add(announcement_message)
    db.flush()

    db.add(
        Announcement(
            thread_id=announcement_thread.id,
            team_id=team.id,
            sender_id=coach.id,
            title="Practice Schedule Update",
            body=announcement_message.body,
            audience_label="team",
            visibility_flags={"parent_visibility_enforced": True, "seeded": True},
        )
    )

    direct_thread = MessageThread(
        team_id=team.id,
        title="Tyson Reed Check-In",
        thread_type=MessageThreadType.direct,
        created_by_user_id=coach.id,
        parent_visibility_required=True,
        visibility_flags={"parent_visibility_enforced": True, "seeded": True},
    )
    db.add(direct_thread)
    db.flush()

    db.add_all(
        [
            MessageParticipant(
                thread_id=direct_thread.id,
                team_id=team.id,
                user_id=coach.id,
                participant_type=MessageParticipantType.member,
            ),
            MessageParticipant(
                thread_id=direct_thread.id,
                team_id=team.id,
                user_id=athlete.id,
                participant_type=MessageParticipantType.member,
            ),
            MessageParticipant(
                thread_id=direct_thread.id,
                team_id=team.id,
                user_id=parent.id,
                participant_type=MessageParticipantType.parent_visibility,
                visibility_flags={"auto_included_reason": "auto-added for athlete Tyson Reed"},
            ),
        ]
    )
    db.flush()

    check_in = Message(
        thread_id=direct_thread.id,
        team_id=team.id,
        sender_id=coach.id,
        body="Checking in on recovery after yesterday's practice. Keep your parent looped in here for any updates.",
        message_type=MessageType.text,
        visibility_flags={"parent_visibility_enforced": True, "seeded": True},
    )
    db.add(check_in)
    db.flush()

    db.add_all(
        [
            MessageAuditLog(
                team_id=team.id,
                thread_id=announcement_thread.id,
                message_id=announcement_message.id,
                actor_id=coach.id,
                action=AuditAction.announcement_sent,
                entity_type="announcement",
                entity_id=announcement_thread.id,
                after_state={"title": "Practice Schedule Update"},
                visibility_flags={"seeded": True},
                compliance_note="Seeded team announcement with parent visibility",
            ),
            MessageAuditLog(
                team_id=team.id,
                thread_id=direct_thread.id,
                message_id=check_in.id,
                actor_id=coach.id,
                action=AuditAction.message_sent,
                entity_type="message",
                entity_id=check_in.id,
                after_state={"body": check_in.body},
                visibility_flags={"seeded": True},
                compliance_note="Seeded direct thread including linked parent",
            ),
        ]
    )

    first_log = WeightLog(
        athlete_id=athlete.id,
        team_id=team.id,
        created_by_user_id=athlete.id,
        logged_at=(datetime.utcnow() - timedelta(days=6)).replace(hour=7, minute=15, second=0, microsecond=0),
        weight=149.2,
        body_fat_percentage=11.5,
        hydration_note="Hydrated well after practice.",
        comments="Morning check-in before school.",
    )
    second_log = WeightLog(
        athlete_id=athlete.id,
        team_id=team.id,
        created_by_user_id=athlete.id,
        logged_at=(datetime.utcnow() - timedelta(days=1)).replace(hour=7, minute=10, second=0, microsecond=0),
        weight=147.8,
        body_fat_percentage=11.1,
        hydration_note="Steady hydration all day.",
        comments="Feeling on plan for the week.",
    )
    db.add_all([first_log, second_log])
    db.flush()

    target = AthleteTarget(
        athlete_id=athlete.id,
        team_id=team.id,
        target_weight_class=144,
        target_date=date.today() + timedelta(days=21),
        body_fat_percentage=11.1,
        created_by_user_id=coach.id,
    )
    db.add(target)
    db.flush()

    plan_payload = calculate_plan(
        current_weight=147.8,
        body_fat_percentage=11.1,
        target_weight_class=144,
        target_date=target.target_date,
    )
    plan = WeightPlan(
        athlete_id=athlete.id,
        team_id=team.id,
        athlete_target_id=target.id,
        current_weight=plan_payload["current_weight"],
        body_fat_percentage=plan_payload["body_fat_percentage"],
        target_weight_class=plan_payload["target_weight_class"],
        target_date=plan_payload["target_date"],
        weekly_allowed_loss=plan_payload["weekly_allowed_loss"],
        required_weekly_loss=plan_payload["required_weekly_loss"],
        projected_reachable_weight=plan_payload["projected_reachable_weight"],
        estimated_reachable_class=plan_payload["estimated_reachable_class"],
        projected_target_date=plan_payload["projected_target_date"],
        status=plan_payload["status"],
        warning_message=plan_payload["warning_message"],
        summary=plan_payload["summary"],
        plan_details=plan_payload["plan_details"],
    )
    db.add(plan)
    db.flush()

    db.add(
        WeightAlert(
            athlete_id=athlete.id,
            team_id=team.id,
            plan_id=plan.id,
            alert_type=WeightAlertType.approaching_weigh_in,
            alert_message="Tyson Reed is inside the weigh-in planning window for the current class target.",
            severity=WeightPlanStatus.yellow,
        )
    )

    vendors = [
        Vendor(
            name="Mat Supply Co.",
            code="MATSUP",
            website_url="https://example.com/matsupply",
            contact_name="Dana Lowe",
            supports_dropship=True,
        ),
        Vendor(
            name="Wrestle Gear Direct",
            code="WGD",
            website_url="https://example.com/wgd",
            contact_name="Chris Vale",
            supports_dropship=True,
        ),
        Vendor(
            name="Team Basics Apparel",
            code="TBA",
            website_url="https://example.com/team-basics",
            contact_name="Lena Ortiz",
            supports_dropship=True,
        ),
    ]
    db.add_all(vendors)
    db.flush()

    categories = [
        ProductCategory(slug="medical", name="Medical", description="Tape, braces, and recovery essentials.", icon_name="medical_services", sort_order=1),
        ProductCategory(slug="mat-tape", name="Mat Tape", description="Mat repair and edge security supplies.", icon_name="construction", sort_order=2),
        ProductCategory(slug="sanitizing", name="Sanitizing", description="Cleaning supplies for the room and tournament tables.", icon_name="cleaning_services", sort_order=3),
        ProductCategory(slug="equipment", name="Equipment", description="Core wrestling equipment for athletes and staff.", icon_name="sports_mma", sort_order=4),
        ProductCategory(slug="scoring-supplies", name="Scoring Supplies", description="Meet-day table and scorekeeping supplies.", icon_name="scoreboard", sort_order=5),
        ProductCategory(slug="training-accessories", name="Training Accessories", description="Conditioning and movement extras for the room.", icon_name="fitness_center", sort_order=6),
        ProductCategory(slug="apparel-basics", name="Apparel Basics", description="Plain school store apparel ready for future merch expansion.", icon_name="checkroom", sort_order=7),
    ]
    db.add_all(categories)
    db.flush()
    category_by_slug = {category.slug: category for category in categories}

    products = [
        Product(category_id=category_by_slug["medical"].id, vendor_id=vendors[1].id, name="Athletic Tape", description="1.5-inch white athletic tape for practice and competition prep.", sku="MED-TAPE-001", cost_price=2.15, sell_price=4.99, stock_status=StockStatus.in_stock, visibility=ProductVisibility.both, is_featured=True, inventory_tracked=True, inventory_count=180, image_url="https://placehold.co/800x800/png?text=Athletic+Tape", brand_name="Wrestle Gear Direct", unit_label="roll"),
        Product(category_id=category_by_slug["medical"].id, vendor_id=vendors[1].id, name="Pre-Wrap", description="Foam pre-wrap for ankles, wrists, and quick support setups.", sku="MED-PRE-002", cost_price=1.75, sell_price=3.99, stock_status=StockStatus.in_stock, visibility=ProductVisibility.both, inventory_tracked=True, inventory_count=140, image_url="https://placehold.co/800x800/png?text=Pre-Wrap", brand_name="Wrestle Gear Direct", unit_label="roll"),
        Product(category_id=category_by_slug["medical"].id, vendor_id=vendors[1].id, name="Support Brace", description="Flexible brace for knee or elbow support during training.", sku="MED-BRACE-003", cost_price=10.50, sell_price=19.99, stock_status=StockStatus.in_stock, visibility=ProductVisibility.individual_only, inventory_tracked=False, image_url="https://placehold.co/800x800/png?text=Brace", brand_name="Wrestle Gear Direct", unit_label="each"),
        Product(category_id=category_by_slug["medical"].id, vendor_id=vendors[1].id, name="Reusable Ice Pack", description="Reusable cold pack for post-practice recovery and training room use.", sku="MED-ICE-004", cost_price=3.90, sell_price=8.99, stock_status=StockStatus.low_stock, visibility=ProductVisibility.both, inventory_tracked=True, inventory_count=36, image_url="https://placehold.co/800x800/png?text=Ice+Pack", brand_name="Wrestle Gear Direct", unit_label="each"),
        Product(category_id=category_by_slug["mat-tape"].id, vendor_id=vendors[0].id, name="Competition Mat Tape", description="Strong vinyl mat tape for seam and edge work.", sku="MAT-TAPE-010", cost_price=7.95, sell_price=14.99, stock_status=StockStatus.in_stock, visibility=ProductVisibility.team_only, is_featured=True, inventory_tracked=True, inventory_count=60, image_url="https://placehold.co/800x800/png?text=Mat+Tape", brand_name="Mat Supply Co.", unit_label="roll"),
        Product(category_id=category_by_slug["sanitizing"].id, vendor_id=vendors[0].id, name="Disinfectant Spray", description="Fast-drying spray for mats, benches, and shared hard surfaces.", sku="SAN-SPRAY-020", cost_price=5.20, sell_price=9.99, stock_status=StockStatus.in_stock, visibility=ProductVisibility.team_only, inventory_tracked=True, inventory_count=48, image_url="https://placehold.co/800x800/png?text=Disinfectant+Spray", brand_name="Mat Supply Co.", unit_label="bottle"),
        Product(category_id=category_by_slug["sanitizing"].id, vendor_id=vendors[0].id, name="Sanitizing Wipes", description="Bulk wipes for scoring tables, training room, and travel kits.", sku="SAN-WIPES-021", cost_price=4.40, sell_price=8.49, stock_status=StockStatus.in_stock, visibility=ProductVisibility.team_only, inventory_tracked=True, inventory_count=72, image_url="https://placehold.co/800x800/png?text=Wipes", brand_name="Mat Supply Co.", unit_label="tub"),
        Product(category_id=category_by_slug["equipment"].id, vendor_id=vendors[1].id, name="Knee Pads", description="Lightweight knee pad pair for drilling and live work.", sku="EQ-KNEE-030", cost_price=12.00, sell_price=24.99, stock_status=StockStatus.in_stock, visibility=ProductVisibility.individual_only, is_featured=True, inventory_tracked=False, image_url="https://placehold.co/800x800/png?text=Knee+Pads", brand_name="Wrestle Gear Direct", unit_label="pair"),
        Product(category_id=category_by_slug["equipment"].id, vendor_id=vendors[1].id, name="Headgear", description="Classic ear protection approved for practice and competition.", sku="EQ-HEAD-031", cost_price=19.50, sell_price=39.99, stock_status=StockStatus.in_stock, visibility=ProductVisibility.both, inventory_tracked=False, image_url="https://placehold.co/800x800/png?text=Headgear", brand_name="Wrestle Gear Direct", unit_label="each"),
        Product(category_id=category_by_slug["scoring-supplies"].id, vendor_id=vendors[0].id, name="Stopwatch", description="Simple stopwatch for weigh-ins, drills, and table work.", sku="SC-STOP-040", cost_price=6.00, sell_price=12.99, stock_status=StockStatus.in_stock, visibility=ProductVisibility.team_only, inventory_tracked=True, inventory_count=20, image_url="https://placehold.co/800x800/png?text=Stopwatch", brand_name="Mat Supply Co.", unit_label="each"),
        Product(category_id=category_by_slug["scoring-supplies"].id, vendor_id=vendors[0].id, name="Scorebook", description="Meet-day scorebook for duals and small tournaments.", sku="SC-BOOK-041", cost_price=4.25, sell_price=9.49, stock_status=StockStatus.in_stock, visibility=ProductVisibility.team_only, inventory_tracked=True, inventory_count=24, image_url="https://placehold.co/800x800/png?text=Scorebook", brand_name="Mat Supply Co.", unit_label="each"),
        Product(category_id=category_by_slug["scoring-supplies"].id, vendor_id=vendors[0].id, name="Flip Scoreboard", description="Portable tabletop flip scoreboard for side mats and events.", sku="SC-FLIP-042", cost_price=18.75, sell_price=34.99, stock_status=StockStatus.low_stock, visibility=ProductVisibility.team_only, inventory_tracked=True, inventory_count=6, image_url="https://placehold.co/800x800/png?text=Flip+Scoreboard", brand_name="Mat Supply Co.", unit_label="each"),
        Product(category_id=category_by_slug["training-accessories"].id, vendor_id=vendors[1].id, name="Cones Set", description="Training cones for movement, shots, and scramble stations.", sku="TA-CONES-050", cost_price=9.10, sell_price=17.99, stock_status=StockStatus.in_stock, visibility=ProductVisibility.team_only, inventory_tracked=True, inventory_count=16, image_url="https://placehold.co/800x800/png?text=Cones", brand_name="Wrestle Gear Direct", unit_label="set"),
        Product(category_id=category_by_slug["training-accessories"].id, vendor_id=vendors[1].id, name="Resistance Bands", description="Five-band pack for activation and warm-up routines.", sku="TA-BANDS-051", cost_price=6.30, sell_price=14.99, stock_status=StockStatus.in_stock, visibility=ProductVisibility.both, inventory_tracked=False, image_url="https://placehold.co/800x800/png?text=Resistance+Bands", brand_name="Wrestle Gear Direct", unit_label="set"),
        Product(category_id=category_by_slug["training-accessories"].id, vendor_id=vendors[1].id, name="Agility Ladder", description="Flat agility ladder for warm-up footwork and speed work.", sku="TA-LADDER-052", cost_price=14.60, sell_price=29.99, stock_status=StockStatus.backordered, visibility=ProductVisibility.team_only, allow_backorder=True, inventory_tracked=False, image_url="https://placehold.co/800x800/png?text=Agility+Ladder", brand_name="Wrestle Gear Direct", unit_label="each"),
        Product(category_id=category_by_slug["apparel-basics"].id, vendor_id=vendors[2].id, name="Plain Team Shirt", description="Soft dark team shirt for athletes, parents, and coaches.", sku="APP-SHIRT-060", cost_price=8.20, sell_price=19.99, stock_status=StockStatus.in_stock, visibility=ProductVisibility.both, is_featured=True, inventory_tracked=False, image_url="https://placehold.co/800x800/png?text=Team+Shirt", brand_name="Team Basics Apparel", unit_label="each"),
        Product(category_id=category_by_slug["apparel-basics"].id, vendor_id=vendors[2].id, name="Plain Team Hoodie", description="Heavyweight hoodie ready for future merch personalization.", sku="APP-HOODIE-061", cost_price=18.50, sell_price=42.99, stock_status=StockStatus.in_stock, visibility=ProductVisibility.both, is_featured=True, inventory_tracked=False, image_url="https://placehold.co/800x800/png?text=Team+Hoodie", brand_name="Team Basics Apparel", unit_label="each"),
    ]
    db.add_all(products)
    db.flush()

    for product in products:
        db.add(
            ProductImage(
                product_id=product.id,
                image_url=product.image_url,
                alt_text=f"{product.name} product image",
                sort_order=1,
            )
        )
    db.flush()

    featured_ids = [product.id for product in products if product.is_featured][:6]
    enabled_category_ids = [category.id for category in categories]
    db.add(
        TeamStoreConfig(
            team_id=team.id,
            store_name="Riverdale Wrestling Team Store",
            store_tagline="Practice-room essentials, family gear, and bulk supply ordering in one place.",
            is_store_enabled=True,
            allow_athlete_checkout=False,
            school_gear_enabled=True,
            featured_product_ids_csv=",".join(str(value) for value in featured_ids),
            enabled_category_ids_csv=",".join(str(value) for value in enabled_category_ids),
            announcement_text="Coach-approved supply ordering is open for the upcoming tournament block.",
            created_by_user_id=coach.id,
            updated_by_user_id=coach.id,
        )
    )
    db.flush()

    product_by_sku = {product.sku: product for product in products}
    parent_cart = CartItem(
        team_id=team.id,
        user_id=parent.id,
        product_id=product_by_sku["APP-SHIRT-060"].id,
        order_type=OrderType.individual,
        quantity=2,
        notes="One adult medium and one youth large.",
    )
    coach_cart = CartItem(
        team_id=team.id,
        user_id=coach.id,
        product_id=product_by_sku["SAN-SPRAY-020"].id,
        order_type=OrderType.team_supply,
        quantity=4,
        notes="Restock before the dual and team camp weekend.",
    )
    db.add_all([parent_cart, coach_cart])
    db.flush()

    team_order = Order(
        team_id=team.id,
        purchaser_id=coach.id,
        purchaser_role=PurchaserRole.coach,
        order_type=OrderType.team_supply,
        status=OrderStatus.processing,
        shipping_status=ShippingStatus.packed,
        subtotal=69.92,
        shipping_cost=12.00,
        total=81.92,
        notes="Tournament supply restock for practice room and scorer's table.",
        shipping_address="Riverdale High Wrestling Room, 200 Main St, Riverdale, NY 10471",
        shipping_carrier="UPS",
        vendor_reference="RHS-SUPPLY-1001",
    )
    db.add(team_order)
    db.flush()
    db.add_all(
        [
            OrderItem(
                order_id=team_order.id,
                product_id=product_by_sku["MAT-TAPE-010"].id,
                vendor_id=product_by_sku["MAT-TAPE-010"].vendor_id,
                product_name_snapshot=product_by_sku["MAT-TAPE-010"].name,
                sku_snapshot=product_by_sku["MAT-TAPE-010"].sku,
                quantity=2,
                unit_cost_price=7.95,
                unit_sell_price=14.99,
                line_total=29.98,
                shipping_status=ShippingStatus.packed,
            ),
            OrderItem(
                order_id=team_order.id,
                product_id=product_by_sku["SAN-SPRAY-020"].id,
                vendor_id=product_by_sku["SAN-SPRAY-020"].vendor_id,
                product_name_snapshot=product_by_sku["SAN-SPRAY-020"].name,
                sku_snapshot=product_by_sku["SAN-SPRAY-020"].sku,
                quantity=4,
                unit_cost_price=5.20,
                unit_sell_price=9.99,
                line_total=39.96,
                shipping_status=ShippingStatus.packed,
            ),
        ]
    )

    parent_order = Order(
        team_id=team.id,
        purchaser_id=parent.id,
        purchaser_role=PurchaserRole.parent,
        order_type=OrderType.individual,
        status=OrderStatus.shipped,
        shipping_status=ShippingStatus.shipped,
        subtotal=62.98,
        shipping_cost=7.50,
        total=70.48,
        notes="Family order for Tyson's weekend tournament setup.",
        shipping_address="18 Hudson Ave, Riverdale, NY 10471",
        shipping_carrier="USPS",
        tracking_number="9400-RHS-STORE-1002",
    )
    db.add(parent_order)
    db.flush()
    db.add_all(
        [
            OrderItem(
                order_id=parent_order.id,
                product_id=product_by_sku["EQ-HEAD-031"].id,
                vendor_id=product_by_sku["EQ-HEAD-031"].vendor_id,
                product_name_snapshot=product_by_sku["EQ-HEAD-031"].name,
                sku_snapshot=product_by_sku["EQ-HEAD-031"].sku,
                quantity=1,
                unit_cost_price=19.50,
                unit_sell_price=39.99,
                line_total=39.99,
                shipping_status=ShippingStatus.shipped,
            ),
            OrderItem(
                order_id=parent_order.id,
                product_id=product_by_sku["APP-SHIRT-060"].id,
                vendor_id=product_by_sku["APP-SHIRT-060"].vendor_id,
                product_name_snapshot=product_by_sku["APP-SHIRT-060"].name,
                sku_snapshot=product_by_sku["APP-SHIRT-060"].sku,
                quantity=1,
                unit_cost_price=8.20,
                unit_sell_price=19.99,
                line_total=19.99,
                shipping_status=ShippingStatus.shipped,
            ),
            OrderItem(
                order_id=parent_order.id,
                product_id=product_by_sku["MED-PRE-002"].id,
                vendor_id=product_by_sku["MED-PRE-002"].vendor_id,
                product_name_snapshot=product_by_sku["MED-PRE-002"].name,
                sku_snapshot=product_by_sku["MED-PRE-002"].sku,
                quantity=1,
                unit_cost_price=1.75,
                unit_sell_price=3.99,
                line_total=3.99,
                shipping_status=ShippingStatus.shipped,
            ),
        ]
    )

    stats_matches = [
        (
            athlete,
            "Nolan Price",
            "North Ridge",
            "Riverdale Dual",
            date.today() - timedelta(days=8),
            "144 lbs",
            MatchOutcome.win,
            MatchResultType.pin,
            7,
            2,
            "3:42",
            {"takedowns": 3, "escapes": 1, "reversals": 0, "nearfall_points": 2, "stall_calls": 0, "shot_attempts": 5, "shot_conversions": 3},
        ),
        (
            athlete,
            "Ben Salas",
            "Hudson Prep",
            "Hudson Invite",
            date.today() - timedelta(days=6),
            "144 lbs",
            MatchOutcome.win,
            MatchResultType.major_decision,
            12,
            3,
            None,
            {"takedowns": 4, "escapes": 2, "reversals": 0, "nearfall_points": 4, "stall_calls": 1, "shot_attempts": 8, "shot_conversions": 4},
        ),
        (
            athlete,
            "Carter Mills",
            "St. James",
            "Hudson Invite",
            date.today() - timedelta(days=4),
            "144 lbs",
            MatchOutcome.loss,
            MatchResultType.decision,
            4,
            6,
            None,
            {"takedowns": 1, "escapes": 1, "reversals": 0, "nearfall_points": 0, "stall_calls": 0, "shot_attempts": 4, "shot_conversions": 1},
        ),
        (
            athlete_two,
            "Luca Bryant",
            "North Shore",
            "Section Qualifier",
            date.today() - timedelta(days=10),
            "157 lbs",
            MatchOutcome.win,
            MatchResultType.tech_fall,
            17,
            1,
            None,
            {"takedowns": 5, "escapes": 1, "reversals": 1, "nearfall_points": 6, "stall_calls": 0, "shot_attempts": 7, "shot_conversions": 5},
        ),
        (
            athlete_two,
            "Evan Knox",
            "Ridgefield",
            "Section Qualifier",
            date.today() - timedelta(days=3),
            "157 lbs",
            MatchOutcome.win,
            MatchResultType.decision,
            8,
            5,
            None,
            {"takedowns": 3, "escapes": 1, "reversals": 1, "nearfall_points": 0, "stall_calls": 0, "shot_attempts": 6, "shot_conversions": 3},
        ),
        (
            athlete_three,
            "Parker Dunn",
            "Kingston",
            "JV Showcase",
            date.today() - timedelta(days=2),
            "132 lbs",
            MatchOutcome.win,
            MatchResultType.pin,
            10,
            2,
            "1:56",
            {"takedowns": 4, "escapes": 1, "reversals": 0, "nearfall_points": 2, "stall_calls": 0, "shot_attempts": 6, "shot_conversions": 4},
        ),
    ]
    created_matches: list[Match] = []
    for athlete_user, opponent_name, opponent_school, event_name, match_date, weight_class, result, result_type, score_for, score_against, pin_time, stat_payload in stats_matches:
        match = Match(
            athlete_id=athlete_user.id,
            team_id=team.id,
            created_by_user_id=coach.id,
            updated_by_user_id=coach.id,
            opponent_name=opponent_name,
            opponent_school=opponent_school,
            event_name=event_name,
            match_date=match_date,
            weight_class=weight_class,
            result=result,
            result_type=result_type,
            score_for=score_for,
            score_against=score_against,
            pin_time=pin_time,
        )
        db.add(match)
        db.flush()
        db.add(
            MatchStats(
                match_id=match.id,
                athlete_id=athlete_user.id,
                team_id=team.id,
                takedowns=stat_payload["takedowns"],
                escapes=stat_payload["escapes"],
                reversals=stat_payload["reversals"],
                nearfall_points=stat_payload["nearfall_points"],
                stall_calls=stat_payload["stall_calls"],
                shot_attempts=stat_payload["shot_attempts"],
                shot_conversions=stat_payload["shot_conversions"],
            )
        )
        created_matches.append(match)

    db.add_all(
        [
            AthleteStatSnapshot(
                team_id=team.id,
                athlete_id=athlete.id,
                total_matches=3,
                wins=2,
                losses=1,
                win_percentage=0.667,
                bonus_point_rate=0.667,
                recent_trend="trending up",
                strengths_summary="Strong re-attacks and pressure finishes",
                weaknesses_summary="Needs cleaner hand-fight exits",
                summary_payload={"takedowns_per_match": 2.7, "shot_conversion_rate": 0.47},
            ),
            AthleteStatSnapshot(
                team_id=team.id,
                athlete_id=athlete_two.id,
                total_matches=2,
                wins=2,
                losses=0,
                win_percentage=1.0,
                bonus_point_rate=0.5,
                recent_trend="hot streak",
                strengths_summary="Dominant top pressure",
                weaknesses_summary="Can open matches faster",
                summary_payload={"takedowns_per_match": 4.0, "shot_conversion_rate": 0.62},
            ),
            AthleteStatSnapshot(
                team_id=team.id,
                athlete_id=athlete_three.id,
                total_matches=1,
                wins=1,
                losses=0,
                win_percentage=1.0,
                bonus_point_rate=1.0,
                recent_trend="rising fast",
                strengths_summary="Fast finishes and confident attacks",
                weaknesses_summary="Small sample size",
                summary_payload={"takedowns_per_match": 4.0, "shot_conversion_rate": 0.67},
            ),
        ]
    )

    recruiting_profiles = [
        (
            athlete,
            {
                "graduation_year": 2027,
                "school_team": "Riverdale High Varsity",
                "weight_class": "144 lbs",
                "height": "5'8\"",
                "gpa": "3.7",
                "bio": "Fast neutral wrestler with pressure pace, strong re-attacks, and leadership in big dual moments.",
                "achievements": ["Section finalist", "2x team captain", "38-11 last season"],
                "contact_email": "family.reed@wrestlingos.com",
                "contact_phone": "555-1102",
                "location_label": "Riverdale, NY",
                "stats_summary": {"takedowns_per_match": 2.7, "shot_conversion_rate": 0.47, "recent_matches": 3},
                "profile_image_url": athlete.profile_image_url,
                "is_open": True,
                "is_actively_looking": True,
                "is_featured": True,
                "visibility_level": RecruitingVisibilityLevel.coaches_only,
                "contact_visibility": RecruitingContactVisibility.coaches_only,
                "visibility": {
                    "show_contact_to_coaches": True,
                    "show_gpa": True,
                    "show_location": True,
                    "show_profile_photo": True,
                    "parent_visibility_required": True,
                    "allow_direct_contact_request": True,
                },
                "highlights": [
                    ("Section Run Film", "https://www.youtube.com/watch?v=reed_section_run"),
                    ("Ride-and-Turn Breakdown", "https://www.youtube.com/watch?v=reed_top_work"),
                ],
            },
        ),
        (
            athlete_two,
            {
                "graduation_year": 2026,
                "school_team": "Riverdale High Varsity",
                "weight_class": "157 lbs",
                "height": "5'10\"",
                "gpa": "3.4",
                "bio": "Physical top wrestler with strong finishes and confident mat returns. Looking for programs that value pressure and grit.",
                "achievements": ["Section qualifier", "Regional podium finish", "28 bonus-point wins"],
                "contact_email": "mason.family@wrestlingos.com",
                "contact_phone": "555-2105",
                "location_label": "White Plains, NY",
                "stats_summary": {"takedowns_per_match": 4.0, "shot_conversion_rate": 0.62, "recent_matches": 2},
                "profile_image_url": athlete_two.profile_image_url,
                "is_open": True,
                "is_actively_looking": True,
                "is_featured": False,
                "visibility_level": RecruitingVisibilityLevel.coaches_only,
                "contact_visibility": RecruitingContactVisibility.coaches_only,
                "visibility": {
                    "show_contact_to_coaches": True,
                    "show_gpa": False,
                    "show_location": True,
                    "show_profile_photo": True,
                    "parent_visibility_required": True,
                    "allow_direct_contact_request": True,
                },
                "highlights": [
                    ("Section Qualifier Tech", "https://www.youtube.com/watch?v=cole_tech"),
                ],
            },
        ),
        (
            athlete_three,
            {
                "graduation_year": 2028,
                "school_team": "Riverdale High Rising Varsity",
                "weight_class": "132 lbs",
                "height": "5'6\"",
                "gpa": "3.9",
                "bio": "Young athlete building an exposure profile early with strong motion and fast attacks.",
                "achievements": ["JV showcase champion", "Offseason camp standout"],
                "contact_email": "eli.navarro@wrestlingos.com",
                "contact_phone": "555-3106",
                "location_label": "Yonkers, NY",
                "stats_summary": {"takedowns_per_match": 4.0, "shot_conversion_rate": 0.67, "recent_matches": 1},
                "profile_image_url": athlete_three.profile_image_url,
                "is_open": True,
                "is_actively_looking": False,
                "is_featured": True,
                "visibility_level": RecruitingVisibilityLevel.public,
                "contact_visibility": RecruitingContactVisibility.hidden,
                "visibility": {
                    "show_contact_to_coaches": False,
                    "show_gpa": True,
                    "show_location": True,
                    "show_profile_photo": True,
                    "parent_visibility_required": False,
                    "allow_direct_contact_request": True,
                },
                "highlights": [
                    ("JV Showcase Pin", "https://www.youtube.com/watch?v=navarro_pin"),
                    ("Summer Camp Scramble Finishes", "https://www.youtube.com/watch?v=navarro_camp"),
                ],
            },
        ),
    ]
    profile_by_athlete_id: dict[int, RecruitingProfile] = {}
    for athlete_user, profile_payload in recruiting_profiles:
        profile = RecruitingProfile(
            athlete_id=athlete_user.id,
            team_id=team.id,
            graduation_year=profile_payload["graduation_year"],
            school_team=profile_payload["school_team"],
            weight_class=profile_payload["weight_class"],
            height=profile_payload["height"],
            gpa=profile_payload["gpa"],
            bio=profile_payload["bio"],
            achievements=profile_payload["achievements"],
            contact_email=profile_payload["contact_email"],
            contact_phone=profile_payload["contact_phone"],
            location_label=profile_payload["location_label"],
            stats_summary=profile_payload["stats_summary"],
            profile_image_url=profile_payload["profile_image_url"],
            is_open=profile_payload["is_open"],
            is_actively_looking=profile_payload["is_actively_looking"],
            is_featured=profile_payload["is_featured"],
            visibility_level=profile_payload["visibility_level"],
            contact_visibility=profile_payload["contact_visibility"],
        )
        db.add(profile)
        db.flush()
        visibility_payload = profile_payload["visibility"]
        db.add(
            RecruitingVisibility(
                profile_id=profile.id,
                show_contact_to_coaches=visibility_payload["show_contact_to_coaches"],
                show_gpa=visibility_payload["show_gpa"],
                show_location=visibility_payload["show_location"],
                show_profile_photo=visibility_payload["show_profile_photo"],
                parent_visibility_required=visibility_payload["parent_visibility_required"],
                allow_direct_contact_request=visibility_payload["allow_direct_contact_request"],
            )
        )
        for index, (title, url) in enumerate(profile_payload["highlights"]):
            db.add(
                RecruitingHighlight(
                    athlete_id=athlete_user.id,
                    profile_id=profile.id,
                    title=title,
                    highlight_url=url,
                    sort_order=index,
                )
            )
        profile_by_athlete_id[athlete_user.id] = profile

    watchlist_entry = RecruitingWatchlist(
        coach_user_id=coach.id,
        athlete_id=athlete_two.id,
        team_id=team.id,
        profile_id=profile_by_athlete_id[athlete_two.id].id,
    )
    db.add(watchlist_entry)
    db.flush()
    db.add_all(
        [
            RecruitingTag(
                coach_user_id=coach.id,
                athlete_id=athlete_two.id,
                team_id=team.id,
                profile_id=profile_by_athlete_id[athlete_two.id].id,
                tag="Top Priority",
            ),
            RecruitingTag(
                coach_user_id=coach.id,
                athlete_id=athlete_two.id,
                team_id=team.id,
                profile_id=profile_by_athlete_id[athlete_two.id].id,
                tag="Strong Top Game",
            ),
            RecruitingNote(
                coach_user_id=coach.id,
                athlete_id=athlete_two.id,
                team_id=team.id,
                profile_id=profile_by_athlete_id[athlete_two.id].id,
                note="High motor with real top pressure. Worth follow-up after next qualifier.",
            ),
        ]
    )
    db.commit()
