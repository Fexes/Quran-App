import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../data/stores/quran_user_data_store.dart';
import '../../domain/entities/quran_note.dart';

class QuranNotesPage extends StatefulWidget {
  const QuranNotesPage({super.key, this.initialNoteId});

  final String? initialNoteId;

  @override
  State<QuranNotesPage> createState() => _QuranNotesPageState();
}

class _QuranNotesPageState extends State<QuranNotesPage> {
  late final QuranUserDataStore _store;
  late final TextEditingController _searchController;
  var _notes = <QuranNote>[];
  var _query = '';

  @override
  void initState() {
    super.initState();
    _store = getIt<QuranUserDataStore>();
    _searchController = TextEditingController();
    _loadNotes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialNote();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadNotes() {
    setState(() => _notes = _store.notes);
  }

  void _openInitialNote() {
    final id = widget.initialNoteId?.trim();
    if (id == null || id.isEmpty || !mounted) {
      return;
    }
    for (final note in _notes) {
      if (note.id == id) {
        _openNoteEditor(note);
        return;
      }
    }
  }

  Future<void> _openNoteEditor([QuranNote? note]) async {
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _NoteEditorSheet(note: note),
    );
    if (text == null || !mounted) {
      return;
    }
    await _store.saveNote(id: note?.id, text: text);
    if (mounted) {
      _loadNotes();
    }
  }

  Future<void> _deleteNote(QuranNote note) async {
    await _store.deleteNote(note.id);
    if (mounted) {
      _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _notes
        .where((note) {
          if (_query.isEmpty) {
            return true;
          }
          return note.text.toLowerCase().contains(_query) ||
              (note.verseKey?.contains(_query) ?? false);
        })
        .toList(growable: false);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNoteEditor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add note'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search notes or verse key',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (value) {
                  setState(() => _query = value.trim().toLowerCase());
                },
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const _NotesEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final note = filtered[index];
                        return _NoteTile(
                          note: note,
                          onTap: () => _openNoteEditor(note),
                          onVerseTap: note.verseKey == null
                              ? null
                              : () => _openVerse(note.verseKey!),
                          onDelete: () => _deleteNote(note),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVerse(String verseKey) {
    final parts = verseKey.split(':');
    if (parts.length != 2) {
      return;
    }
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null) {
      return;
    }
    context.push(AppRoutes.quranReaderPath(surah, ayahNumber: ayah));
  }
}

class _NotesEmptyState extends StatelessWidget {
  const _NotesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 58,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'No notes yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Save reflections, study points, and reminders here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: QuranTheme.subText(context, 0.68),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({
    required this.note,
    required this.onTap,
    required this.onDelete,
    this.onVerseTap,
  });

  final QuranNote note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onVerseTap;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.yMMMd().add_jm();
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      prominent: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: QuranTheme.softFill(
                context,
                Theme.of(context).colorScheme.primary,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notes_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.38,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (note.verseKey != null) ...[
                  const SizedBox(height: 8),
                  ActionChip(
                    avatar: const Icon(Icons.menu_book_rounded, size: 17),
                    label: Text('Ayah ${note.verseKey}'),
                    onPressed: onVerseTap,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  formatter.format(note.updatedAt),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: QuranTheme.subText(context, 0.62),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete note',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _NoteEditorSheet extends StatefulWidget {
  const _NoteEditorSheet({this.note});

  final QuranNote? note;

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note?.text ?? '')
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final canSave = _controller.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 12),
      child: PremiumSurface(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        radius: QuranTheme.radiusSheet,
        prominent: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.note == null ? 'Add note' : 'Edit note',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 5,
              maxLines: 8,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Write a reflection or study note',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: canSave
                  ? () => Navigator.of(context).pop(_controller.text.trim())
                  : null,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save note'),
            ),
          ],
        ),
      ),
    );
  }
}
