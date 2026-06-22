import 'package:flutter/material.dart';

import '../models/merch_models.dart';
import '../services/merch_api_service.dart';
import '../widgets/merch_designer_ui.dart';
import 'merch_preview_screen.dart';

class TeamMerchGalleryScreen extends StatefulWidget {
  const TeamMerchGalleryScreen({
    super.key,
    required this.api,
    required this.teamId,
    required this.schoolPrimaryColor,
    required this.schoolSecondaryColor,
    required this.schoolAccentColor,
  });

  final MerchApiService api;
  final int teamId;
  final Color schoolPrimaryColor;
  final Color schoolSecondaryColor;
  final Color schoolAccentColor;

  @override
  State<TeamMerchGalleryScreen> createState() => _TeamMerchGalleryScreenState();
}

class _TeamMerchGalleryScreenState extends State<TeamMerchGalleryScreen> {
  late Future<List<MerchDesign>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchTeamDesigns(teamId: widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    return MerchShell(
      title: 'Team Merch Gallery',
      child: FutureBuilder<List<MerchDesign>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final published = snapshot.data!
              .where((design) => design.isPublished)
              .toList(growable: false);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (published.isEmpty)
                const MerchPanel(
                  child: Text(
                    'Published team merch will appear here for athletes and parents after coach approval.',
                    style: TextStyle(color: Color(0xFF8FA0B8), height: 1.45),
                  ),
                )
              else
                ...published.map(
                  (design) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MerchDesignCard(
                      design: design,
                      accentColor: widget.schoolAccentColor,
                      onTap: () {
                        Navigator.of(context).push(
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
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
