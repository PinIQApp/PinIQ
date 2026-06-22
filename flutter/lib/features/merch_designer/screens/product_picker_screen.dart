import 'package:flutter/material.dart';

import '../models/merch_models.dart';
import '../widgets/merch_designer_ui.dart';

class ProductPickerResult {
  const ProductPickerResult({required this.product, required this.template});

  final MerchProduct product;
  final MerchTemplate? template;
}

class ProductPickerScreen extends StatefulWidget {
  const ProductPickerScreen({
    super.key,
    required this.products,
    required this.templates,
    required this.schoolAccentColor,
  });

  final List<MerchProduct> products;
  final List<MerchTemplate> templates;
  final Color schoolAccentColor;

  @override
  State<ProductPickerScreen> createState() => _ProductPickerScreenState();
}

class _ProductPickerScreenState extends State<ProductPickerScreen> {
  MerchProduct? _selectedProduct;
  MerchTemplate? _selectedTemplate;

  @override
  Widget build(BuildContext context) {
    return MerchShell(
      title: 'Pick Product',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const MerchSectionTitle('Choose A Product'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final product = widget.products[index];
              return MerchProductCard(
                product: product,
                accentColor: widget.schoolAccentColor,
                onTap: () => setState(() => _selectedProduct = product),
              );
            },
          ),
          const SizedBox(height: 24),
          const MerchSectionTitle('Choose A Template'),
          const SizedBox(height: 12),
          ...widget.templates.map(
            (template) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MerchTemplateCard(
                template: template,
                accentColor: widget.schoolAccentColor,
                selected: _selectedTemplate?.id == template.id,
                onTap: () => setState(() => _selectedTemplate = template),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: widget.schoolAccentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _selectedProduct == null
                ? null
                : () {
                    Navigator.of(context).pop(
                      ProductPickerResult(
                        product: _selectedProduct!,
                        template: _selectedTemplate,
                      ),
                    );
                  },
            child: const Text('Continue To Designer'),
          ),
        ],
      ),
    );
  }
}
