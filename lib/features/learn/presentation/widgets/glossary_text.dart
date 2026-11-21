import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../data/guide_terms.dart';
import '../../domain/guide_term.dart';
import '../../domain/guide_term_matcher.dart';
import '../pages/guide_term_page.dart';

class GlossaryText extends StatefulWidget {
  const GlossaryText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textDirection,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextDirection? textDirection;

  @override
  State<GlossaryText> createState() => _GlossaryTextState();
}

class _GlossaryTextState extends State<GlossaryText> {
  static final _matcher = GuideTermMatcher(guideTerms);
  final _recognizers = <TapGestureRecognizer>[];
  late List<InlineSpan> _spans;

  @override
  void initState() {
    super.initState();
    _buildSpans();
  }

  @override
  void didUpdateWidget(covariant GlossaryText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) _buildSpans();
  }

  void _buildSpans() {
    _disposeRecognizers();
    _spans = [];
    var end = 0;
    for (final match in _matcher.findIn(widget.data)) {
      if (match.start > end) {
        _spans.add(TextSpan(text: widget.data.substring(end, match.start)));
      }
      Offset? anchor;
      final recognizer = TapGestureRecognizer()
        ..onTapDown = (details) {
          anchor = details.globalPosition;
        }
        ..onTapCancel = () {
          anchor = null;
        }
        ..onTap = () {
          final position = anchor;
          anchor = null;
          _showDefinition(match.term, position);
        };
      _recognizers.add(recognizer);
      _spans.add(
        TextSpan(
          text: widget.data.substring(match.start, match.end),
          recognizer: recognizer,
          mouseCursor: SystemMouseCursors.click,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationThickness: 1.4,
          ),
        ),
      );
      end = match.end;
    }
    if (end < widget.data.length) {
      _spans.add(TextSpan(text: widget.data.substring(end)));
    }
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  Future<void> _showDefinition(GuideTerm term, Offset? position) async {
    final box = context.findRenderObject();
    final anchor =
        position ??
        (box is RenderBox && box.hasSize
            ? box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2))
            : MediaQuery.sizeOf(context).center(Offset.zero));
    final learnMore = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 160),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final padding = MediaQuery.paddingOf(dialogContext);
        return Directionality(
          textDirection: TextDirection.ltr,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const margin = 16.0;
                final width = math.min(
                  390.0,
                  constraints.maxWidth - margin * 2,
                );
                final rawPoint = anchor - Offset(padding.left, padding.top);
                final point = Offset(
                  rawPoint.dx.clamp(margin, constraints.maxWidth - margin),
                  rawPoint.dy.clamp(margin, constraints.maxHeight - margin),
                );
                final left = (point.dx - width / 2).clamp(
                  margin,
                  constraints.maxWidth - width - margin,
                );
                final above = math.max(0.0, point.dy - margin - 12);
                final below = math.max(
                  0.0,
                  constraints.maxHeight - point.dy - margin - 12,
                );
                final placeBelow =
                    below >= math.min(240, constraints.maxHeight / 2) ||
                    below >= above;
                final space = placeBelow ? below : above;
                final center = space < 160;
                final maxHeight = center
                    ? constraints.maxHeight - margin * 2
                    : math.min(420.0, space);
                return Stack(
                  children: [
                    Positioned(
                      left: left,
                      width: width,
                      top: center
                          ? margin
                          : (placeBelow ? point.dy + 12 : null),
                      bottom: !center && !placeBelow
                          ? constraints.maxHeight - point.dy + 12
                          : null,
                      child: _DefinitionPopup(
                        term: term,
                        maxHeight: maxHeight,
                        onClose: () => Navigator.of(dialogContext).pop(false),
                        onLearnMore: () =>
                            Navigator.of(dialogContext).pop(true),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    if (learnMore != true || !mounted) return;
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => GuideTermPage(term: term)));
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _spans),
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      softWrap: widget.softWrap,
      textDirection: widget.textDirection,
    );
  }
}

class _DefinitionPopup extends StatelessWidget {
  const _DefinitionPopup({
    required this.term,
    required this.maxHeight,
    required this.onClose,
    required this.onLearnMore,
  });

  final GuideTerm term;
  final double maxHeight;
  final VoidCallback onClose;
  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: QuranTheme.surface(context),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      elevation: 10,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Semantics(
                        header: true,
                        child: Text(term.title, style: textTheme.titleLarge),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close definition',
                    autofocus: true,
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  term.definition,
                  style: textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
              if (term.hasDetails) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onLearnMore,
                  child: const Text('Learn more'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
