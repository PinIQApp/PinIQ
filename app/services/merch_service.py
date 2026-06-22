from __future__ import annotations

import json
from datetime import datetime

from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload

from app.models.merch import (
    MerchDesign,
    MerchDesignLayer,
    MerchExport,
    MerchExportStatus,
    MerchExportType,
    MerchLayerType,
    MerchPlacement,
    MerchProduct,
    MerchProductType,
    MerchTemplate,
    TeamMerchConfig,
)
from app.models.messaging import ParentLink
from app.models.team import Team, TeamMember, TeamMemberStatus
from app.models.user import User, UserRole
from app.schemas.merch import (
    MerchDesignCreate,
    MerchDesignLayerInput,
    MerchDesignLayerRead,
    MerchDesignRead,
    MerchDesignUpdate,
    MerchExportRead,
    MerchExportRequest,
    MerchProductRead,
    MerchPublishResponse,
    MerchTemplateRead,
    TeamMerchConfigRead,
)


DEFAULT_PRODUCTS = [
    {
        "product_type": MerchProductType.hoodie,
        "slug": "hoodie",
        "name": "Team Hoodie",
        "description": "Heavyweight hoodie with front chest and back print zones.",
        "base_price": 44.0,
        "supported_views_csv": "front,back,side",
        "colorways_csv": "black,charcoal,heather_gray,school_primary",
        "supports_sleeve_print": True,
        "supports_back_print": True,
        "supports_sponsor_area": True,
    },
    {
        "product_type": MerchProductType.t_shirt,
        "slug": "t-shirt",
        "name": "Performance T-Shirt",
        "description": "Moisture-wicking tee for athletes, coaches, and fans.",
        "base_price": 24.0,
        "supported_views_csv": "front,back,side",
        "colorways_csv": "black,white,heather_gray,school_primary",
        "supports_sleeve_print": True,
        "supports_back_print": True,
        "supports_sponsor_area": True,
    },
    {
        "product_type": MerchProductType.joggers,
        "slug": "joggers",
        "name": "Travel Joggers",
        "description": "Warm-up joggers with leg placement zones and subtle side branding.",
        "base_price": 38.0,
        "supported_views_csv": "front,back,side",
        "colorways_csv": "black,charcoal,navy",
        "supports_sleeve_print": False,
        "supports_back_print": False,
        "supports_sponsor_area": False,
    },
    {
        "product_type": MerchProductType.quarter_zip,
        "slug": "quarter-zip",
        "name": "Quarter Zip",
        "description": "Coach-friendly layering piece with premium chest logo placement.",
        "base_price": 49.0,
        "supported_views_csv": "front,back,side",
        "colorways_csv": "black,graphite,school_primary",
        "supports_sleeve_print": True,
        "supports_back_print": True,
        "supports_sponsor_area": False,
    },
    {
        "product_type": MerchProductType.warm_up_set,
        "slug": "warm-up-set",
        "name": "Warm-Up Set",
        "description": "Coordinated jacket and pant set for travel and duals.",
        "base_price": 82.0,
        "supported_views_csv": "front,back,side",
        "colorways_csv": "black,graphite,school_primary",
        "supports_sleeve_print": True,
        "supports_back_print": True,
        "supports_sponsor_area": True,
    },
    {
        "product_type": MerchProductType.singlet,
        "slug": "singlet",
        "name": "Competition Singlet",
        "description": "Competition-ready singlet with chest, side, and lower-back print zones.",
        "base_price": 55.0,
        "supported_views_csv": "front,back,side",
        "colorways_csv": "black,navy,school_primary,school_secondary",
        "supports_sleeve_print": False,
        "supports_back_print": True,
        "supports_sponsor_area": False,
    },
    {
        "product_type": MerchProductType.fight_shorts,
        "slug": "fight-shorts",
        "name": "Fight Shorts",
        "description": "Training shorts with side panel and leg print zones.",
        "base_price": 34.0,
        "supported_views_csv": "front,back,side",
        "colorways_csv": "black,white,school_primary",
        "supports_sleeve_print": False,
        "supports_back_print": False,
        "supports_sponsor_area": False,
    },
    {
        "product_type": MerchProductType.compression_shirt,
        "slug": "compression-shirt",
        "name": "Compression Shirt",
        "description": "Tight-fit performance layer with minimalist athletic layout options.",
        "base_price": 32.0,
        "supported_views_csv": "front,back,side",
        "colorways_csv": "black,white,school_primary",
        "supports_sleeve_print": True,
        "supports_back_print": True,
        "supports_sponsor_area": False,
    },
    {
        "product_type": MerchProductType.fan_merch,
        "slug": "fan-merch",
        "name": "Fan Merch Item",
        "description": "Flexible fan item placeholder for hats, crewnecks, and accessories.",
        "base_price": 20.0,
        "supported_views_csv": "front,back",
        "colorways_csv": "black,white,school_primary,school_secondary",
        "supports_sleeve_print": False,
        "supports_back_print": True,
        "supports_sponsor_area": True,
    },
]

DEFAULT_TEMPLATES = [
    {
        "key": "clean-modern",
        "name": "Clean Modern",
        "description": "Sharp front chest branding with restrained back typography.",
        "style_notes": "Minimal blocking, strong wordmark hierarchy, easy for school approval.",
        "default_primary_color": "#111827",
        "default_secondary_color": "#E5E7EB",
        "default_accent_color": "#D4AF37",
        "recommended_product_types_csv": "hoodie,t_shirt,quarter_zip,fan_merch",
        "default_layer_schema": [
            {"layer_type": "logo", "placement": "chest", "sort_order": 1, "visible": True},
            {"layer_type": "text", "placement": "back", "sort_order": 2, "visible": True},
        ],
    },
    {
        "key": "aggressive-athletic",
        "name": "Aggressive Athletic",
        "description": "Competition-driven build with large mascot presence and accent striping.",
        "style_notes": "Best for singlets, compression gear, and training tops.",
        "default_primary_color": "#0F172A",
        "default_secondary_color": "#DC2626",
        "default_accent_color": "#F59E0B",
        "recommended_product_types_csv": "singlet,compression_shirt,fight_shorts,warm_up_set",
        "default_layer_schema": [
            {"layer_type": "mascot", "placement": "front", "sort_order": 1, "visible": True},
            {"layer_type": "text", "placement": "back", "sort_order": 2, "visible": True},
            {"layer_type": "accent", "placement": "side", "sort_order": 3, "visible": True},
        ],
    },
    {
        "key": "state-champ-style",
        "name": "State Champ Style",
        "description": "Bold championship framing with elevated back print and title lockup.",
        "style_notes": "Works well for team issue hoodies, tees, and warm-up sets.",
        "default_primary_color": "#111111",
        "default_secondary_color": "#C0841A",
        "default_accent_color": "#F8FAFC",
        "recommended_product_types_csv": "hoodie,t_shirt,warm_up_set",
        "default_layer_schema": [
            {"layer_type": "text", "placement": "front", "sort_order": 1, "visible": True},
            {"layer_type": "logo", "placement": "back", "sort_order": 2, "visible": True},
            {"layer_type": "sponsor", "placement": "lower_back", "sort_order": 3, "visible": True},
        ],
    },
    {
        "key": "military-inspired",
        "name": "Military-Inspired",
        "description": "Structured utility aesthetic with disciplined typography and sleeve callouts.",
        "style_notes": "Strong fit for quarter zips, joggers, and warm-up sets.",
        "default_primary_color": "#1F2937",
        "default_secondary_color": "#6B7280",
        "default_accent_color": "#84CC16",
        "recommended_product_types_csv": "quarter_zip,joggers,warm_up_set,hoodie",
        "default_layer_schema": [
            {"layer_type": "text", "placement": "chest", "sort_order": 1, "visible": True},
            {"layer_type": "text", "placement": "left_sleeve", "sort_order": 2, "visible": True},
            {"layer_type": "logo", "placement": "back", "sort_order": 3, "visible": True},
        ],
    },
    {
        "key": "minimal-fan-gear",
        "name": "Minimal Fan Gear",
        "description": "Low-noise fan design system for parent and student merch drops.",
        "style_notes": "Simple, clean, and easy to export into a larger team store flow.",
        "default_primary_color": "#0B1120",
        "default_secondary_color": "#F8FAFC",
        "default_accent_color": "#38BDF8",
        "recommended_product_types_csv": "fan_merch,t_shirt,hoodie",
        "default_layer_schema": [
            {"layer_type": "wordmark", "placement": "front", "sort_order": 1, "visible": True},
            {"layer_type": "logo", "placement": "back", "sort_order": 2, "visible": False},
        ],
    },
]


def _split_csv(value: str | None) -> list[str]:
    if not value:
        return []
    return [item.strip() for item in value.split(",") if item.strip()]


def _json_load(value: str | None, default: object) -> object:
    if not value:
        return default
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return default


def _json_dump(value: object) -> str:
    return json.dumps(value, separators=(",", ":"), sort_keys=True)


def _approved_membership(team: Team, user_id: int) -> TeamMember | None:
    return next(
        (
            member
            for member in team.memberships
            if member.user_id == user_id and member.status == TeamMemberStatus.approved
        ),
        None,
    )


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


def _is_linked_parent(db: Session, *, team_id: int, parent_user_id: int) -> bool:
    return (
        db.query(ParentLink)
        .filter(
            ParentLink.team_id == team_id,
            ParentLink.parent_user_id == parent_user_id,
            ParentLink.is_active.is_(True),
        )
        .first()
        is not None
    )


def _manager_role(team: Team, current_user: User) -> str | None:
    membership = _approved_membership(team, current_user.id)
    if current_user.role == UserRole.admin:
        return current_user.role.value
    if membership and current_user.role == UserRole.coach:
        return current_user.role.value
    return None


def _ensure_design_view_access(db: Session, team: Team, design: MerchDesign, current_user: User) -> None:
    if current_user.role == UserRole.admin:
        return
    membership = _approved_membership(team, current_user.id)
    if membership and current_user.role == UserRole.coach:
        return
    if design.is_published and membership is not None:
        return
    if design.is_published and current_user.role == UserRole.parent and _is_linked_parent(
        db, team_id=team.id, parent_user_id=current_user.id
    ):
        return
    raise HTTPException(status_code=403, detail="You are not allowed to view this merch design")


def _ensure_design_manage_access(team: Team, current_user: User) -> str:
    membership = _approved_membership(team, current_user.id)
    if current_user.role == UserRole.admin:
        return current_user.role.value
    if membership and current_user.role == UserRole.coach:
        return current_user.role.value
    raise HTTPException(status_code=403, detail="Only coaches or admins can manage team merch designs")


def _preview_placeholder(design_id: int, view: str) -> str:
    return f"/media/merch/designs/{design_id}/{view}-preview.png"


def _seed_products_and_templates(db: Session) -> None:
    has_products = db.query(MerchProduct.id).first() is not None
    has_templates = db.query(MerchTemplate.id).first() is not None
    if not has_products:
        for item in DEFAULT_PRODUCTS:
            db.add(MerchProduct(**item))
    if not has_templates:
        for item in DEFAULT_TEMPLATES:
            db.add(
                MerchTemplate(
                    key=item["key"],
                    name=item["name"],
                    description=item["description"],
                    style_notes=item["style_notes"],
                    recommended_product_types_csv=item["recommended_product_types_csv"],
                    default_primary_color=item["default_primary_color"],
                    default_secondary_color=item["default_secondary_color"],
                    default_accent_color=item["default_accent_color"],
                    default_layer_schema=_json_dump(item["default_layer_schema"]),
                )
            )
    if not has_products or not has_templates:
        db.flush()


def _get_or_create_team_config(db: Session, team: Team, current_user: User) -> TeamMerchConfig:
    config = db.query(TeamMerchConfig).filter(TeamMerchConfig.team_id == team.id).first()
    if config:
        return config

    config = TeamMerchConfig(
        team_id=team.id,
        school_name=team.school_name,
        mascot=team.mascot_name,
        school_colors_csv=",".join([team.primary_color, team.secondary_color, team.accent_color]),
        primary_logo_url=team.logo_url,
        secondary_logo_url=team.logo_url,
        alternate_wordmark_url=team.logo_url,
        sponsor_text_default=None,
        gallery_title=f"{team.school_name} Wrestling Merch",
        created_by_user_id=current_user.id,
        updated_by_user_id=current_user.id,
    )
    db.add(config)
    db.flush()
    return config


def _serialize_product(product: MerchProduct) -> MerchProductRead:
    return MerchProductRead(
        id=product.id,
        product_type=product.product_type,
        slug=product.slug,
        name=product.name,
        description=product.description,
        base_price=float(product.base_price),
        supported_views=_split_csv(product.supported_views_csv),
        colorways=_split_csv(product.colorways_csv),
        supports_sleeve_print=product.supports_sleeve_print,
        supports_back_print=product.supports_back_print,
        supports_sponsor_area=product.supports_sponsor_area,
        is_active=product.is_active,
    )


def _serialize_template(template: MerchTemplate) -> MerchTemplateRead:
    raw_product_types = _split_csv(template.recommended_product_types_csv)
    return MerchTemplateRead(
        id=template.id,
        key=template.key,
        name=template.name,
        description=template.description,
        style_notes=template.style_notes,
        recommended_product_types=[MerchProductType(value) for value in raw_product_types],
        default_primary_color=template.default_primary_color,
        default_secondary_color=template.default_secondary_color,
        default_accent_color=template.default_accent_color,
        default_layer_schema=_json_load(template.default_layer_schema, []),
        is_active=template.is_active,
    )


def _serialize_team_config(config: TeamMerchConfig) -> TeamMerchConfigRead:
    return TeamMerchConfigRead(
        id=config.id,
        team_id=config.team_id,
        school_name=config.school_name,
        mascot=config.mascot,
        school_colors=_split_csv(config.school_colors_csv),
        primary_logo_url=config.primary_logo_url,
        secondary_logo_url=config.secondary_logo_url,
        alternate_wordmark_url=config.alternate_wordmark_url,
        sponsor_text_default=config.sponsor_text_default,
        gallery_title=config.gallery_title,
        coach_notes=config.coach_notes,
        created_by_user_id=config.created_by_user_id,
        updated_by_user_id=config.updated_by_user_id,
        created_at=config.created_at,
        updated_at=config.updated_at,
    )


def _serialize_layer(layer: MerchDesignLayer) -> MerchDesignLayerRead:
    return MerchDesignLayerRead(
        id=layer.id,
        merch_design_id=layer.merch_design_id,
        layer_type=layer.layer_type,
        placement=layer.placement,
        asset_url=layer.asset_url,
        text_content=layer.text_content,
        text_style=layer.text_style,
        color_hex=layer.color_hex,
        sort_order=layer.sort_order,
        visible=layer.visible,
        layer_metadata=_json_load(layer.layer_metadata, {}),
        created_at=layer.created_at,
        updated_at=layer.updated_at,
    )


def _serialize_export(export: MerchExport) -> MerchExportRead:
    return MerchExportRead(
        id=export.id,
        merch_design_id=export.merch_design_id,
        requested_by_user_id=export.requested_by_user_id,
        export_type=export.export_type,
        status=export.status,
        file_url=export.file_url,
        notes=export.notes,
        requested_at=export.requested_at,
        completed_at=export.completed_at,
    )


def _build_preview_state(design: MerchDesign) -> dict[str, object]:
    layers = sorted(design.layers, key=lambda item: (item.sort_order, item.id))
    supported_views = _split_csv(design.product.supported_views_csv)
    view_layers: dict[str, list[dict[str, object]]] = {view: [] for view in supported_views}

    for layer in layers:
        placement_key = layer.placement.value
        if placement_key in {"front", "chest"}:
            target_view = "front"
        elif placement_key in {"back", "lower_back"}:
            target_view = "back"
        else:
            target_view = "side"
        view_layers.setdefault(target_view, []).append(
            {
                "id": layer.id,
                "layer_type": layer.layer_type.value,
                "placement": layer.placement.value,
                "asset_url": layer.asset_url,
                "text_content": layer.text_content,
                "text_style": layer.text_style,
                "color_hex": layer.color_hex,
                "visible": layer.visible,
                "sort_order": layer.sort_order,
                "metadata": _json_load(layer.layer_metadata, {}),
            }
        )

    return {
        "design_id": design.id,
        "product_type": design.product.product_type.value,
        "product_name": design.product.name,
        "template_name": design.template_name,
        "design_name": design.design_name,
        "colors": {
            "primary": design.primary_color,
            "secondary": design.secondary_color,
            "accent": design.accent_color,
            "colorway_name": design.colorway_name,
        },
        "branding": {
            "front_logo_url": design.front_logo_url,
            "back_logo_url": design.back_logo_url,
            "front_text": design.front_text,
            "back_text": design.back_text,
            "sleeve_text": design.sleeve_text,
            "sponsor_text": design.sponsor_text,
        },
        "views": [
            {
                "view": view,
                "base_color": design.primary_color if view != "back" else design.secondary_color,
                "placeholder_image_url": _preview_placeholder(design.id, view),
                "layers": view_layers.get(view, []),
            }
            for view in supported_views
        ],
        "export_placeholders": {
            "preview_image_url": design.preview_image_url,
            "print_layout_url": design.print_layout_url,
            "manufacturer_sheet_url": design.manufacturer_sheet_url,
        },
    }


def _apply_layers(design: MerchDesign, layers: list[MerchDesignLayerInput]) -> None:
    design.layers.clear()
    for layer in layers:
        design.layers.append(
            MerchDesignLayer(
                layer_type=layer.layer_type,
                placement=layer.placement,
                asset_url=layer.asset_url,
                text_content=layer.text_content,
                text_style=layer.text_style,
                color_hex=layer.color_hex,
                sort_order=layer.sort_order,
                visible=layer.visible,
                layer_metadata=_json_dump(layer.layer_metadata),
            )
        )


def _layer_inputs_from_template(
    template: MerchTemplate | None,
    *,
    config: TeamMerchConfig,
    design_name: str,
    front_text: str | None,
    back_text: str | None,
    sponsor_text: str | None,
) -> list[MerchDesignLayerInput]:
    if template is None:
        return []

    raw_layers = _json_load(template.default_layer_schema, [])
    inputs: list[MerchDesignLayerInput] = []
    for index, item in enumerate(raw_layers):
        if not isinstance(item, dict):
            continue
        layer_type_value = item.get("layer_type", "text")
        if layer_type_value == "wordmark":
            layer_type = MerchLayerType.text
            text_content = front_text or config.school_name
        elif layer_type_value == "logo":
            layer_type = MerchLayerType.logo
            text_content = None
        elif layer_type_value == "mascot":
            layer_type = MerchLayerType.mascot
            text_content = config.mascot
        elif layer_type_value == "sponsor":
            layer_type = MerchLayerType.sponsor
            text_content = sponsor_text or config.sponsor_text_default
        elif layer_type_value == "accent":
            layer_type = MerchLayerType.accent
            text_content = None
        else:
            layer_type = MerchLayerType.text
            placement_guess = str(item.get("placement", "front"))
            text_content = front_text if placement_guess in {"front", "chest"} else back_text or design_name

        placement = MerchPlacement(str(item.get("placement", "front")))
        asset_url = None
        if layer_type == MerchLayerType.logo:
            asset_url = config.primary_logo_url if placement in {MerchPlacement.front, MerchPlacement.chest} else config.secondary_logo_url
        inputs.append(
            MerchDesignLayerInput(
                layer_type=layer_type,
                placement=placement,
                asset_url=asset_url,
                text_content=text_content,
                text_style="varsity" if layer_type in {MerchLayerType.text, MerchLayerType.sponsor} else None,
                color_hex=None,
                sort_order=int(item.get("sort_order", index)),
                visible=bool(item.get("visible", True)),
                layer_metadata={"source": "template", "template_key": template.key},
            )
        )
    return inputs


def _serialize_design(design: MerchDesign) -> MerchDesignRead:
    return MerchDesignRead(
        id=design.id,
        team_id=design.team_id,
        created_by_user_id=design.created_by_user_id,
        merch_product_id=design.merch_product_id,
        merch_template_id=design.merch_template_id,
        team_merch_config_id=design.team_merch_config_id,
        design_name=design.design_name,
        template_name=design.template_name,
        primary_color=design.primary_color,
        secondary_color=design.secondary_color,
        accent_color=design.accent_color,
        colorway_name=design.colorway_name,
        front_logo_url=design.front_logo_url,
        back_logo_url=design.back_logo_url,
        front_text=design.front_text,
        back_text=design.back_text,
        sleeve_text=design.sleeve_text,
        sponsor_text=design.sponsor_text,
        notes=design.notes,
        preview_state=_json_load(design.preview_state, {}),
        preview_image_url=design.preview_image_url,
        print_layout_url=design.print_layout_url,
        manufacturer_sheet_url=design.manufacturer_sheet_url,
        export_status=design.export_status,
        is_published=design.is_published,
        published_at=design.published_at,
        created_at=design.created_at,
        updated_at=design.updated_at,
        product=_serialize_product(design.product),
        template=_serialize_template(design.template) if design.template else None,
        team_config=_serialize_team_config(design.team_config) if design.team_config else None,
        layers=[_serialize_layer(layer) for layer in sorted(design.layers, key=lambda item: (item.sort_order, item.id))],
        exports=[_serialize_export(export) for export in sorted(design.exports, key=lambda item: item.id)],
    )


def list_products(db: Session) -> list[MerchProductRead]:
    _seed_products_and_templates(db)
    products = (
        db.query(MerchProduct)
        .filter(MerchProduct.is_active.is_(True))
        .order_by(MerchProduct.id.asc())
        .all()
    )
    return [_serialize_product(product) for product in products]


def list_templates(db: Session) -> list[MerchTemplateRead]:
    _seed_products_and_templates(db)
    templates = (
        db.query(MerchTemplate)
        .filter(MerchTemplate.is_active.is_(True))
        .order_by(MerchTemplate.id.asc())
        .all()
    )
    return [_serialize_template(template) for template in templates]


def _query_designs(db: Session):
    return db.query(MerchDesign).options(
        joinedload(MerchDesign.product),
        joinedload(MerchDesign.template),
        joinedload(MerchDesign.team_config),
        joinedload(MerchDesign.layers),
        joinedload(MerchDesign.exports),
    )


def create_design(db: Session, *, payload: MerchDesignCreate, current_user: User) -> MerchDesignRead:
    _seed_products_and_templates(db)
    team = _load_team(db, payload.team_id)
    _ensure_design_manage_access(team, current_user)
    config = _get_or_create_team_config(db, team, current_user)

    product = (
        db.query(MerchProduct)
        .filter(MerchProduct.product_type == payload.product_type, MerchProduct.is_active.is_(True))
        .first()
    )
    if not product:
        raise HTTPException(status_code=404, detail="Merch product not found")

    template = None
    if payload.template_key:
        template = db.query(MerchTemplate).filter(MerchTemplate.key == payload.template_key).first()
        if not template:
            raise HTTPException(status_code=404, detail="Merch template not found")

    design = MerchDesign(
        team_id=team.id,
        created_by_user_id=current_user.id,
        merch_product_id=product.id,
        merch_template_id=template.id if template else None,
        team_merch_config_id=config.id,
        design_name=payload.design_name,
        template_name=template.name if template else None,
        primary_color=(
            payload.primary_color
            or (template.default_primary_color if template else None)
            or team.primary_color
        ),
        secondary_color=(
            payload.secondary_color
            or (template.default_secondary_color if template else None)
            or team.secondary_color
        ),
        accent_color=(
            payload.accent_color
            or (template.default_accent_color if template else None)
            or team.accent_color
        ),
        colorway_name=payload.colorway_name,
        front_logo_url=payload.front_logo_url or config.primary_logo_url,
        back_logo_url=payload.back_logo_url or config.secondary_logo_url,
        front_text=payload.front_text or config.school_name,
        back_text=payload.back_text or config.mascot,
        sleeve_text=payload.sleeve_text,
        sponsor_text=payload.sponsor_text or config.sponsor_text_default,
        notes=payload.notes,
        preview_image_url=None,
        print_layout_url=None,
        manufacturer_sheet_url=None,
        export_status=MerchExportStatus.draft,
        is_published=False,
    )
    db.add(design)
    db.flush()

    layers = payload.layers or _layer_inputs_from_template(
        template,
        config=config,
        design_name=design.design_name,
        front_text=design.front_text,
        back_text=design.back_text,
        sponsor_text=design.sponsor_text,
    )
    _apply_layers(design, layers)
    db.flush()

    design.preview_image_url = _preview_placeholder(design.id, "front")
    design.preview_state = _json_dump(_build_preview_state(design))
    db.flush()
    return _serialize_design(design)


def list_team_designs(db: Session, *, team_id: int, current_user: User) -> list[MerchDesignRead]:
    _seed_products_and_templates(db)
    team = _load_team(db, team_id)
    manager = _manager_role(team, current_user)
    membership = _approved_membership(team, current_user.id)
    linked_parent = current_user.role == UserRole.parent and _is_linked_parent(db, team_id=team.id, parent_user_id=current_user.id)
    if manager is None and membership is None and not linked_parent:
        raise HTTPException(status_code=403, detail="You are not allowed to view team merch designs")

    query = _query_designs(db).filter(MerchDesign.team_id == team_id)
    if manager is None:
        query = query.filter(MerchDesign.is_published.is_(True))
    designs = query.order_by(MerchDesign.updated_at.desc(), MerchDesign.id.desc()).all()
    return [_serialize_design(design) for design in designs]


def get_design(db: Session, *, design_id: int, current_user: User) -> MerchDesignRead:
    design = _query_designs(db).filter(MerchDesign.id == design_id).first()
    if not design:
        raise HTTPException(status_code=404, detail="Merch design not found")
    team = _load_team(db, design.team_id)
    _ensure_design_view_access(db, team, design, current_user)
    return _serialize_design(design)


def update_design(db: Session, *, design_id: int, payload: MerchDesignUpdate, current_user: User) -> MerchDesignRead:
    design = _query_designs(db).filter(MerchDesign.id == design_id).first()
    if not design:
        raise HTTPException(status_code=404, detail="Merch design not found")
    team = _load_team(db, design.team_id)
    _ensure_design_manage_access(team, current_user)

    template = design.template
    if payload.template_key is not None:
        template = db.query(MerchTemplate).filter(MerchTemplate.key == payload.template_key).first()
        if not template:
            raise HTTPException(status_code=404, detail="Merch template not found")
        design.merch_template_id = template.id
        design.template_name = template.name

    for field in [
        "design_name",
        "colorway_name",
        "primary_color",
        "secondary_color",
        "accent_color",
        "front_logo_url",
        "back_logo_url",
        "front_text",
        "back_text",
        "sleeve_text",
        "sponsor_text",
        "notes",
    ]:
        value = getattr(payload, field)
        if value is not None:
            setattr(design, field, value)

    if payload.layers is not None:
        _apply_layers(design, payload.layers)
    elif payload.template_key is not None and template is not None:
        config = design.team_config or _get_or_create_team_config(db, team, current_user)
        _apply_layers(
            design,
            _layer_inputs_from_template(
                template,
                config=config,
                design_name=design.design_name,
                front_text=design.front_text,
                back_text=design.back_text,
                sponsor_text=design.sponsor_text,
            ),
        )

    db.flush()
    design.preview_state = _json_dump(_build_preview_state(design))
    db.flush()
    return _serialize_design(design)


def publish_design(db: Session, *, design_id: int, current_user: User) -> MerchPublishResponse:
    design = _query_designs(db).filter(MerchDesign.id == design_id).first()
    if not design:
        raise HTTPException(status_code=404, detail="Merch design not found")
    team = _load_team(db, design.team_id)
    role = _ensure_design_manage_access(team, current_user)

    design.is_published = True
    design.published_at = datetime.utcnow()
    if design.preview_state is None:
        design.preview_state = _json_dump(_build_preview_state(design))
    db.flush()
    return MerchPublishResponse(design=_serialize_design(design), published_by_role=role, store_ready=True)


def export_design(db: Session, *, design_id: int, payload: MerchExportRequest, current_user: User) -> MerchDesignRead:
    design = _query_designs(db).filter(MerchDesign.id == design_id).first()
    if not design:
        raise HTTPException(status_code=404, detail="Merch design not found")
    team = _load_team(db, design.team_id)
    _ensure_design_manage_access(team, current_user)

    file_url = f"/media/merch/exports/design-{design.id}-{payload.export_type.value}.pdf"
    export = MerchExport(
        merch_design_id=design.id,
        requested_by_user_id=current_user.id,
        export_type=payload.export_type,
        status=MerchExportStatus.ready,
        file_url=file_url,
        notes=payload.notes or "Placeholder export generated for downstream print/manufacturer workflow.",
        completed_at=datetime.utcnow(),
    )
    db.add(export)

    design.export_status = MerchExportStatus.ready
    if payload.export_type == MerchExportType.preview_image:
        design.preview_image_url = f"/media/merch/exports/design-{design.id}-preview.png"
    elif payload.export_type == MerchExportType.print_layout:
        design.print_layout_url = file_url
    elif payload.export_type == MerchExportType.manufacturer_sheet:
        design.manufacturer_sheet_url = file_url

    db.flush()
    design.preview_state = _json_dump(_build_preview_state(design))
    db.flush()
    return _serialize_design(design)
