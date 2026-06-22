from __future__ import annotations
from typing import Optional

from datetime import datetime
from enum import Enum

from sqlalchemy import Boolean, DateTime, Enum as SqlEnum, ForeignKey, Integer, Numeric, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base


class MerchProductType(str, Enum):
    hoodie = "hoodie"
    t_shirt = "t_shirt"
    joggers = "joggers"
    quarter_zip = "quarter_zip"
    warm_up_set = "warm_up_set"
    singlet = "singlet"
    fight_shorts = "fight_shorts"
    compression_shirt = "compression_shirt"
    fan_merch = "fan_merch"


class MerchLayerType(str, Enum):
    logo = "logo"
    mascot = "mascot"
    text = "text"
    sponsor = "sponsor"
    accent = "accent"


class MerchPlacement(str, Enum):
    front = "front"
    back = "back"
    left_sleeve = "left_sleeve"
    right_sleeve = "right_sleeve"
    left_leg = "left_leg"
    right_leg = "right_leg"
    side = "side"
    chest = "chest"
    lower_back = "lower_back"


class MerchExportStatus(str, Enum):
    draft = "draft"
    queued = "queued"
    ready = "ready"
    failed = "failed"


class MerchExportType(str, Enum):
    preview_image = "preview_image"
    print_layout = "print_layout"
    manufacturer_sheet = "manufacturer_sheet"


class MerchProduct(Base):
    __tablename__ = "merch_products"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    product_type: Mapped[MerchProductType] = mapped_column(SqlEnum(MerchProductType), nullable=False, unique=True)
    slug: Mapped[str] = mapped_column(String(80), nullable=False, unique=True, index=True)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)
    base_price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False, default=0)
    supported_views_csv: Mapped[str] = mapped_column(String(120), nullable=False, default="front,back,side")
    colorways_csv: Mapped[Optional[str]] = mapped_column(Text)
    supports_sleeve_print: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    supports_back_print: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    supports_sponsor_area: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    designs = relationship("MerchDesign", back_populates="product")


class MerchTemplate(Base):
    __tablename__ = "merch_templates"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    key: Mapped[str] = mapped_column(String(80), nullable=False, unique=True, index=True)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    style_notes: Mapped[Optional[str]] = mapped_column(Text)
    recommended_product_types_csv: Mapped[Optional[str]] = mapped_column(Text)
    default_primary_color: Mapped[Optional[str]] = mapped_column(String(7))
    default_secondary_color: Mapped[Optional[str]] = mapped_column(String(7))
    default_accent_color: Mapped[Optional[str]] = mapped_column(String(7))
    default_layer_schema: Mapped[Optional[str]] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    designs = relationship("MerchDesign", back_populates="template")


class TeamMerchConfig(Base):
    __tablename__ = "team_merch_configs"
    __table_args__ = (UniqueConstraint("team_id", name="uq_team_merch_config_team_id"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    school_name: Mapped[str] = mapped_column(String(140), nullable=False)
    mascot: Mapped[str] = mapped_column(String(120), nullable=False)
    school_colors_csv: Mapped[Optional[str]] = mapped_column(Text)
    primary_logo_url: Mapped[Optional[str]] = mapped_column(String(500))
    secondary_logo_url: Mapped[Optional[str]] = mapped_column(String(500))
    alternate_wordmark_url: Mapped[Optional[str]] = mapped_column(String(500))
    sponsor_text_default: Mapped[Optional[str]] = mapped_column(String(120))
    gallery_title: Mapped[Optional[str]] = mapped_column(String(160))
    coach_notes: Mapped[Optional[str]] = mapped_column(Text)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    updated_by_user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    team = relationship("Team")
    created_by = relationship("User", foreign_keys=[created_by_user_id])
    updated_by = relationship("User", foreign_keys=[updated_by_user_id])
    designs = relationship("MerchDesign", back_populates="team_config")


class MerchDesign(Base):
    __tablename__ = "merch_designs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    merch_product_id: Mapped[int] = mapped_column(ForeignKey("merch_products.id"), nullable=False, index=True)
    merch_template_id: Mapped[Optional[int]] = mapped_column(ForeignKey("merch_templates.id"), index=True)
    team_merch_config_id: Mapped[Optional[int]] = mapped_column(ForeignKey("team_merch_configs.id"), index=True)
    design_name: Mapped[str] = mapped_column(String(160), nullable=False)
    template_name: Mapped[Optional[str]] = mapped_column(String(120))
    primary_color: Mapped[str] = mapped_column(String(7), nullable=False)
    secondary_color: Mapped[str] = mapped_column(String(7), nullable=False)
    accent_color: Mapped[Optional[str]] = mapped_column(String(7))
    colorway_name: Mapped[Optional[str]] = mapped_column(String(80))
    front_logo_url: Mapped[Optional[str]] = mapped_column(String(500))
    back_logo_url: Mapped[Optional[str]] = mapped_column(String(500))
    front_text: Mapped[Optional[str]] = mapped_column(String(120))
    back_text: Mapped[Optional[str]] = mapped_column(String(120))
    sleeve_text: Mapped[Optional[str]] = mapped_column(String(80))
    sponsor_text: Mapped[Optional[str]] = mapped_column(String(120))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    preview_state: Mapped[Optional[str]] = mapped_column(Text)
    preview_image_url: Mapped[Optional[str]] = mapped_column(String(500))
    print_layout_url: Mapped[Optional[str]] = mapped_column(String(500))
    manufacturer_sheet_url: Mapped[Optional[str]] = mapped_column(String(500))
    export_status: Mapped[MerchExportStatus] = mapped_column(
        SqlEnum(MerchExportStatus), default=MerchExportStatus.draft, nullable=False
    )
    is_published: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    published_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    team = relationship("Team")
    created_by = relationship("User", foreign_keys=[created_by_user_id])
    product = relationship("MerchProduct", back_populates="designs")
    template = relationship("MerchTemplate", back_populates="designs")
    team_config = relationship("TeamMerchConfig", back_populates="designs")
    layers = relationship("MerchDesignLayer", back_populates="design", cascade="all, delete-orphan")
    exports = relationship("MerchExport", back_populates="design", cascade="all, delete-orphan")


class MerchDesignLayer(Base):
    __tablename__ = "merch_design_layers"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    merch_design_id: Mapped[int] = mapped_column(ForeignKey("merch_designs.id"), nullable=False, index=True)
    layer_type: Mapped[MerchLayerType] = mapped_column(SqlEnum(MerchLayerType), nullable=False)
    placement: Mapped[MerchPlacement] = mapped_column(SqlEnum(MerchPlacement), nullable=False)
    asset_url: Mapped[Optional[str]] = mapped_column(String(500))
    text_content: Mapped[Optional[str]] = mapped_column(String(160))
    text_style: Mapped[Optional[str]] = mapped_column(String(80))
    color_hex: Mapped[Optional[str]] = mapped_column(String(7))
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    visible: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    layer_metadata: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    design = relationship("MerchDesign", back_populates="layers")


class MerchExport(Base):
    __tablename__ = "merch_exports"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    merch_design_id: Mapped[int] = mapped_column(ForeignKey("merch_designs.id"), nullable=False, index=True)
    requested_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    export_type: Mapped[MerchExportType] = mapped_column(SqlEnum(MerchExportType), nullable=False)
    status: Mapped[MerchExportStatus] = mapped_column(
        SqlEnum(MerchExportStatus), default=MerchExportStatus.queued, nullable=False
    )
    file_url: Mapped[Optional[str]] = mapped_column(String(500))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    requested_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime)

    design = relationship("MerchDesign", back_populates="exports")
    requested_by = relationship("User")
