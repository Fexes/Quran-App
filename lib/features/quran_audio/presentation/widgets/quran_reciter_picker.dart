import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../quran/domain/entities/quran_audio_reciter.dart';

Future<QuranAudioReciter?> showQuranReciterPickerSheet(
  BuildContext context, {
  required List<QuranAudioReciter> reciters,
  required String? selectedReciterId,
  String title = 'Choose reciter',
}) {
  return showModalBottomSheet<QuranAudioReciter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (_) => QuranReciterPickerSheet(
      reciters: reciters,
      selectedReciterId: selectedReciterId,
      title: title,
    ),
  );
}

class QuranReciterPickerSheet extends StatefulWidget {
  const QuranReciterPickerSheet({
    super.key,
    required this.reciters,
    required this.selectedReciterId,
    this.title = 'Choose reciter',
  });

  final List<QuranAudioReciter> reciters;
  final String? selectedReciterId;
  final String title;

  @override
  State<QuranReciterPickerSheet> createState() =>
      _QuranReciterPickerSheetState();
}

class _QuranReciterPickerSheetState extends State<QuranReciterPickerSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final reciters = widget.reciters
        .where((reciter) => _matchesQuery(reciter, query))
        .toList(growable: false);
    final primary = Theme.of(context).colorScheme.primary;
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.86,
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              10,
              18,
              18 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: QuranTheme.outline(context),
                    borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: QuranTheme.softFill(context, primary),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.record_voice_over_rounded,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '${widget.reciters.length} reciters available',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: QuranTheme.subText(context)),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search reciters',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            onPressed: () {
                              _controller.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: QuranTheme.softFill(context, primary),
                    border: _searchBorder(context),
                    enabledBorder: _searchBorder(context),
                    focusedBorder: _searchBorder(context, primary),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: reciters.isEmpty
                      ? Center(
                          child: Text(
                            'No reciters found',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: QuranTheme.subText(context)),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: reciters.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final reciter = reciters[index];
                            return QuranReciterPickerTile(
                              reciter: reciter,
                              selected: reciter.id == widget.selectedReciterId,
                              onTap: () => Navigator.of(context).pop(reciter),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _searchBorder(BuildContext context, [Color? color]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
      borderSide: BorderSide(color: color ?? QuranTheme.outline(context)),
    );
  }

  bool _matchesQuery(QuranAudioReciter reciter, String query) {
    if (query.isEmpty) {
      return true;
    }
    final fields = [
      reciter.name,
      reciter.arabicName ?? '',
      reciter.qualityLabel ?? '',
      reciter.provider.name,
    ].join(' ').toLowerCase();
    return fields.contains(query);
  }
}

class QuranReciterPickerTile extends StatelessWidget {
  const QuranReciterPickerTile({
    super.key,
    required this.reciter,
    required this.selected,
    required this.onTap,
  });

  final QuranAudioReciter reciter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected
          ? QuranTheme.softFill(context, primary)
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.34)
                  : QuranTheme.outline(context),
            ),
            boxShadow: [
              if (!selected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
            ],
          ),
          child: Row(
            children: [
              QuranReciterAvatar(
                reciter: reciter,
                size: 56,
                selected: selected,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reciter.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (reciter.arabicName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        reciter.arabicName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: QuranTheme.subText(context),
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        QuranReciterMetaChip(
                          icon: Icons.graphic_eq_rounded,
                          label: reciter.qualityLabel ?? 'Audio',
                        ),
                        QuranReciterMetaChip(
                          icon: Icons.cloud_download_rounded,
                          label: quranAudioProviderLabel(reciter.provider),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected ? primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? primary : QuranTheme.outline(context),
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      )
                    : Icon(
                        Icons.chevron_right_rounded,
                        color: QuranTheme.subText(context),
                        size: 22,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuranReciterAvatar extends StatelessWidget {
  const QuranReciterAvatar({
    super.key,
    this.reciter,
    this.name,
    this.imageUrl,
    this.size = 52,
    this.selected = false,
  });

  final QuranAudioReciter? reciter;
  final String? name;
  final String? imageUrl;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final displayName = name ?? reciter?.name ?? 'Quran';
    final url = imageUrl ?? reciter?.effectiveImageUrl;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: selected ? primary : QuranTheme.softFill(context, primary),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? primary : QuranTheme.outline(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: selected ? 0.10 : 0.06),
            blurRadius: selected ? 16 : 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipOval(
        child: url == null
            ? _ReciterAvatarFallback(name: displayName, selected: selected)
            : Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _ReciterAvatarFallback(
                  name: displayName,
                  selected: selected,
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }
                  return _ReciterAvatarFallback(
                    name: displayName,
                    selected: selected,
                  );
                },
              ),
      ),
    );
  }
}

class _ReciterAvatarFallback extends StatelessWidget {
  const _ReciterAvatarFallback({required this.name, required this.selected});

  final String name;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ColoredBox(
      color: selected ? primary : QuranTheme.softFill(context, primary),
      child: Center(
        child: Text(
          _initials(name),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: selected ? Theme.of(context).colorScheme.onPrimary : primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class QuranReciterMetaChip extends StatelessWidget {
  const QuranReciterMetaChip({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
        border: Border.all(color: QuranTheme.outline(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: QuranTheme.subText(context)),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: QuranTheme.subText(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String quranAudioProviderLabel(QuranAudioProvider provider) {
  return switch (provider) {
    QuranAudioProvider.everyAyah => 'EveryAyah',
    QuranAudioProvider.alQuranCloud => 'Al Quran Cloud',
    QuranAudioProvider.quranEnc => 'QuranEnc',
  };
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    return _leadingCharacters(parts.first, 2).toUpperCase();
  }
  return '${_leadingCharacters(parts.first, 1)}'
          '${_leadingCharacters(parts.last, 1)}'
      .toUpperCase();
}

String _leadingCharacters(String value, int count) {
  final buffer = StringBuffer();
  final iterator = value.runes.iterator;
  while (buffer.length < count && iterator.moveNext()) {
    buffer.write(String.fromCharCode(iterator.current));
  }
  return buffer.toString();
}
