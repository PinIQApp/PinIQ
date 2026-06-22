import 'package:flutter/material.dart';

import '../models/merch_models.dart';
import '../services/merch_api_service.dart';
import '../widgets/merch_designer_ui.dart';

class MerchPreviewScreen extends StatefulWidget {
  const MerchPreviewScreen({
    super.key,
    required this.api,
    required this.design,
    required this.schoolPrimaryColor,
    required this.schoolSecondaryColor,
    required this.schoolAccentColor,
  });

  final MerchApiService api;
  final MerchDesign design;
  final Color schoolPrimaryColor;
  final Color schoolSecondaryColor;
  final Color schoolAccentColor;

  @override
  State<MerchPreviewScreen> createState() => _MerchPreviewScreenState();
}

class _MerchPreviewScreenState extends State<MerchPreviewScreen> {
  late MerchDesign _design;
  bool _isPublishing = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _design = widget.design;
  }

  Future<void> _publish() async {
    setState(() => _isPublishing = true);
    try {
      final result = await widget.api.publishDesign(designId: _design.id);
      if (!mounted) return;
      setState(() => _design = result.design);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Published by ${result.publishedByRole.replaceAll('_', ' ')}',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Future<void> _export(String exportType) async {
    setState(() => _isExporting = true);
    try {
      final design = await widget.api.exportDesign(
        designId: _design.id,
        exportType: exportType,
        notes: 'Requested from preview screen',
      );
      if (!mounted) return;
      setState(() => _design = design);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${exportType.replaceAll('_', ' ')} ready placeholder created',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewViews = _design.previewViews;
    return MerchShell(
      title: 'Preview Design',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...previewViews.map(
            (view) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: MerchPreviewCard(
                title:
                    '${view.view[0].toUpperCase()}${view.view.substring(1)} View',
                view: view,
                primaryColor: colorFromHex(
                  _design.primaryColor,
                  fallback: widget.schoolPrimaryColor,
                ),
                secondaryColor: colorFromHex(
                  _design.secondaryColor,
                  fallback: widget.schoolSecondaryColor,
                ),
                accentColor: colorFromHex(
                  _design.accentColor,
                  fallback: widget.schoolAccentColor,
                ),
              ),
            ),
          ),
          MerchPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MerchSectionTitle('Export Ready Setup'),
                const SizedBox(height: 12),
                Text(
                  'Preview image, print layout, and manufacturer sheet are scaffolded as placeholders so we can swap in a real render/export pipeline later without changing the screen flow.',
                  style: const TextStyle(
                    color: Color(0xFF8FA0B8),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton(
                      onPressed: _isExporting
                          ? null
                          : () => _export('preview_image'),
                      child: const Text('Preview Image'),
                    ),
                    OutlinedButton(
                      onPressed: _isExporting
                          ? null
                          : () => _export('print_layout'),
                      child: const Text('Print Layout'),
                    ),
                    OutlinedButton(
                      onPressed: _isExporting
                          ? null
                          : () => _export('manufacturer_sheet'),
                      child: const Text('Manufacturer Sheet'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: widget.schoolAccentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isPublishing ? null : _publish,
            child: Text(
              _isPublishing
                  ? 'Publishing...'
                  : (_design.isPublished ? 'Published' : 'Publish Design'),
            ),
          ),
        ],
      ),
    );
  }
}
