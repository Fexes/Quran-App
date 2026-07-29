import 'package:flutter/material.dart';

import '../../domain/entities/hadith_item.dart';

class HadithNarrationChainView extends StatelessWidget {
  const HadithNarrationChainView({super.key, required this.hadith});

  final HadithItem hadith;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
