import 'package:flutter/material.dart';

import '../macos_colors.dart';
import '../models/media_models.dart';

class MacosMusicAiView extends StatelessWidget {
  const MacosMusicAiView({super.key, required this.categories});

  final List<AiCategory> categories;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MacosColors.contentBackground,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Music AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Personalised blends across ${categories.length} moods. '
            'Choose a lane and let the neural curator do the rest.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 5 / 3,
              children: categories
                  .map(
                    (category) => Container(
                      decoration: BoxDecoration(
                        color: MacosColors.aiCardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: MacosColors.aiCardBorder),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${category.tracks} curated tracks',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          FilledButton.tonal(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  MacosColors.navSelectedBackground,
                              foregroundColor: MacosColors.accentBlue,
                            ),
                            child: const Text('Generate mix'),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
