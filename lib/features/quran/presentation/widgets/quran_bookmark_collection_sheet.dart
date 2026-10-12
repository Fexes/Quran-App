import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_sheet.dart';

Color bookmarkCollectionColor(BuildContext context, int colorValue) {
  final color = Color(colorValue);
  return QuranTheme.isDark(context)
      ? Color.lerp(color, Colors.white, 0.4)!
      : color;
}

IconData bookmarkCollectionIcon(int codePoint) {
  for (final icon in const [
    Icons.bookmark_rounded,
    Icons.favorite_rounded,
    Icons.school_rounded,
  ]) {
    if (icon.codePoint == codePoint) return icon;
  }
  return Icons.bookmark_rounded;
}

class QuranBookmarkCollectionSheet extends StatefulWidget {
  const QuranBookmarkCollectionSheet({super.key, required this.onCreate});

  final Future<bool> Function(
    String name,
    String description,
    int color,
    int icon,
  )
  onCreate;

  @override
  State<QuranBookmarkCollectionSheet> createState() =>
      _QuranBookmarkCollectionSheetState();
}

class _QuranBookmarkCollectionSheetState
    extends State<QuranBookmarkCollectionSheet> {
  String _name = '';
  String _description = '';
  int _color = 0xFF2E7D5B;
  int _icon = Icons.bookmark_rounded.codePoint;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving || _name.trim().isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await widget.onCreate(
      _name.trim(),
      _description.trim(),
      _color,
      _icon,
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = 'Collection could not be saved. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'New collection',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            autofocus: true,
            enabled: !_saving,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Collection name'),
            onChanged: (value) => setState(() => _name = value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            enabled: !_saving,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
            ),
            onChanged: (value) => _description = value,
          ),
          const SizedBox(height: 20),
          Text('Color', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final color in const {
                0xFF2E7D5B: 'Green',
                0xFF1565C0: 'Blue',
                0xFF6A1B9A: 'Purple',
                0xFFEF6C00: 'Orange',
              }.entries)
                Semantics(
                  selected: _color == color.key,
                  child: IconButton.filled(
                    tooltip: color.value,
                    style: IconButton.styleFrom(
                      backgroundColor: Color(color.key),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.square(44),
                    ),
                    onPressed: _saving
                        ? null
                        : () => setState(() => _color = color.key),
                    icon: AppIcon(
                      _color == color.key ? Icons.check_rounded : Icons.circle,
                      size: _color == color.key ? 22 : 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Icon', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (final entry in const {
                'Bookmark': Icons.bookmark_rounded,
                'Favorite': Icons.favorite_rounded,
                'Study': Icons.school_rounded,
              }.entries)
                ButtonSegment(
                  value: entry.value.codePoint,
                  tooltip: entry.key,
                  icon: AppIcon(entry.value),
                ),
            ],
            selected: {_icon},
            onSelectionChanged: _saving
                ? null
                : (values) => setState(() => _icon = values.first),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving || _name.trim().isEmpty ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const AppIcon(Icons.add_rounded),
            label: Text(_saving ? 'Saving...' : 'Create collection'),
          ),
        ],
      ),
    );
  }
}
