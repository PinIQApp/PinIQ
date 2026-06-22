import 'package:flutter/material.dart';

import '../models/merch_models.dart';

class MerchShell extends StatelessWidget {
  const MerchShell({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(title),
      ),
      body: child,
    );
  }
}

class MerchPanel extends StatelessWidget {
  const MerchPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF121821),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}

class MerchSectionTitle extends StatelessWidget {
  const MerchSectionTitle(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class MerchProductCard extends StatelessWidget {
  const MerchProductCard({
    super.key,
    required this.product,
    required this.accentColor,
    required this.onTap,
  });

  final MerchProduct product;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF131A24),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.28),
                    const Color(0xFF0D121A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  product.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              product.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.description ?? product.productType,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF8FA0B8), height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              '\$${product.basePrice.toStringAsFixed(0)} base',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class MerchTemplateCard extends StatelessWidget {
  const MerchTemplateCard({
    super.key,
    required this.template,
    required this.accentColor,
    required this.selected,
    required this.onTap,
  });

  final MerchTemplate template;
  final Color accentColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withOpacity(0.16)
              : const Color(0xFF131A24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? accentColor : Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              template.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF8FA0B8), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class MerchDesignCard extends StatelessWidget {
  const MerchDesignCard({
    super.key,
    required this.design,
    required this.accentColor,
    required this.onTap,
  });

  final MerchDesign design;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121821),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    design.designName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${design.product.name}  •  ${design.templateName ?? 'Custom build'}',
                    style: const TextStyle(color: Color(0xFF8FA0B8)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusPill(
                        label: design.isPublished ? 'Published' : 'Draft',
                        color: accentColor,
                      ),
                      _ColorSwatch(hex: design.primaryColor),
                      _ColorSwatch(hex: design.secondaryColor),
                      if (design.accentColor != null)
                        _ColorSwatch(hex: design.accentColor!),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class MerchPreviewCard extends StatelessWidget {
  const MerchPreviewCard({
    super.key,
    required this.title,
    required this.view,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });

  final String title;
  final MerchPreviewView view;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final base = colorFromHex(view.baseColor, fallback: primaryColor);
    return MerchPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 220,
              height: 240,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white12),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            secondaryColor.withOpacity(0.18),
                            Colors.transparent,
                            accentColor.withOpacity(0.12),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                  ...view.layers
                      .where((item) => item['visible'] != false)
                      .map(
                        (layer) => _PreviewLayer(
                          layer: layer,
                          accentColor: accentColor,
                        ),
                      ),
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewLayer extends StatelessWidget {
  const _PreviewLayer({required this.layer, required this.accentColor});

  final Map<String, dynamic> layer;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final placement = layer['placement']?.toString() ?? 'front';
    final content =
        layer['text_content']?.toString() ??
        layer['layer_type']?.toString().toUpperCase() ??
        '';
    final color = colorFromHex(
      layer['color_hex']?.toString(),
      fallback: accentColor,
    );

    final alignment = switch (placement) {
      'back' => Alignment.center,
      'lower_back' => Alignment.bottomCenter,
      'left_sleeve' => Alignment.centerLeft,
      'right_sleeve' => Alignment.centerRight,
      'side' => Alignment.centerRight,
      'chest' => Alignment.topCenter,
      _ => Alignment.center,
    };

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.7)),
        ),
        child: Text(
          content.isEmpty
              ? (layer['layer_type']?.toString().toUpperCase() ?? '')
              : content,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 12)],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.hex});

  final String hex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: colorFromHex(hex),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
    );
  }
}

Color colorFromHex(String? hex, {Color fallback = const Color(0xFFE63946)}) {
  if (hex == null || hex.isEmpty) {
    return fallback;
  }
  final normalized = hex.replaceFirst('#', '');
  if (normalized.length != 6) {
    return fallback;
  }
  return Color(int.parse('FF$normalized', radix: 16));
}
