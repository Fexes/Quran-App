import 'package:flutter/material.dart';

import '../theme/quran_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: QuranTheme.text(context),
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
