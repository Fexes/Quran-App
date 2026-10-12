import 'package:flutter/material.dart';
import 'app_icon.dart';

import 'app_sheet.dart';

class NoteEditorSheet extends StatefulWidget {
  const NoteEditorSheet({
    super.key,
    required this.title,
    this.initialText = '',
    this.allowEmpty = false,
    this.subtitle,
    this.onSave,
  });

  final String title;
  final String initialText;
  final bool allowEmpty;
  final String? subtitle;
  final Future<void> Function(String text)? onSave;

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  late String _text = widget.initialText;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving || (!widget.allowEmpty && _text.trim().isEmpty)) return;
    assert(widget.allowEmpty || _text.trim().isNotEmpty);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave?.call(_text);
      if (mounted) Navigator.of(context).pop(_text);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Your note could not be saved. Your draft is still here.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: widget.title,
      subtitle: widget.subtitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            initialValue: widget.initialText,
            autofocus: true,
            enabled: !_saving,
            minLines: 5,
            maxLines: 8,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Write a note'),
            onChanged: (text) => setState(() => _text = text),
          ),
          const SizedBox(height: 14),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed:
                !_saving && (widget.allowEmpty || _text.trim().isNotEmpty)
                ? _save
                : null,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const AppIcon(Icons.check_rounded),
            label: Text(_saving ? 'Saving...' : 'Save note'),
          ),
        ],
      ),
    );
  }
}
