import 'package:flutter/material.dart';
import 'app_icon.dart';

import '../theme/quran_theme.dart';

class AppSheet extends StatefulWidget {
  const AppSheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
    this.scrollableChild = false,
  });

  final String title;
  final String? subtitle;
  final Widget? footer;
  final Widget child;
  final bool scrollableChild;

  @override
  State<AppSheet> createState() => _AppSheetState();
}

class _AppSheetState extends State<AppSheet> {
  double _dismissPull = 0;
  bool _dismissing = false;

  void _close() {
    if (_dismissing || !mounted || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _dismissing = true;
    Navigator.of(context).pop();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is ScrollStartNotification) _dismissPull = 0;
    if (notification is OverscrollNotification &&
        notification.dragDetails != null &&
        notification.metrics.pixels <= notification.metrics.minScrollExtent &&
        notification.overscroll < 0) {
      _dismissPull -= notification.overscroll;
    }
    if (notification is ScrollEndNotification && _dismissPull >= 64) {
      _dismissPull = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _close();
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Material(
        color: QuranTheme.surface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(QuranTheme.radiusSheet),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: AnimatedSize(
            duration: media.disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 240),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    ((media.size.height -
                                media.padding.top -
                                media.viewInsets.bottom) *
                            0.9)
                        .clamp(0.0, media.size.height)
                        .toDouble(),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (widget.subtitle?.isNotEmpty == true)
                                Text(
                                  widget.subtitle!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: QuranTheme.subText(context),
                                      ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: _close,
                          icon: const AppIcon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _onScroll,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: ClampingScrollPhysics(),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: widget.scrollableChild
                              ? widget.child
                              : SingleChildScrollView(child: widget.child),
                        ),
                      ),
                    ),
                  ),
                  if (widget.footer != null)
                    Material(
                      color: QuranTheme.surface(context),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: widget.footer,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
