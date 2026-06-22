import 'package:flutter/material.dart';

import '../models/merch_models.dart';
import '../services/merch_api_service.dart';
import '../widgets/merch_designer_ui.dart';
import 'merch_preview_screen.dart';

class MerchEditorScreen extends StatefulWidget {
  const MerchEditorScreen({
    super.key,
    required this.api,
    required this.teamId,
    required this.product,
    required this.template,
    required this.schoolPrimaryColor,
    required this.schoolSecondaryColor,
    required this.schoolAccentColor,
    this.initialDesign,
  });

  final MerchApiService api;
  final int teamId;
  final MerchProduct product;
  final MerchTemplate? template;
  final Color schoolPrimaryColor;
  final Color schoolSecondaryColor;
  final Color schoolAccentColor;
  final MerchDesign? initialDesign;

  @override
  State<MerchEditorScreen> createState() => _MerchEditorScreenState();
}

class _MerchEditorScreenState extends State<MerchEditorScreen> {
  late final TextEditingController _designNameController;
  late final TextEditingController _frontTextController;
  late final TextEditingController _backTextController;
  late final TextEditingController _sleeveTextController;
  late final TextEditingController _sponsorTextController;
  late final TextEditingController _notesController;

  late String _primaryColor;
  late String _secondaryColor;
  late String _accentColor;
  String? _selectedColorway;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDesign;
    _designNameController = TextEditingController(
      text: initial?.designName ?? '${widget.product.name} Drop',
    );
    _frontTextController = TextEditingController(
      text: initial?.frontText ?? 'WRESTLING',
    );
    _backTextController = TextEditingController(
      text: initial?.backText ?? 'STATE READY',
    );
    _sleeveTextController = TextEditingController(
      text:
          initial?.sleeveText ??
          (widget.product.supportsSleevePrint ? 'WRESTLETECH' : ''),
    );
    _sponsorTextController = TextEditingController(
      text: initial?.sponsorText ?? '',
    );
    _notesController = TextEditingController(text: initial?.notes ?? '');
    _primaryColor =
        initial?.primaryColor ??
        widget.template?.defaultPrimaryColor ??
        '#111827';
    _secondaryColor =
        initial?.secondaryColor ??
        widget.template?.defaultSecondaryColor ??
        '#E5E7EB';
    _accentColor =
        initial?.accentColor ??
        widget.template?.defaultAccentColor ??
        '#D4AF37';
    _selectedColorway =
        initial?.colorwayName ??
        (widget.product.colorways.isNotEmpty
            ? widget.product.colorways.first
            : null);
  }

  @override
  void dispose() {
    _designNameController.dispose();
    _frontTextController.dispose();
    _backTextController.dispose();
    _sleeveTextController.dispose();
    _sponsorTextController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveAndOpenPreview() async {
    setState(() => _isSaving = true);
    try {
      final design = widget.initialDesign == null
          ? await widget.api.createDesign(
              teamId: widget.teamId,
              productType: widget.product.productType,
              templateKey: widget.template?.key,
              designName: _designNameController.text.trim(),
              colorwayName: _selectedColorway,
              primaryColor: _primaryColor,
              secondaryColor: _secondaryColor,
              accentColor: _accentColor,
              frontText: _frontTextController.text.trim(),
              backText: _backTextController.text.trim(),
              sleeveText: _sleeveTextController.text.trim(),
              sponsorText: _sponsorTextController.text.trim().isEmpty
                  ? null
                  : _sponsorTextController.text.trim(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            )
          : await widget.api.updateDesign(
              designId: widget.initialDesign!.id,
              designName: _designNameController.text.trim(),
              templateKey: widget.template?.key,
              colorwayName: _selectedColorway,
              primaryColor: _primaryColor,
              secondaryColor: _secondaryColor,
              accentColor: _accentColor,
              frontText: _frontTextController.text.trim(),
              backText: _backTextController.text.trim(),
              sleeveText: _sleeveTextController.text.trim(),
              sponsorText: _sponsorTextController.text.trim().isEmpty
                  ? null
                  : _sponsorTextController.text.trim(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );
      if (!mounted) return;
      final refreshed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => MerchPreviewScreen(
            api: widget.api,
            design: design,
            schoolAccentColor: widget.schoolAccentColor,
            schoolPrimaryColor: widget.schoolPrimaryColor,
            schoolSecondaryColor: widget.schoolSecondaryColor,
          ),
        ),
      );
      if (refreshed == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewView = widget.initialDesign?.previewViews.isNotEmpty == true
        ? widget.initialDesign!.previewViews.first
        : MerchPreviewView(
            view: 'front',
            baseColor: _primaryColor,
            layers: [
              {
                'placement': 'front',
                'visible': true,
                'text_content': _frontTextController.text,
                'layer_type': 'text',
                'color_hex': _accentColor,
              },
            ],
          );

    return MerchShell(
      title: 'Merch Editor',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          MerchPreviewCard(
            title: 'Live Preview',
            view: previewView,
            primaryColor: colorFromHex(
              _primaryColor,
              fallback: widget.schoolPrimaryColor,
            ),
            secondaryColor: colorFromHex(
              _secondaryColor,
              fallback: widget.schoolSecondaryColor,
            ),
            accentColor: colorFromHex(
              _accentColor,
              fallback: widget.schoolAccentColor,
            ),
          ),
          const SizedBox(height: 20),
          MerchPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MerchSectionTitle('Design Controls'),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Design Name',
                  child: _textField(_designNameController),
                ),
                _LabeledField(
                  label: 'Front Text',
                  child: _textField(_frontTextController),
                ),
                _LabeledField(
                  label: 'Back Text',
                  child: _textField(_backTextController),
                ),
                if (widget.product.supportsSleevePrint)
                  _LabeledField(
                    label: 'Sleeve Text',
                    child: _textField(_sleeveTextController),
                  ),
                if (widget.product.supportsSponsorArea)
                  _LabeledField(
                    label: 'Sponsor Area',
                    child: _textField(_sponsorTextController),
                  ),
                _LabeledField(
                  label: 'Colorway',
                  child: DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF121821),
                    value: _selectedColorway,
                    items: widget.product.colorways
                        .map(
                          (colorway) => DropdownMenuItem(
                            value: colorway,
                            child: Text(colorway.replaceAll('_', ' ')),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) =>
                        setState(() => _selectedColorway = value),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(),
                  ),
                ),
                _ColorField(
                  label: 'Primary Color',
                  value: _primaryColor,
                  onChanged: (value) => setState(() => _primaryColor = value),
                ),
                _ColorField(
                  label: 'Secondary Color',
                  value: _secondaryColor,
                  onChanged: (value) => setState(() => _secondaryColor = value),
                ),
                _ColorField(
                  label: 'Accent Color',
                  value: _accentColor,
                  onChanged: (value) => setState(() => _accentColor = value),
                ),
                _LabeledField(
                  label: 'Coach Notes',
                  child: _textField(_notesController, maxLines: 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: widget.schoolAccentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isSaving ? null : _saveAndOpenPreview,
            child: Text(_isSaving ? 'Saving...' : 'Save And Review'),
          ),
        ],
      ),
    );
  }

  Widget _textField(TextEditingController controller, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(),
      onChanged: (_) => setState(() {}),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF0E141D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ColorField extends StatelessWidget {
  const _ColorField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorFromHex(value),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: value,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0E141D),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
