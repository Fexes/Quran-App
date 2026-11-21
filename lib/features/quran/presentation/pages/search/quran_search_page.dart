import 'package:flutter/material.dart';

import '../../../../search/presentation/pages/offline_search_page.dart';

/// Compatibility entry point for callers of the original Quran search page.
class QuranSearchPage extends StatelessWidget {
  const QuranSearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  Widget build(BuildContext context) =>
      OfflineSearchPage(initialQuery: initialQuery);
}
