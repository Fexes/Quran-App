import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class LocaleState extends Equatable {
  const LocaleState({required this.locale, this.followSystem = false});

  final Locale locale;
  final bool followSystem;

  Locale? get appLocale => followSystem ? null : locale;
  String get preferenceCode => followSystem ? 'system' : locale.languageCode;

  LocaleState copyWith({Locale? locale, bool? followSystem}) {
    return LocaleState(
      locale: locale ?? this.locale,
      followSystem: followSystem ?? this.followSystem,
    );
  }

  @override
  List<Object> get props => [locale, followSystem];
}
