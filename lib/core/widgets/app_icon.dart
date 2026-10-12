import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Original 24-unit linework, inspired by courtyard arches and Arab craftwork.
/// Keeps Icon's API so existing tooltips, buttons and selected colors still work.
class AppIcon extends Icon {
  const AppIcon(
    super.icon, {
    super.key,
    super.size,
    super.color,
    super.semanticLabel,
    super.textDirection,
    super.applyTextScaling,
    this.strokeWidth = 1.5,
  }) : assert(strokeWidth > 0);

  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final mark = _marks[icon];
    if (mark == null) return super.build(context);
    final theme = IconTheme.of(context);
    final direction = textDirection ?? Directionality.of(context);
    var extent = size ?? theme.size ?? 24;
    if (applyTextScaling ?? theme.applyTextScaling ?? false) {
      extent = MediaQuery.textScalerOf(context).scale(extent);
    }
    final ink = color ?? theme.color ?? Colors.black;
    return Semantics(
      label: semanticLabel,
      textDirection: direction,
      child: SizedBox.square(
        dimension: extent,
        child: Center(
          child: CustomPaint(
            size: Size.square(extent),
            painter: _AppIconPainter(
              mark,
              ink.withValues(alpha: ink.a * (theme.opacity ?? 1)),
              strokeWidth: strokeWidth,
              mirror:
                  (icon?.matchTextDirection ?? false) &&
                  direction == TextDirection.rtl,
            ),
          ),
        ),
      ),
    );
  }
}

enum _Mark {
  home,
  quran,
  book,
  library,
  mosque,
  qibla,
  beads,
  bookmark,
  bookmarkFilled,
  notes,
  language,
  download,
  upload,
  calendar,
  journal,
  moon,
  sun,
  sunrise,
  sunset,
  lantern,
  dua,
  fasting,
  names,
  goal,
  award,
  settings,
  tune,
  location,
  locationOff,
  target,
  clock,
  hourglass,
  search,
  searchOff,
  heart,
  heartFilled,
  shield,
  lock,
  garden,
  travel,
  people,
  city,
  folder,
  memory,
  audio,
  voice,
  bell,
  bellActive,
  flame,
  picture,
  layout,
  list,
  textSize,
  play,
  pause,
  next,
  previous,
  repeat,
  speed,
  refresh,
  undo,
  back,
  forward,
  chevronLeft,
  chevronRight,
  down,
  up,
  outward,
  close,
  add,
  remove,
  check,
  checkCircle,
  info,
  error,
  more,
  copy,
  share,
  delete,
  eye,
  eyeOff,
  hash,
  infinity,
  flag,
  calculator,
  storage,
  drag,
}

final _marks = <IconData, _Mark>{
  Icons.home_outlined: _Mark.home,
  Icons.home_rounded: _Mark.home,
  Icons.menu_book_outlined: _Mark.quran,
  Icons.menu_book_rounded: _Mark.quran,
  Icons.auto_stories_outlined: _Mark.book,
  Icons.auto_stories_rounded: _Mark.book,
  Icons.book_outlined: _Mark.book,
  Icons.school_rounded: _Mark.book,
  Icons.local_library_outlined: _Mark.library,
  Icons.local_library_rounded: _Mark.library,
  Icons.library_books_outlined: _Mark.library,
  Icons.library_books_rounded: _Mark.library,
  Icons.collections_bookmark_outlined: _Mark.library,
  Icons.mosque_outlined: _Mark.mosque,
  Icons.mosque_rounded: _Mark.mosque,
  Icons.explore_outlined: _Mark.qibla,
  Icons.explore_rounded: _Mark.qibla,
  Icons.navigation_rounded: _Mark.qibla,
  Icons.trip_origin_rounded: _Mark.beads,
  Icons.bookmark_border_rounded: _Mark.bookmark,
  Icons.bookmark_rounded: _Mark.bookmarkFilled,
  Icons.bookmarks_outlined: _Mark.bookmark,
  Icons.edit_note_rounded: _Mark.notes,
  Icons.notes_rounded: _Mark.notes,
  Icons.edit_rounded: _Mark.notes,
  Icons.translate_rounded: _Mark.language,
  Icons.language_rounded: _Mark.language,
  Icons.file_download_outlined: _Mark.download,
  Icons.download_outlined: _Mark.download,
  Icons.download_rounded: _Mark.download,
  Icons.downloading_rounded: _Mark.download,
  Icons.cloud_download_rounded: _Mark.download,
  Icons.download_for_offline_outlined: _Mark.download,
  Icons.download_for_offline_rounded: _Mark.download,
  Icons.file_upload_outlined: _Mark.upload,
  Icons.offline_pin_outlined: _Mark.checkCircle,
  Icons.offline_pin_rounded: _Mark.checkCircle,
  Icons.download_done_rounded: _Mark.checkCircle,
  Icons.calendar_today_outlined: _Mark.calendar,
  Icons.calendar_today_rounded: _Mark.calendar,
  Icons.calendar_month_outlined: _Mark.calendar,
  Icons.calendar_month_rounded: _Mark.calendar,
  Icons.fact_check_outlined: _Mark.journal,
  Icons.dark_mode_outlined: _Mark.moon,
  Icons.bedtime_rounded: _Mark.moon,
  Icons.nightlight_outlined: _Mark.moon,
  Icons.brightness_4_outlined: _Mark.moon,
  Icons.wb_sunny_rounded: _Mark.sun,
  Icons.wb_sunny_outlined: _Mark.sun,
  Icons.light_mode_outlined: _Mark.sun,
  Icons.brightness_6_rounded: _Mark.sun,
  Icons.wb_twilight_outlined: _Mark.sunrise,
  Icons.wb_twilight_rounded: _Mark.sunset,
  Icons.lightbulb_outline_rounded: _Mark.lantern,
  Icons.volunteer_activism_outlined: _Mark.dua,
  Icons.restaurant_rounded: _Mark.fasting,
  Icons.calculate_outlined: _Mark.calculator,
  Icons.auto_awesome_outlined: _Mark.names,
  Icons.auto_awesome_rounded: _Mark.names,
  Icons.circle_outlined: _Mark.names,
  Icons.radio_button_checked_rounded: _Mark.beads,
  Icons.track_changes_rounded: _Mark.goal,
  Icons.workspace_premium_outlined: _Mark.award,
  Icons.star_outline_rounded: _Mark.award,
  Icons.stars_outlined: _Mark.award,
  Icons.settings_rounded: _Mark.settings,
  Icons.tune_outlined: _Mark.tune,
  Icons.tune_rounded: _Mark.tune,
  Icons.location_on_outlined: _Mark.location,
  Icons.location_on_rounded: _Mark.location,
  Icons.location_off_rounded: _Mark.locationOff,
  Icons.my_location_rounded: _Mark.target,
  Icons.schedule_outlined: _Mark.clock,
  Icons.schedule_rounded: _Mark.clock,
  Icons.access_time_rounded: _Mark.clock,
  Icons.timer_rounded: _Mark.hourglass,
  Icons.history_rounded: _Mark.clock,
  Icons.update_rounded: _Mark.clock,
  Icons.search_rounded: _Mark.search,
  Icons.manage_search_rounded: _Mark.search,
  Icons.search_off_rounded: _Mark.searchOff,
  Icons.favorite_border_rounded: _Mark.heart,
  Icons.favorite_rounded: _Mark.heartFilled,
  Icons.health_and_safety_rounded: _Mark.shield,
  Icons.verified_user_outlined: _Mark.shield,
  Icons.verified_outlined: _Mark.shield,
  Icons.lock_outline_rounded: _Mark.lock,
  Icons.lock_person_rounded: _Mark.lock,
  Icons.park_rounded: _Mark.garden,
  Icons.flight_takeoff_rounded: _Mark.travel,
  Icons.group_outlined: _Mark.people,
  Icons.groups_rounded: _Mark.people,
  Icons.location_city_rounded: _Mark.city,
  Icons.folder_open_rounded: _Mark.folder,
  Icons.psychology_alt_outlined: _Mark.memory,
  Icons.graphic_eq_rounded: _Mark.audio,
  Icons.record_voice_over_outlined: _Mark.voice,
  Icons.record_voice_over_rounded: _Mark.voice,
  Icons.notifications_none_rounded: _Mark.bell,
  Icons.notifications_rounded: _Mark.bell,
  Icons.notifications_active_outlined: _Mark.bellActive,
  Icons.notifications_active_rounded: _Mark.bellActive,
  Icons.local_fire_department_outlined: _Mark.flame,
  Icons.local_fire_department_rounded: _Mark.flame,
  Icons.offline_bolt_rounded: _Mark.flame,
  Icons.image_rounded: _Mark.picture,
  Icons.view_agenda_outlined: _Mark.layout,
  Icons.view_week_rounded: _Mark.layout,
  Icons.view_headline_rounded: _Mark.list,
  Icons.list_alt_rounded: _Mark.list,
  Icons.segment_rounded: _Mark.list,
  Icons.text_fields_rounded: _Mark.textSize,
  Icons.format_size_rounded: _Mark.textSize,
  Icons.play_arrow_rounded: _Mark.play,
  Icons.pause_rounded: _Mark.pause,
  Icons.skip_next_rounded: _Mark.next,
  Icons.skip_previous_rounded: _Mark.previous,
  Icons.repeat_rounded: _Mark.repeat,
  Icons.compare_arrows_rounded: _Mark.repeat,
  Icons.speed_rounded: _Mark.speed,
  Icons.refresh_rounded: _Mark.refresh,
  Icons.replay_rounded: _Mark.refresh,
  Icons.restart_alt_rounded: _Mark.refresh,
  Icons.undo_rounded: _Mark.undo,
  Icons.arrow_back_rounded: _Mark.back,
  Icons.arrow_forward_rounded: _Mark.forward,
  Icons.arrow_back_ios_new_rounded: _Mark.chevronLeft,
  Icons.chevron_left_rounded: _Mark.chevronLeft,
  Icons.chevron_right_rounded: _Mark.chevronRight,
  Icons.expand_more_rounded: _Mark.down,
  Icons.vertical_align_top_rounded: _Mark.up,
  Icons.keyboard_double_arrow_up_rounded: _Mark.up,
  Icons.arrow_outward_rounded: _Mark.outward,
  Icons.open_in_new_rounded: _Mark.outward,
  Icons.close_rounded: _Mark.close,
  Icons.add_rounded: _Mark.add,
  Icons.add_circle_outline_rounded: _Mark.add,
  Icons.remove_rounded: _Mark.remove,
  Icons.remove_circle_outline_rounded: _Mark.remove,
  Icons.check_rounded: _Mark.check,
  Icons.check_circle_rounded: _Mark.checkCircle,
  Icons.info_rounded: _Mark.info,
  Icons.info_outline_rounded: _Mark.info,
  Icons.error_outline_rounded: _Mark.error,
  Icons.more_horiz_rounded: _Mark.more,
  Icons.copy_rounded: _Mark.copy,
  Icons.share_rounded: _Mark.share,
  Icons.ios_share_rounded: _Mark.share,
  Icons.delete_outline_rounded: _Mark.delete,
  Icons.delete_forever_rounded: _Mark.delete,
  Icons.delete_sweep_rounded: _Mark.delete,
  Icons.visibility_rounded: _Mark.eye,
  Icons.visibility_off_outlined: _Mark.eyeOff,
  Icons.tag_rounded: _Mark.hash,
  Icons.all_inclusive_rounded: _Mark.infinity,
  Icons.flag_rounded: _Mark.flag,
  Icons.storage_rounded: _Mark.storage,
  Icons.drag_handle_rounded: _Mark.drag,
};

class _AppIconPainter extends CustomPainter {
  const _AppIconPainter(
    this.mark,
    this.color, {
    required this.mirror,
    required this.strokeWidth,
  });
  final _Mark mark;
  final Color color;
  final bool mirror;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    if (mirror) {
      canvas.translate(24, 0);
      canvas.scale(-1, 1);
    }
    final ink = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    void path(Path p, {bool solid = false}) =>
        canvas.drawPath(p, solid ? fill : ink);
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), ink);
    void circle(double x, double y, double radius, {bool solid = false}) =>
        canvas.drawCircle(Offset(x, y), radius, solid ? fill : ink);
    void box(double x, double y, double w, double h, [double radius = 1]) =>
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h),
            Radius.circular(radius),
          ),
          ink,
        );
    void arch(double left, double top, double width, double bottom) {
      path(
        Path()
          ..moveTo(left, bottom)
          ..lineTo(left, top + width * .6)
          ..cubicTo(
            left,
            top + width * .3,
            left + width * .35,
            top + width * .25,
            left + width * .5,
            top,
          )
          ..cubicTo(
            left + width * .65,
            top + width * .25,
            left + width,
            top + width * .3,
            left + width,
            top + width * .6,
          )
          ..lineTo(left + width, bottom),
      );
    }

    void star(double x, double y, double radius) {
      final p = Path();
      for (var i = 0; i < 16; i++) {
        final a = -math.pi / 2 + i * math.pi / 8,
            r = i.isEven ? radius : radius * .72;
        final px = x + math.cos(a) * r, py = y + math.sin(a) * r;
        if (i == 0) {
          p.moveTo(px, py);
        } else {
          p.lineTo(px, py);
        }
      }
      path(p..close());
    }

    void moon() => path(
      Path()
        ..moveTo(16, 3)
        ..cubicTo(4, 1, 1, 17, 11, 21)
        ..cubicTo(16, 23, 21, 19, 21, 15)
        ..cubicTo(10, 20, 7, 6, 16, 3)
        ..close(),
    );
    void check() => path(
      Path()
        ..moveTo(7, 12)
        ..lineTo(10.5, 15.5)
        ..lineTo(17, 8.5),
    );
    switch (mark) {
      case _Mark.home:
        arch(4, 2.5, 16, 21);
        line(4, 21, 20, 21);
        arch(9, 12, 6, 21);
        line(7, 10, 7, 12);
        line(17, 10, 17, 12);
      case _Mark.quran:
        path(
          Path()
            ..moveTo(12, 7)
            ..cubicTo(8, 4, 5, 4, 2.5, 5)
            ..lineTo(2.5, 18)
            ..cubicTo(6, 17, 9, 18, 12, 20)
            ..cubicTo(15, 18, 18, 17, 21.5, 18)
            ..lineTo(21.5, 5)
            ..cubicTo(19, 4, 16, 4, 12, 7)
            ..lineTo(12, 20),
        );
        line(5.5, 8, 9, 9);
        line(5.5, 11, 9, 12);
        line(15, 9, 18.5, 8);
        line(15, 12, 18.5, 11);
      case _Mark.book:
        box(5, 3, 14, 18, 1.6);
        line(8, 3, 8, 21);
        arch(11, 6, 5, 14);
        line(11, 14, 16, 14);
        line(11, 17, 16, 17);
      case _Mark.library:
        arch(2.5, 2.5, 19, 21);
        line(2.5, 21, 21.5, 21);
        box(6, 11, 3, 8, .4);
        box(10.5, 9, 3, 10, .4);
        path(
          Path()
            ..moveTo(16, 10)
            ..lineTo(19, 18.5)
            ..lineTo(16.5, 19.3)
            ..lineTo(13.8, 10.8)
            ..close(),
        );
      case _Mark.mosque:
        arch(6, 6, 12, 20);
        line(3, 20, 21, 20);
        line(3, 20, 3, 7);
        line(21, 20, 21, 7);
        path(
          Path()
            ..moveTo(1.5, 7)
            ..lineTo(3, 3)
            ..lineTo(4.5, 7)
            ..close(),
        );
        path(
          Path()
            ..moveTo(19.5, 7)
            ..lineTo(21, 3)
            ..lineTo(22.5, 7)
            ..close(),
        );
        arch(10, 13, 4, 20);
        line(12, 6, 12, 3);
      case _Mark.qibla:
        star(12, 12, 10);
        path(
          Path()
            ..moveTo(16, 7)
            ..lineTo(13, 15)
            ..lineTo(7, 17)
            ..lineTo(10, 9)
            ..close(),
        );
        line(10, 9, 13, 15);
      case _Mark.beads:
        for (var i = 0; i < 11; i++) {
          final a = -math.pi / 2 + i * math.pi * 2 / 12;
          circle(11 + math.cos(a) * 7, 10 + math.sin(a) * 7, 1.65);
        }
        line(16, 16, 18, 19);
        path(
          Path()
            ..moveTo(17, 19)
            ..lineTo(16, 22)
            ..moveTo(18, 19)
            ..lineTo(19, 22)
            ..moveTo(19, 18)
            ..lineTo(22, 20),
        );
      case _Mark.bookmark:
      case _Mark.bookmarkFilled:
        final p = Path()
          ..moveTo(6, 3)
          ..lineTo(18, 3)
          ..lineTo(18, 21)
          ..lineTo(12, 17)
          ..lineTo(6, 21)
          ..close();
        if (mark == _Mark.bookmarkFilled) {
          canvas.drawPath(
            p,
            Paint()..color = color.withValues(alpha: color.a * .24),
          );
        }
        path(p);
        path(
          Path()
            ..moveTo(12, 6)
            ..lineTo(14.5, 9)
            ..lineTo(12, 12)
            ..lineTo(9.5, 9)
            ..close(),
        );
      case _Mark.notes:
        box(4, 3, 13, 18);
        line(7, 7, 13, 7);
        line(7, 11, 12, 11);
        path(
          Path()
            ..moveTo(12, 18)
            ..lineTo(13, 14)
            ..lineTo(20, 7)
            ..lineTo(22, 9)
            ..lineTo(15, 16)
            ..close(),
        );
      case _Mark.language:
        circle(9, 9, 6.5);
        canvas.drawOval(const Rect.fromLTWH(6, 2.5, 6, 13), ink);
        line(2.5, 9, 15.5, 9);
        path(
          Path()
            ..moveTo(13, 22)
            ..lineTo(17, 12)
            ..lineTo(21, 22)
            ..moveTo(14.5, 18.5)
            ..lineTo(19.5, 18.5),
        );
      case _Mark.download:
      case _Mark.upload:
        arch(3, 3, 18, 21);
        line(3, 21, 21, 21);
        line(7, 18, 17, 18);
        if (mark == _Mark.download) {
          line(12, 7, 12, 15);
          path(
            Path()
              ..moveTo(8.5, 11.5)
              ..lineTo(12, 15)
              ..lineTo(15.5, 11.5),
          );
        } else {
          line(12, 7, 12, 15);
          path(
            Path()
              ..moveTo(8.5, 10.5)
              ..lineTo(12, 7)
              ..lineTo(15.5, 10.5),
          );
        }
      case _Mark.calendar:
        box(3, 5, 18, 16, 2);
        line(7, 3, 7, 7);
        line(17, 3, 17, 7);
        line(3, 10, 21, 10);
        star(12, 15.5, 3.2);
      case _Mark.journal:
        box(4, 3, 16, 18, 1.5);
        line(8, 3, 8, 21);
        path(
          Path()
            ..moveTo(11, 12)
            ..lineTo(13, 14)
            ..lineTo(17, 9),
        );
        line(11, 17, 17, 17);
      case _Mark.moon:
        moon();
        circle(19, 5, 1, solid: true);
      case _Mark.sun:
        circle(12, 12, 4.5);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          line(
            12 + 7 * math.cos(a),
            12 + 7 * math.sin(a),
            12 + 10 * math.cos(a),
            12 + 10 * math.sin(a),
          );
        }
      case _Mark.sunrise:
      case _Mark.sunset:
        canvas.drawArc(
          const Rect.fromLTWH(6, 10, 12, 12),
          math.pi,
          math.pi,
          false,
          ink,
        );
        line(2, 17, 22, 17);
        line(5, 21, 19, 21);
        line(3, 9, 5, 11);
        line(19, 11, 21, 9);
        line(12, 2, 12, 7);
        path(
          mark == _Mark.sunrise
              ? (Path()
                  ..moveTo(9, 5)
                  ..lineTo(12, 2)
                  ..lineTo(15, 5))
              : (Path()
                  ..moveTo(9, 4)
                  ..lineTo(12, 7)
                  ..lineTo(15, 4)),
        );
      case _Mark.lantern:
        circle(12, 3, 1.5);
        path(
          Path()
            ..moveTo(6, 8)
            ..lineTo(9, 5)
            ..lineTo(15, 5)
            ..lineTo(18, 8)
            ..lineTo(17, 18)
            ..lineTo(12, 22)
            ..lineTo(7, 18)
            ..close(),
        );
        line(6, 8, 18, 8);
        line(7, 18, 17, 18);
        path(
          Path()
            ..moveTo(12, 10)
            ..lineTo(14, 14)
            ..lineTo(12, 17)
            ..lineTo(10, 14)
            ..close(),
        );
      case _Mark.dua:
        path(
          Path()
            ..moveTo(3, 20)
            ..lineTo(3, 11)
            ..quadraticBezierTo(3, 9, 5, 11)
            ..lineTo(8, 15)
            ..moveTo(3, 20)
            ..lineTo(10, 21)
            ..lineTo(10, 17)
            ..lineTo(7, 13)
            ..moveTo(21, 20)
            ..lineTo(21, 11)
            ..quadraticBezierTo(21, 9, 19, 11)
            ..lineTo(16, 15)
            ..moveTo(21, 20)
            ..lineTo(14, 21)
            ..lineTo(14, 17)
            ..lineTo(17, 13),
        );
        star(12, 6, 3.5);
      case _Mark.fasting:
        path(
          Path()
            ..moveTo(3, 14)
            ..quadraticBezierTo(4, 21, 12, 21)
            ..quadraticBezierTo(20, 21, 21, 14)
            ..close(),
        );
        line(7, 23, 17, 23);
        path(
          Path()
            ..moveTo(11, 2)
            ..cubicTo(5, 2, 5, 10, 11, 10)
            ..cubicTo(8, 7, 8, 5, 11, 2),
        );
        circle(17, 6, 1, solid: true);
        line(5, 11, 6, 12);
        line(17, 11, 16, 12);
      case _Mark.names:
        star(12, 12, 10);
        path(
          Path()
            ..moveTo(12, 6)
            ..cubicTo(18, 10, 18, 14, 12, 18)
            ..cubicTo(6, 14, 6, 10, 12, 6)
            ..close(),
        );
        line(12, 10, 12, 14);
      case _Mark.goal:
        arch(3, 2, 18, 21);
        line(3, 21, 21, 21);
        path(
          Path()
            ..moveTo(7, 17)
            ..lineTo(10, 13)
            ..lineTo(13, 15)
            ..lineTo(18, 9),
        );
        path(
          Path()
            ..moveTo(14, 9)
            ..lineTo(18, 9)
            ..lineTo(18, 13),
        );
      case _Mark.award:
        star(12, 9, 6.5);
        path(
          Path()
            ..moveTo(7, 14)
            ..lineTo(5, 22)
            ..lineTo(9, 20)
            ..lineTo(12, 22)
            ..lineTo(12, 16)
            ..moveTo(17, 14)
            ..lineTo(19, 22)
            ..lineTo(15, 20)
            ..lineTo(12, 22),
        );
        circle(12, 9, 2);
      case _Mark.settings:
        star(12, 12, 10);
        circle(12, 12, 4);
        circle(12, 12, 1, solid: true);
      case _Mark.tune:
        line(5, 3, 5, 9);
        line(5, 13, 5, 21);
        line(12, 3, 12, 14);
        line(12, 18, 12, 21);
        line(19, 3, 19, 5);
        line(19, 9, 19, 21);
        circle(5, 11, 2);
        circle(12, 16, 2);
        circle(19, 7, 2);
      case _Mark.location:
      case _Mark.locationOff:
        path(
          Path()
            ..moveTo(12, 22)
            ..cubicTo(9, 17, 4, 13, 4, 9)
            ..cubicTo(4, -1, 20, -1, 20, 9)
            ..cubicTo(20, 13, 15, 17, 12, 22)
            ..close(),
        );
        arch(9, 5, 6, 12);
        line(9, 12, 15, 12);
        if (mark == _Mark.locationOff) line(3, 3, 21, 21);
      case _Mark.target:
        circle(12, 12, 7);
        circle(12, 12, 2.5);
        line(12, 1, 12, 5);
        line(12, 19, 12, 23);
        line(1, 12, 5, 12);
        line(19, 12, 23, 12);
      case _Mark.clock:
        circle(12, 12, 9.5);
        line(12, 6, 12, 12);
        line(12, 12, 16, 14);
        circle(12, 12, 1, solid: true);
      case _Mark.hourglass:
        line(6, 3, 18, 3);
        line(6, 21, 18, 21);
        path(
          Path()
            ..moveTo(7, 3)
            ..cubicTo(7, 10, 17, 14, 17, 21)
            ..moveTo(17, 3)
            ..cubicTo(17, 10, 7, 14, 7, 21),
        );
        line(10, 18, 14, 18);
      case _Mark.search:
      case _Mark.searchOff:
        circle(10, 10, 6.5);
        line(15, 15, 21, 21);
        if (mark == _Mark.searchOff) {
          line(8, 8, 12, 12);
          line(8, 12, 12, 8);
        }
      case _Mark.heart:
      case _Mark.heartFilled:
        path(
          Path()
            ..moveTo(12, 21)
            ..cubicTo(-7, 8, 7, -3, 12, 7)
            ..cubicTo(17, -3, 31, 8, 12, 21)
            ..close(),
          solid: mark == _Mark.heartFilled,
        );
      case _Mark.shield:
        path(
          Path()
            ..moveTo(12, 2)
            ..quadraticBezierTo(7, 5, 3, 5)
            ..lineTo(4, 14)
            ..quadraticBezierTo(5, 19, 12, 22)
            ..quadraticBezierTo(19, 19, 20, 14)
            ..lineTo(21, 5)
            ..quadraticBezierTo(17, 5, 12, 2)
            ..close(),
        );
        check();
      case _Mark.lock:
        arch(7, 2, 10, 11);
        box(4, 10, 16, 12, 2);
        circle(12, 15, 1.4);
        line(12, 16.5, 12, 18);
      case _Mark.garden:
        line(12, 22, 12, 7);
        path(
          Path()
            ..moveTo(12, 15)
            ..cubicTo(4, 15, 3, 10, 4, 7)
            ..cubicTo(9, 7, 12, 10, 12, 15)
            ..moveTo(12, 10)
            ..cubicTo(12, 5, 16, 3, 20, 3)
            ..cubicTo(21, 8, 18, 11, 12, 10),
        );
        line(7, 22, 17, 22);
      case _Mark.travel:
        path(
          Path()
            ..moveTo(2, 15)
            ..lineTo(22, 9)
            ..lineTo(20, 7)
            ..lineTo(13, 9)
            ..lineTo(7, 3)
            ..lineTo(5, 4)
            ..lineTo(8, 11)
            ..lineTo(4, 12)
            ..lineTo(2, 10)
            ..lineTo(1, 11)
            ..close(),
        );
        line(3, 21, 21, 21);
      case _Mark.people:
        circle(9, 7, 3);
        path(
          Path()
            ..moveTo(3, 21)
            ..lineTo(3, 17)
            ..cubicTo(3, 10, 15, 10, 15, 17)
            ..lineTo(15, 21)
            ..close(),
        );
        path(
          Path()
            ..moveTo(16, 4)
            ..cubicTo(21, 4, 21, 10, 16, 10)
            ..moveTo(18, 13)
            ..quadraticBezierTo(22, 14, 22, 18)
            ..lineTo(22, 21),
        );
      case _Mark.city:
        arch(3, 4, 7, 21);
        arch(13, 1.5, 8, 21);
        line(2, 21, 22, 21);
        line(6, 11, 7, 11);
        line(6, 15, 7, 15);
        line(16, 10, 18, 10);
        line(16, 14, 18, 14);
      case _Mark.folder:
        path(
          Path()
            ..moveTo(2, 20)
            ..lineTo(2, 5)
            ..lineTo(9, 5)
            ..lineTo(12, 8)
            ..lineTo(21, 8)
            ..lineTo(21, 11)
            ..moveTo(2, 20)
            ..lineTo(6, 11)
            ..lineTo(23, 11)
            ..lineTo(19, 20)
            ..close(),
        );
      case _Mark.memory:
        arch(4, 2, 16, 21);
        line(4, 21, 20, 21);
        star(12, 11, 4);
        line(9, 18, 15, 18);
      case _Mark.audio:
        for (var i = 0; i < 5; i++) {
          final h = [5.0, 11.0, 18.0, 11.0, 5.0][i];
          line(4 + i * 4, 12 - h / 2, 4 + i * 4, 12 + h / 2);
        }
      case _Mark.voice:
        box(9, 2, 6, 13, 3);
        path(
          Path()
            ..moveTo(6, 10)
            ..lineTo(6, 13)
            ..cubicTo(6, 21, 18, 21, 18, 13)
            ..lineTo(18, 10),
        );
        line(12, 19, 12, 23);
        line(9, 23, 15, 23);
      case _Mark.bell:
      case _Mark.bellActive:
        path(
          Path()
            ..moveTo(5, 16)
            ..lineTo(6, 9)
            ..cubicTo(6, 3, 18, 3, 18, 9)
            ..lineTo(19, 16)
            ..lineTo(21, 18)
            ..lineTo(3, 18)
            ..close(),
        );
        line(12, 2, 12, 4);
        path(
          Path()
            ..moveTo(9, 21)
            ..quadraticBezierTo(12, 23, 15, 21),
        );
        if (mark == _Mark.bellActive) {
          line(2, 5, 1, 9);
          line(22, 5, 23, 9);
        }
      case _Mark.flame:
        path(
          Path()
            ..moveTo(13, 2)
            ..cubicTo(15, 9, 20, 10, 20, 15)
            ..cubicTo(20, 24, 4, 24, 4, 15)
            ..quadraticBezierTo(4, 10, 8, 8)
            ..quadraticBezierTo(6, 13, 10, 13)
            ..quadraticBezierTo(15, 11, 13, 2)
            ..close(),
        );
      case _Mark.picture:
        box(3, 3, 18, 18, 2);
        circle(16, 8, 2);
        path(
          Path()
            ..moveTo(3, 17)
            ..lineTo(9, 11)
            ..lineTo(15, 17)
            ..lineTo(18, 14)
            ..lineTo(21, 17),
        );
      case _Mark.layout:
        box(3, 3, 18, 7, 1);
        box(3, 14, 18, 7, 1);
      case _Mark.list:
        line(4, 5, 20, 5);
        line(4, 12, 20, 12);
        line(4, 19, 15, 19);
      case _Mark.textSize:
        line(3, 5, 21, 5);
        line(12, 5, 12, 21);
        line(8, 21, 16, 21);
        line(3, 5, 3, 8);
        line(21, 5, 21, 8);
      case _Mark.play:
        path(
          Path()
            ..moveTo(8, 3.5)
            ..lineTo(21, 12)
            ..lineTo(8, 20.5)
            ..close(),
          solid: true,
        );
      case _Mark.pause:
        box(6, 4, 3, 16, .5);
        box(15, 4, 3, 16, .5);
      case _Mark.next:
        path(
          Path()
            ..moveTo(5, 4)
            ..lineTo(16, 12)
            ..lineTo(5, 20)
            ..close(),
          solid: true,
        );
        line(19, 4, 19, 20);
      case _Mark.previous:
        path(
          Path()
            ..moveTo(19, 4)
            ..lineTo(8, 12)
            ..lineTo(19, 20)
            ..close(),
          solid: true,
        );
        line(5, 4, 5, 20);
      case _Mark.repeat:
        path(
          Path()
            ..moveTo(4, 10)
            ..lineTo(4, 6)
            ..lineTo(20, 6)
            ..moveTo(17, 3)
            ..lineTo(20, 6)
            ..lineTo(17, 9)
            ..moveTo(20, 14)
            ..lineTo(20, 18)
            ..lineTo(4, 18)
            ..moveTo(7, 15)
            ..lineTo(4, 18)
            ..lineTo(7, 21),
        );
      case _Mark.speed:
        canvas.drawArc(
          const Rect.fromLTWH(3, 4, 18, 18),
          math.pi * .85,
          math.pi * 1.3,
          false,
          ink,
        );
        line(12, 13, 17, 8);
        circle(12, 13, 1.5);
        line(7, 21, 17, 21);
      case _Mark.refresh:
        canvas.drawArc(
          const Rect.fromLTWH(4, 4, 16, 16),
          -math.pi * .9,
          math.pi * 1.7,
          false,
          ink,
        );
        path(
          Path()
            ..moveTo(3, 3)
            ..lineTo(3, 9)
            ..lineTo(9, 9),
        );
      case _Mark.undo:
        path(
          Path()
            ..moveTo(3, 9)
            ..lineTo(13, 9)
            ..cubicTo(23, 9, 23, 20, 14, 20)
            ..lineTo(10, 20)
            ..moveTo(8, 4)
            ..lineTo(3, 9)
            ..lineTo(8, 14),
        );
      case _Mark.back:
        line(3, 12, 21, 12);
        path(
          Path()
            ..moveTo(10, 5)
            ..lineTo(3, 12)
            ..lineTo(10, 19),
        );
      case _Mark.forward:
        line(3, 12, 21, 12);
        path(
          Path()
            ..moveTo(14, 5)
            ..lineTo(21, 12)
            ..lineTo(14, 19),
        );
      case _Mark.chevronLeft:
        path(
          Path()
            ..moveTo(15, 5)
            ..lineTo(8, 12)
            ..lineTo(15, 19),
        );
      case _Mark.chevronRight:
        path(
          Path()
            ..moveTo(9, 5)
            ..lineTo(16, 12)
            ..lineTo(9, 19),
        );
      case _Mark.down:
        path(
          Path()
            ..moveTo(5, 9)
            ..lineTo(12, 16)
            ..lineTo(19, 9),
        );
      case _Mark.up:
        path(
          Path()
            ..moveTo(5, 15)
            ..lineTo(12, 8)
            ..lineTo(19, 15),
        );
      case _Mark.outward:
        line(5, 19, 19, 5);
        path(
          Path()
            ..moveTo(7, 5)
            ..lineTo(19, 5)
            ..lineTo(19, 17),
        );
      case _Mark.close:
        line(5, 5, 19, 19);
        line(19, 5, 5, 19);
      case _Mark.add:
        line(12, 4, 12, 20);
        line(4, 12, 20, 12);
      case _Mark.remove:
        line(4, 12, 20, 12);
      case _Mark.check:
        check();
      case _Mark.checkCircle:
        circle(12, 12, 9.5);
        check();
      case _Mark.info:
        circle(12, 12, 9.5);
        circle(12, 7, 1, solid: true);
        line(12, 11, 12, 18);
      case _Mark.error:
        circle(12, 12, 9.5);
        circle(12, 17, 1, solid: true);
        line(12, 6, 12, 13);
      case _Mark.more:
        for (final x in [5.0, 12.0, 19.0]) {
          circle(x, 12, 1.25, solid: true);
        }
      case _Mark.copy:
        box(8, 7, 13, 15, 1.5);
        path(
          Path()
            ..moveTo(5, 18)
            ..lineTo(3, 18)
            ..lineTo(3, 2)
            ..lineTo(16, 2)
            ..lineTo(16, 4),
        );
      case _Mark.share:
        path(
          Path()
            ..moveTo(5, 11)
            ..lineTo(5, 21)
            ..lineTo(19, 21)
            ..lineTo(19, 11)
            ..moveTo(7, 7)
            ..lineTo(12, 2)
            ..lineTo(17, 7)
            ..moveTo(12, 2)
            ..lineTo(12, 15),
        );
      case _Mark.delete:
        path(
          Path()
            ..moveTo(5, 7)
            ..lineTo(6, 21)
            ..lineTo(18, 21)
            ..lineTo(19, 7),
        );
        line(3, 7, 21, 7);
        path(
          Path()
            ..moveTo(8, 7)
            ..lineTo(8, 3)
            ..lineTo(16, 3)
            ..lineTo(16, 7),
        );
        line(10, 11, 10, 17);
        line(14, 11, 14, 17);
      case _Mark.eye:
      case _Mark.eyeOff:
        path(
          Path()
            ..moveTo(2, 12)
            ..quadraticBezierTo(12, -1, 22, 12)
            ..quadraticBezierTo(12, 25, 2, 12)
            ..close(),
        );
        circle(12, 12, 3);
        if (mark == _Mark.eyeOff) line(3, 3, 21, 21);
      case _Mark.hash:
        line(9, 3, 7, 21);
        line(17, 3, 15, 21);
        line(3, 8, 22, 8);
        line(2, 16, 21, 16);
      case _Mark.infinity:
        path(
          Path()
            ..moveTo(12, 12)
            ..cubicTo(-1, -3, -1, 27, 12, 12)
            ..cubicTo(25, -3, 25, 27, 12, 12),
        );
      case _Mark.flag:
        line(5, 3, 5, 22);
        path(
          Path()
            ..moveTo(5, 4)
            ..quadraticBezierTo(9, 1, 13, 4)
            ..quadraticBezierTo(17, 7, 21, 4)
            ..lineTo(21, 14)
            ..quadraticBezierTo(17, 17, 13, 14)
            ..quadraticBezierTo(9, 11, 5, 14),
        );
      case _Mark.calculator:
        box(4, 2, 16, 20, 2);
        box(7, 5, 10, 4, .5);
        line(8, 13, 8, 17);
        line(6, 15, 10, 15);
        line(14, 14, 17, 14);
        line(14, 17, 17, 17);
      case _Mark.storage:
        box(3, 3, 18, 6, 1);
        box(3, 15, 18, 6, 1);
        circle(7, 6, .7, solid: true);
        circle(7, 18, .7, solid: true);
        line(11, 6, 18, 6);
        line(11, 18, 18, 18);
      case _Mark.drag:
        line(5, 9, 19, 9);
        line(5, 15, 19, 15);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AppIconPainter old) =>
      old.mark != mark ||
      old.color != color ||
      old.mirror != mirror ||
      old.strokeWidth != strokeWidth;
}
