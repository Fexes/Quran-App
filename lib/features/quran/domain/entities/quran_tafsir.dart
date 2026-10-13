import 'dart:ui' show TextAlign, TextDirection;

import 'package:equatable/equatable.dart';

class QuranTafsirResource extends Equatable {
  const QuranTafsirResource({
    required this.id,
    required this.languageName,
    required this.name,
    required this.authorName,
    required this.slug,
  });

  factory QuranTafsirResource.fromJson(Map<dynamic, dynamic> json) {
    return QuranTafsirResource(
      id: _int(json['id']),
      languageName: _string(json['languageName'] ?? json['language_name']),
      name: _string(json['name']),
      authorName: _string(json['authorName'] ?? json['author_name']),
      slug: _string(json['slug']),
    );
  }

  final int id;
  final String languageName;
  final String name;
  final String authorName;
  final String slug;

  String get displayLanguage {
    if (languageName.isEmpty) {
      return '';
    }
    return languageName
        .split(RegExp(r'\s+'))
        .map((part) {
          if (part.isEmpty) {
            return part;
          }
          return '${part[0].toUpperCase()}${part.substring(1)}';
        })
        .join(' ');
  }

  bool get isRtl {
    final tokens = _languageTokens(languageName);
    return tokens.any(_rtlLanguageTokens.contains);
  }

  TextDirection get textDirection {
    return isRtl ? TextDirection.rtl : TextDirection.ltr;
  }

  TextAlign get textAlign {
    return isRtl ? TextAlign.right : TextAlign.left;
  }

  Map<String, Object> toJson() {
    return {
      'id': id,
      'languageName': languageName,
      'name': name,
      'authorName': authorName,
      'slug': slug,
    };
  }

  @override
  List<Object> get props => [id, languageName, name, authorName, slug];
}

class QuranTafsirResult extends Equatable {
  const QuranTafsirResult({
    required this.resource,
    required this.verseKey,
    required this.text,
  });

  final QuranTafsirResource resource;
  final String verseKey;
  final String text;

  @override
  List<Object> get props => [resource, verseKey, text];
}

class QuranTafsirDownloadProgress extends Equatable {
  const QuranTafsirDownloadProgress({
    required this.completedVerses,
    required this.totalVerses,
    this.isComplete = false,
    this.failed = false,
    this.unavailableVerses = 0,
    this.errorMessage,
  });

  final int completedVerses;
  final int totalVerses;
  final bool isComplete;
  final bool failed;
  final int unavailableVerses;
  final String? errorMessage;

  double get percent {
    if (totalVerses <= 0) {
      return 0;
    }
    return (completedVerses / totalVerses).clamp(0, 1).toDouble();
  }

  @override
  List<Object?> get props => [
    completedVerses,
    totalVerses,
    isComplete,
    failed,
    unavailableVerses,
    errorMessage,
  ];
}

class QuranCachedTafsirVerse extends Equatable {
  const QuranCachedTafsirVerse({
    required this.resourceId,
    required this.verseKey,
    required this.text,
    this.resourceName,
    this.languageName,
  });

  final int resourceId;
  final String verseKey;
  final String text;
  final String? resourceName;
  final String? languageName;

  @override
  List<Object?> get props => [
    resourceId,
    verseKey,
    text,
    resourceName,
    languageName,
  ];
}

Set<String> quranTafsirLanguageTokens(String languageName) {
  return _languageTokens(languageName);
}

Set<String> _languageTokens(String languageName) {
  return languageName
      .toLowerCase()
      .split(RegExp(r'[^a-z]+'))
      .where((token) => token.isNotEmpty)
      .toSet();
}

const _rtlLanguageTokens = {
  'arabic',
  'urdu',
  'persian',
  'farsi',
  'pashto',
  'dari',
  'sindhi',
  'uighur',
  'uyghur',
  'hebrew',
  'kurdish',
};

String _string(Object? value) => value is String ? value : '';

int _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}
