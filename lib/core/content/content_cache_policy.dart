import 'package:equatable/equatable.dart';

enum ContentCacheRetention { bundled, sessionOnly, expiring, userOwned }

class ContentCachePolicy extends Equatable {
  const ContentCachePolicy({
    required this.retention,
    this.maxAge,
    this.policyUrl,
  }) : assert(
         retention != ContentCacheRetention.expiring || maxAge != null,
         'Expiring content requires a maximum age.',
       );

  static const quranFoundation = ContentCachePolicy(
    retention: ContentCacheRetention.expiring,
    maxAge: Duration(days: 7),
    policyUrl: 'https://api-docs.quran.foundation/legal/developer-terms/',
  );

  static const bundled = ContentCachePolicy(
    retention: ContentCacheRetention.bundled,
  );

  static const userOwned = ContentCachePolicy(
    retention: ContentCacheRetention.userOwned,
  );

  final ContentCacheRetention retention;
  final Duration? maxAge;
  final String? policyUrl;

  bool isValid({DateTime? fetchedAt, DateTime? now}) {
    switch (retention) {
      case ContentCacheRetention.bundled:
      case ContentCacheRetention.userOwned:
        return true;
      case ContentCacheRetention.sessionOnly:
        return false;
      case ContentCacheRetention.expiring:
        final fetched = fetchedAt;
        final allowedAge = maxAge;
        if (fetched == null || allowedAge == null) {
          return false;
        }
        final current = now ?? DateTime.now();
        if (fetched.isAfter(current)) {
          return false;
        }
        return current.difference(fetched) <= allowedAge;
    }
  }

  DateTime? expiresAt(DateTime? fetchedAt) {
    final allowedAge = maxAge;
    if (fetchedAt == null || allowedAge == null) {
      return null;
    }
    return fetchedAt.add(allowedAge);
  }

  Map<String, Object?> toJson() {
    return {
      'retention': retention.name,
      if (maxAge != null) 'maxAgeSeconds': maxAge!.inSeconds,
      if (policyUrl != null) 'policyUrl': policyUrl,
    };
  }

  @override
  List<Object?> get props => [retention, maxAge, policyUrl];
}
