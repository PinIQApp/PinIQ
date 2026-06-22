from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.merch import MerchExportStatus, MerchExportType, MerchLayerType, MerchPlacement, MerchProductType


class MerchProductRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    product_type: MerchProductType
    slug: str
    name: str
    description: str | None
    base_price: float
    supported_views: list[str]
    colorways: list[str]
    supports_sleeve_print: bool
    supports_back_print: bool
    supports_sponsor_area: bool
    is_active: bool


class MerchDesignLayerInput(BaseModel):
    layer_type: MerchLayerType
    placement: MerchPlacement
    asset_url: str | None = Field(default=None, max_length=500)
    text_content: str | None = Field(default=None, max_length=160)
    text_style: str | None = Field(default=None, max_length=80)
    color_hex: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")
    sort_order: int = Field(default=0, ge=0, le=100)
    visible: bool = True
    layer_metadata: dict[str, str | int | float | bool | None] = Field(default_factory=dict)


class MerchDesignLayerRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    merch_design_id: int
    layer_type: MerchLayerType
    placement: MerchPlacement
    asset_url: str | None
    text_content: str | None
    text_style: str | None
    color_hex: str | None
    sort_order: int
    visible: bool
    layer_metadata: dict[str, str | int | float | bool | None]
    created_at: datetime
    updated_at: datetime


class MerchTemplateRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    key: str
    name: str
    description: str
    style_notes: str | None
    recommended_product_types: list[MerchProductType]
    default_primary_color: str | None
    default_secondary_color: str | None
    default_accent_color: str | None
    default_layer_schema: list[dict[str, object]]
    is_active: bool


class TeamMerchConfigRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    team_id: int
    school_name: str
    mascot: str
    school_colors: list[str]
    primary_logo_url: str | None
    secondary_logo_url: str | None
    alternate_wordmark_url: str | None
    sponsor_text_default: str | None
    gallery_title: str | None
    coach_notes: str | None
    created_by_user_id: int
    updated_by_user_id: int | None
    created_at: datetime
    updated_at: datetime


class MerchDesignCreate(BaseModel):
    team_id: int
    product_type: MerchProductType
    template_key: str | None = Field(default=None, max_length=80)
    design_name: str = Field(min_length=2, max_length=160)
    colorway_name: str | None = Field(default=None, max_length=80)
    primary_color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")
    secondary_color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")
    accent_color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")
    front_logo_url: str | None = Field(default=None, max_length=500)
    back_logo_url: str | None = Field(default=None, max_length=500)
    front_text: str | None = Field(default=None, max_length=120)
    back_text: str | None = Field(default=None, max_length=120)
    sleeve_text: str | None = Field(default=None, max_length=80)
    sponsor_text: str | None = Field(default=None, max_length=120)
    notes: str | None = Field(default=None, max_length=4000)
    layers: list[MerchDesignLayerInput] = Field(default_factory=list)


class MerchDesignUpdate(BaseModel):
    design_name: str | None = Field(default=None, min_length=2, max_length=160)
    template_key: str | None = Field(default=None, max_length=80)
    colorway_name: str | None = Field(default=None, max_length=80)
    primary_color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")
    secondary_color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")
    accent_color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")
    front_logo_url: str | None = Field(default=None, max_length=500)
    back_logo_url: str | None = Field(default=None, max_length=500)
    front_text: str | None = Field(default=None, max_length=120)
    back_text: str | None = Field(default=None, max_length=120)
    sleeve_text: str | None = Field(default=None, max_length=80)
    sponsor_text: str | None = Field(default=None, max_length=120)
    notes: str | None = Field(default=None, max_length=4000)
    layers: list[MerchDesignLayerInput] | None = None


class MerchExportRequest(BaseModel):
    export_type: MerchExportType = MerchExportType.preview_image
    notes: str | None = Field(default=None, max_length=2000)


class MerchExportRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    merch_design_id: int
    requested_by_user_id: int
    export_type: MerchExportType
    status: MerchExportStatus
    file_url: str | None
    notes: str | None
    requested_at: datetime
    completed_at: datetime | None


class MerchDesignRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    team_id: int
    created_by_user_id: int
    merch_product_id: int
    merch_template_id: int | None
    team_merch_config_id: int | None
    design_name: str
    template_name: str | None
    primary_color: str
    secondary_color: str
    accent_color: str | None
    colorway_name: str | None
    front_logo_url: str | None
    back_logo_url: str | None
    front_text: str | None
    back_text: str | None
    sleeve_text: str | None
    sponsor_text: str | None
    notes: str | None
    preview_state: dict[str, object]
    preview_image_url: str | None
    print_layout_url: str | None
    manufacturer_sheet_url: str | None
    export_status: MerchExportStatus
    is_published: bool
    published_at: datetime | None
    created_at: datetime
    updated_at: datetime
    product: MerchProductRead
    template: MerchTemplateRead | None = None
    team_config: TeamMerchConfigRead | None = None
    layers: list[MerchDesignLayerRead] = []
    exports: list[MerchExportRead] = []


class MerchPublishResponse(BaseModel):
    design: MerchDesignRead
    published_by_role: str
    store_ready: bool

