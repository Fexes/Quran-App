import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/architectural_backdrop.dart';
import '../../../../core/widgets/note_editor_sheet.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../data/stores/quran_user_data_store.dart';
import '../../domain/entities/quran_note.dart';

enum _NoteFilter { all, ayahs, personal }

class QuranNotesPage extends StatefulWidget {
  const QuranNotesPage({super.key, this.initialNoteId});

  final String? initialNoteId;

  @override
  State<QuranNotesPage> createState() => _QuranNotesPageState();
}

class _QuranNotesPageState extends State<QuranNotesPage> {
  late final QuranUserDataStore _store;
  final _searchController = TextEditingController();
  var _notes = <QuranNote>[];
  var _query = '';
  var _filter = _NoteFilter.all;
  bool _newestFirst = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _store = getIt<QuranUserDataStore>();
    _loadNotes();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openInitialNote());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadNotes() => setState(() => _notes = _store.notes);

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _openInitialNote() {
    final id = widget.initialNoteId?.trim();
    if (id == null || id.isEmpty || !mounted) return;
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
      builder: (context) => NoteEditorSheet(
        title: note == null ? 'New reflection' : 'Edit reflection',
        subtitle: note?.verseKey == null
            ? 'Personal note'
            : 'Ayah ${note!.verseKey}',
        initialText: note?.text ?? '',
        onSave: (text) async {
          await _store.saveNote(id: note?.id, text: text.trim());
          if (mounted) {
            if (note == null) {
              _searchController.clear();
              _query = '';
              _filter = _NoteFilter.all;
              _newestFirst = true;
            }
            _loadNotes();
          }
        },
      ),
    );
    if (text != null && mounted) _message('Note saved');
  }

  Future<void> _deleteNote(QuranNote note) async {
    if (_deleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Delete note?'),
        content: const Text(
          'This note will be permanently deleted. Your bookmarks will not change.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep note'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _deleting) return;
    setState(() => _deleting = true);
    try {
      await _store.deleteNote(note.id);
      if (mounted) {
        _loadNotes();
        _message('Note deleted');
      }
    } catch (_) {
      if (mounted) _message('Note could not be deleted. Please try again.');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _openVerse(QuranNote note) async {
    final parts = note.verseKey?.split(':');
    final surah = parts?.length == 2 ? int.tryParse(parts![0]) : null;
    final ayah = parts?.length == 2 ? int.tryParse(parts![1]) : null;
    if (surah == null || surah < 1 || surah > 114 || ayah == null || ayah < 1) {
      _message('This note has no valid ayah reference.');
      return;
    }
    await context.push(
      AppRoutes.quranReaderPath(
        surah,
        ayahNumber: ayah,
        translationResourceId: note.translationResourceId,
      ),
    );
    if (mounted) _loadNotes();
  }

  String _dateLabel(DateTime value) {
    final date = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'Today';
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return 'Yesterday';
    }
    return DateFormat.yMMMd().format(date);
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _filter = _NoteFilter.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkedCount = _notes.where((note) => note.verseKey != null).length;
    final filtered = _notes.where((note) {
      if (_filter == _NoteFilter.ayahs && note.verseKey == null) return false;
      if (_filter == _NoteFilter.personal && note.verseKey != null) {
        return false;
      }
      return _query.isEmpty ||
          note.text.toLowerCase().contains(_query) ||
          (note.verseKey?.contains(_query) ?? false);
    }).toList();
    filtered.sort(
      (a, b) => _newestFirst
          ? b.updatedAt.compareTo(a.updatedAt)
          : a.updatedAt.compareTo(b.updatedAt),
    );
    assert(filtered.every((note) => _notes.contains(note)));
    final hasFilters = _query.isNotEmpty || _filter != _NoteFilter.all;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notes'),
        flexibleSpace: const ArchitecturalBackdrop(),
        leading: IconButton(
          tooltip: 'Back',
          icon: const AppIcon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New note',
        onPressed: _deleting ? null : () => _openNoteEditor(),
        child: const AppIcon(Icons.edit_note_rounded),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async => _loadNotes(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your reflections',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_notes.length} notes  /  $linkedCount linked to ayahs',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: QuranTheme.subText(context, 0.65),
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onChanged: (value) =>
                            setState(() => _query = value.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search notes or ayah',
                          prefixIcon: const AppIcon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const AppIcon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final filter in _NoteFilter.values)
                            ChoiceChip(
                              showCheckmark: false,
                              label: Text(switch (filter) {
                                _NoteFilter.all => 'All (${_notes.length})',
                                _NoteFilter.ayahs => 'Ayahs ($linkedCount)',
                                _NoteFilter.personal =>
                                  'Personal (${_notes.length - linkedCount})',
                              }),
                              selected: _filter == filter,
                              onSelected: (_) =>
                                  setState(() => _filter = filter),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              hasFilters
                                  ? '${filtered.length} matching notes'
                                  : 'All notes',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          PopupMenuButton<bool>(
                            tooltip: 'Sort notes',
                            icon: const AppIcon(Icons.sort_rounded),
                            initialValue: _newestFirst,
                            onSelected: (value) =>
                                setState(() => _newestFirst = value),
                            itemBuilder: (_) => [
                              CheckedPopupMenuItem(
                                value: true,
                                checked: _newestFirst,
                                child: const Text('Recently edited'),
                              ),
                              CheckedPopupMenuItem(
                                value: false,
                                checked: !_newestFirst,
                                child: const Text('Oldest first'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 96),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(
                          hasFilters
                              ? Icons.search_off_rounded
                              : Icons.edit_note_rounded,
                          size: 44,
                          color: QuranTheme.subText(context, 0.55),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          hasFilters
                              ? 'No matching notes'
                              : 'A place for reflection',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: hasFilters
                              ? _clearFilters
                              : () => _openNoteEditor(),
                          child: Text(
                            hasFilters ? 'Show all notes' : 'Write a note',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final note = filtered[index];
                      final date = _dateLabel(note.updatedAt);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (index == 0 ||
                              date != _dateLabel(filtered[index - 1].updatedAt))
                            Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 0 : 12,
                                bottom: 12,
                              ),
                              child: Text(
                                date,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: QuranTheme.subText(context, 0.65),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _NoteCard(
                              key: ValueKey(note.id),
                              note: note,
                              onEdit: () => _openNoteEditor(note),
                              onOpenVerse: note.verseKey == null
                                  ? null
                                  : () => _openVerse(note),
                              onDelete: _deleting
                                  ? null
                                  : () => _deleteNote(note),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onOpenVerse,
    required this.onDelete,
  });
  final QuranNote note;
  final VoidCallback onEdit;
  final VoidCallback? onOpenVerse;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseAccent = onOpenVerse == null
        ? const Color(0xFF98613C)
        : const Color(0xFF397E72);
    final accent = QuranTheme.isDark(context)
        ? Color.lerp(baseAccent, Colors.white, 0.4)!
        : baseAccent;
    return PremiumSurface(
      radius: 8,
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: onOpenVerse == null
                    ? Row(
                        children: [
                          AppIcon(
                            Icons.edit_note_rounded,
                            color: accent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Personal note',
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                        ],
                      )
                    : TextButton.icon(
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: onOpenVerse,
                        icon: AppIcon(
                          Icons.menu_book_rounded,
                          size: 18,
                          color: accent,
                        ),
                        label: Text(
                          'Ayah ${note.verseKey}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Note actions',
                enabled: onDelete != null,
                icon: const AppIcon(Icons.more_horiz_rounded),
                onSelected: (action) =>
                    action == 'edit' ? onEdit() : onDelete?.call(),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit note')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete note',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            note.text,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AppIcon(
                Icons.schedule_rounded,
                size: 13,
                color: QuranTheme.subText(context, 0.55),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Edited ${DateFormat.jm().format(note.updatedAt.toLocal())}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: QuranTheme.subText(context, 0.65),
                  ),
                ),
              ),
              AppIcon(
                Icons.edit_rounded,
                size: 16,
                color: QuranTheme.subText(context, 0.55),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
