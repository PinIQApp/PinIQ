import 'dart:convert';

List<dynamic> decodeMerchList(String body) => jsonDecode(body) as List<dynamic>;
Map<String, dynamic> decodeMerchObject(String body) =>
    jsonDecode(body) as Map<String, dynamic>;

class MerchProduct {
  const MerchProduct({
    required this.id,
    required this.productType,
    required this.slug,
    required this.name,
    this.description,
    required this.basePrice,
    required this.supportedViews,
    required this.colorways,
    required this.supportsSleevePrint,
    required this.supportsBackPrint,
    required this.supportsSponsorArea,
    required this.isActive,
  });

  final int id;
  final String productType;
  final String slug;
  final String name;
  final String? description;
  final double basePrice;
  final List<String> supportedViews;
  final List<String> colorways;
  final bool supportsSleevePrint;
  final bool supportsBackPrint;
  final bool supportsSponsorArea;
  final bool isActive;

  factory MerchProduct.fromMap(Map<String, dynamic> map) {
    return MerchProduct(
      id: map['id'] as int,
      productType: map['product_type'] as String,
      slug: map['slug'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      basePrice: (map['base_price'] as num).toDouble(),
      supportedViews: (map['supported_views'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      colorways: (map['colorways'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      supportsSleevePrint: map['supports_sleeve_print'] as bool? ?? false,
      supportsBackPrint: map['supports_back_print'] as bool? ?? false,
      supportsSponsorArea: map['supports_sponsor_area'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}

class MerchTemplate {
  const MerchTemplate({
    required this.id,
    required this.key,
    required this.name,
    required this.description,
    this.styleNotes,
    required this.recommendedProductTypes,
    this.defaultPrimaryColor,
    this.defaultSecondaryColor,
    this.defaultAccentColor,
    required this.defaultLayerSchema,
    required this.isActive,
  });

  final int id;
  final String key;
  final String name;
  final String description;
  final String? styleNotes;
  final List<String> recommendedProductTypes;
  final String? defaultPrimaryColor;
  final String? defaultSecondaryColor;
  final String? defaultAccentColor;
  final List<Map<String, dynamic>> defaultLayerSchema;
  final bool isActive;

  factory MerchTemplate.fromMap(Map<String, dynamic> map) {
    return MerchTemplate(
      id: map['id'] as int,
      key: map['key'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      styleNotes: map['style_notes'] as String?,
      recommendedProductTypes:
          (map['recommended_product_types'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(growable: false),
      defaultPrimaryColor: map['default_primary_color'] as String?,
      defaultSecondaryColor: map['default_secondary_color'] as String?,
      defaultAccentColor: map['default_accent_color'] as String?,
      defaultLayerSchema:
          (map['default_layer_schema'] as List<dynamic>? ?? const [])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList(growable: false),
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}

class MerchLayer {
  const MerchLayer({
    required this.id,
    required this.merchDesignId,
    required this.layerType,
    required this.placement,
    this.assetUrl,
    this.textContent,
    this.textStyle,
    this.colorHex,
    required this.sortOrder,
    required this.visible,
    required this.layerMetadata,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int merchDesignId;
  final String layerType;
  final String placement;
  final String? assetUrl;
  final String? textContent;
  final String? textStyle;
  final String? colorHex;
  final int sortOrder;
  final bool visible;
  final Map<String, dynamic> layerMetadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MerchLayer.fromMap(Map<String, dynamic> map) {
    return MerchLayer(
      id: map['id'] as int,
      merchDesignId: map['merch_design_id'] as int,
      layerType: map['layer_type'] as String,
      placement: map['placement'] as String,
      assetUrl: map['asset_url'] as String?,
      textContent: map['text_content'] as String?,
      textStyle: map['text_style'] as String?,
      colorHex: map['color_hex'] as String?,
      sortOrder: (map['sort_order'] as num).toInt(),
      visible: map['visible'] as bool? ?? true,
      layerMetadata: Map<String, dynamic>.from(
        map['layer_metadata'] as Map? ?? const {},
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class MerchExport {
  const MerchExport({
    required this.id,
    required this.merchDesignId,
    required this.requestedByUserId,
    required this.exportType,
    required this.status,
    this.fileUrl,
    this.notes,
    required this.requestedAt,
    this.completedAt,
  });

  final int id;
  final int merchDesignId;
  final int requestedByUserId;
  final String exportType;
  final String status;
  final String? fileUrl;
  final String? notes;
  final DateTime requestedAt;
  final DateTime? completedAt;

  factory MerchExport.fromMap(Map<String, dynamic> map) {
    return MerchExport(
      id: map['id'] as int,
      merchDesignId: map['merch_design_id'] as int,
      requestedByUserId: map['requested_by_user_id'] as int,
      exportType: map['export_type'] as String,
      status: map['status'] as String,
      fileUrl: map['file_url'] as String?,
      notes: map['notes'] as String?,
      requestedAt: DateTime.parse(map['requested_at'] as String),
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.parse(map['completed_at'] as String),
    );
  }
}

class TeamMerchConfig {
  const TeamMerchConfig({
    required this.id,
    required this.teamId,
    required this.schoolName,
    required this.mascot,
    required this.schoolColors,
    this.primaryLogoUrl,
    this.secondaryLogoUrl,
    this.alternateWordmarkUrl,
    this.sponsorTextDefault,
    this.galleryTitle,
    this.coachNotes,
  });

  final int id;
  final int teamId;
  final String schoolName;
  final String mascot;
  final List<String> schoolColors;
  final String? primaryLogoUrl;
  final String? secondaryLogoUrl;
  final String? alternateWordmarkUrl;
  final String? sponsorTextDefault;
  final String? galleryTitle;
  final String? coachNotes;

  factory TeamMerchConfig.fromMap(Map<String, dynamic> map) {
    return TeamMerchConfig(
      id: map['id'] as int,
      teamId: map['team_id'] as int,
      schoolName: map['school_name'] as String,
      mascot: map['mascot'] as String,
      schoolColors: (map['school_colors'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      primaryLogoUrl: map['primary_logo_url'] as String?,
      secondaryLogoUrl: map['secondary_logo_url'] as String?,
      alternateWordmarkUrl: map['alternate_wordmark_url'] as String?,
      sponsorTextDefault: map['sponsor_text_default'] as String?,
      galleryTitle: map['gallery_title'] as String?,
      coachNotes: map['coach_notes'] as String?,
    );
  }
}

class MerchPreviewView {
  const MerchPreviewView({
    required this.view,
    required this.baseColor,
    this.placeholderImageUrl,
    required this.layers,
  });

  final String view;
  final String baseColor;
  final String? placeholderImageUrl;
  final List<Map<String, dynamic>> layers;

  factory MerchPreviewView.fromMap(Map<String, dynamic> map) {
    return MerchPreviewView(
      view: map['view'] as String,
      baseColor: map['base_color'] as String? ?? '#111827',
      placeholderImageUrl: map['placeholder_image_url'] as String?,
      layers: (map['layers'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false),
    );
  }
}

class MerchDesign {
  const MerchDesign({
    required this.id,
    required this.teamId,
    required this.createdByUserId,
    required this.merchProductId,
    this.merchTemplateId,
    this.teamMerchConfigId,
    required this.designName,
    this.templateName,
    required this.primaryColor,
    required this.secondaryColor,
    this.accentColor,
    this.colorwayName,
    this.frontLogoUrl,
    this.backLogoUrl,
    this.frontText,
    this.backText,
    this.sleeveText,
    this.sponsorText,
    this.notes,
    required this.previewState,
    this.previewImageUrl,
    this.printLayoutUrl,
    this.manufacturerSheetUrl,
    required this.exportStatus,
    required this.isPublished,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
    this.template,
    this.teamConfig,
    required this.layers,
    required this.exports,
  });

  final int id;
  final int teamId;
  final int createdByUserId;
  final int merchProductId;
  final int? merchTemplateId;
  final int? teamMerchConfigId;
  final String designName;
  final String? templateName;
  final String primaryColor;
  final String secondaryColor;
  final String? accentColor;
  final String? colorwayName;
  final String? frontLogoUrl;
  final String? backLogoUrl;
  final String? frontText;
  final String? backText;
  final String? sleeveText;
  final String? sponsorText;
  final String? notes;
  final Map<String, dynamic> previewState;
  final String? previewImageUrl;
  final String? printLayoutUrl;
  final String? manufacturerSheetUrl;
  final String exportStatus;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MerchProduct product;
  final MerchTemplate? template;
  final TeamMerchConfig? teamConfig;
  final List<MerchLayer> layers;
  final List<MerchExport> exports;

  List<MerchPreviewView> get previewViews {
    final items = previewState['views'] as List<dynamic>? ?? const [];
    return items
        .map((item) => MerchPreviewView.fromMap(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  factory MerchDesign.fromMap(Map<String, dynamic> map) {
    return MerchDesign(
      id: map['id'] as int,
      teamId: map['team_id'] as int,
      createdByUserId: map['created_by_user_id'] as int,
      merchProductId: map['merch_product_id'] as int,
      merchTemplateId: map['merch_template_id'] as int?,
      teamMerchConfigId: map['team_merch_config_id'] as int?,
      designName: map['design_name'] as String,
      templateName: map['template_name'] as String?,
      primaryColor: map['primary_color'] as String,
      secondaryColor: map['secondary_color'] as String,
      accentColor: map['accent_color'] as String?,
      colorwayName: map['colorway_name'] as String?,
      frontLogoUrl: map['front_logo_url'] as String?,
      backLogoUrl: map['back_logo_url'] as String?,
      frontText: map['front_text'] as String?,
      backText: map['back_text'] as String?,
      sleeveText: map['sleeve_text'] as String?,
      sponsorText: map['sponsor_text'] as String?,
      notes: map['notes'] as String?,
      previewState: Map<String, dynamic>.from(
        map['preview_state'] as Map? ?? const {},
      ),
      previewImageUrl: map['preview_image_url'] as String?,
      printLayoutUrl: map['print_layout_url'] as String?,
      manufacturerSheetUrl: map['manufacturer_sheet_url'] as String?,
      exportStatus: map['export_status'] as String,
      isPublished: map['is_published'] as bool? ?? false,
      publishedAt: map['published_at'] == null
          ? null
          : DateTime.parse(map['published_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      product: MerchProduct.fromMap(map['product'] as Map<String, dynamic>),
      template: map['template'] == null
          ? null
          : MerchTemplate.fromMap(map['template'] as Map<String, dynamic>),
      teamConfig: map['team_config'] == null
          ? null
          : TeamMerchConfig.fromMap(map['team_config'] as Map<String, dynamic>),
      layers: (map['layers'] as List<dynamic>? ?? const [])
          .map((item) => MerchLayer.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      exports: (map['exports'] as List<dynamic>? ?? const [])
          .map((item) => MerchExport.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class MerchPublishResult {
  const MerchPublishResult({
    required this.design,
    required this.publishedByRole,
    required this.storeReady,
  });

  final MerchDesign design;
  final String publishedByRole;
  final bool storeReady;

  factory MerchPublishResult.fromMap(Map<String, dynamic> map) {
    return MerchPublishResult(
      design: MerchDesign.fromMap(map['design'] as Map<String, dynamic>),
      publishedByRole: map['published_by_role'] as String,
      storeReady: map['store_ready'] as bool? ?? false,
    );
  }
}
