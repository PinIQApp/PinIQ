import 'package:flutter/material.dart';

import '../models/merch_models.dart';
import '../services/merch_api_service.dart';
import '../widgets/merch_designer_ui.dart';
import 'merch_editor_screen.dart';
import 'merch_preview_screen.dart';
import 'product_picker_screen.dart';
import 'team_merch_gallery_screen.dart';

class MerchDesignerHomeScreen extends StatefulWidget {
  const MerchDesignerHomeScreen({
    super.key,
    required this.api,
    required this.teamId,
    required this.currentUserId,
    required this.schoolPrimaryColor,
    required this.schoolSecondaryColor,
    required this.schoolAccentColor,
  });

  final MerchApiService api;
  final int teamId;
  final int currentUserId;
  final Color schoolPrimaryColor;
  final Color schoolSecondaryColor;
  final Color schoolAccentColor;

  @override
  State<MerchDesignerHomeScreen> createState() =>
      _MerchDesignerHomeScreenState();
}

class _MerchDesignerHomeScreenState extends State<MerchDesignerHomeScreen> {
  late Future<_MerchHomeBundle> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _load();
  }

  Future<_MerchHomeBundle> _load() async {
    final results = await Future.wait([
      widget.api.fetchProducts(),
      widget.api.fetchTemplates(),
      widget.api.fetchTeamDesigns(teamId: widget.teamId),
    ]);
    return _MerchHomeBundle(
      products: results[0] as List<MerchProduct>,
      templates: results[1] as List<MerchTemplate>,
      designs: results[2] as List<MerchDesign>,
    );
  }

  Future<void> _startNewDesign(_MerchHomeBundle bundle) async {
    final selection = await Navigator.of(context).push<ProductPickerResult>(
      MaterialPageRoute(
        builder: (_) => ProductPickerScreen(
          products: bundle.products,
          templates: bundle.templates,
          schoolAccentColor: widget.schoolAccentColor,
        ),
      ),
    );
    if (selection == null || !mounted) return;

    final refreshed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MerchEditorScreen(
          api: widget.api,
          teamId: widget.teamId,
          product: selection.product,
          template: selection.template,
          schoolPrimaryColor: widget.schoolPrimaryColor,
          schoolSecondaryColor: widget.schoolSecondaryColor,
          schoolAccentColor: widget.schoolAccentColor,
        ),
      ),
    );
    if (refreshed == true && mounted) {
      setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MerchShell(
      title: 'Merch Designer',
      child: RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await _future;
        },
        child: FutureBuilder<_MerchHomeBundle>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
              );
            }

            final bundle = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.schoolPrimaryColor.withOpacity(0.85),
                        widget.schoolAccentColor.withOpacity(0.28),
                        const Color(0xFF0C121A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WrestleTech Merch Builder',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Build school-ready apparel with templates, live preview structure, and coach-controlled publishing.',
                        style: TextStyle(
                          color: Color(0xFFD8E2F0),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: widget.schoolAccentColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 18,
                          ),
                        ),
                        onPressed: () => _startNewDesign(bundle),
                        child: const Text('Create New Design'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                MerchSectionTitle(
                  'Saved Designs',
                  action: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TeamMerchGalleryScreen(
                            api: widget.api,
                            teamId: widget.teamId,
                            schoolAccentColor: widget.schoolAccentColor,
                            schoolPrimaryColor: widget.schoolPrimaryColor,
                            schoolSecondaryColor: widget.schoolSecondaryColor,
                          ),
                        ),
                      );
                    },
                    child: const Text('Gallery'),
                  ),
                ),
                const SizedBox(height: 12),
                if (bundle.designs.isEmpty)
                  const MerchPanel(
                    child: Text(
                      'No merch designs yet. Start with a product and template to build your first team drop.',
                      style: TextStyle(color: Color(0xFF8FA0B8), height: 1.45),
                    ),
                  )
                else
                  ...bundle.designs.map(
                    (design) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MerchDesignCard(
                        design: design,
                        accentColor: widget.schoolAccentColor,
                        onTap: () async {
                          final refreshed = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => MerchPreviewScreen(
                                    api: widget.api,
                                    design: design,
                                    schoolAccentColor: widget.schoolAccentColor,
                                    schoolPrimaryColor:
                                        widget.schoolPrimaryColor,
                                    schoolSecondaryColor:
                                        widget.schoolSecondaryColor,
                                  ),
                                ),
                              );
                          if (refreshed == true && mounted) {
                            setState(_reload);
                          }
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 22),
                const MerchSectionTitle('Templates'),
                const SizedBox(height: 12),
                ...bundle.templates
                    .take(5)
                    .map(
                      (template) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MerchTemplateCard(
                          template: template,
                          accentColor: widget.schoolAccentColor,
                          selected: false,
                          onTap: () => _startNewDesign(bundle),
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MerchHomeBundle {
  const _MerchHomeBundle({
    required this.products,
    required this.templates,
    required this.designs,
  });

  final List<MerchProduct> products;
  final List<MerchTemplate> templates;
  final List<MerchDesign> designs;
}
