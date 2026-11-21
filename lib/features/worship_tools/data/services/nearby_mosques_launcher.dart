import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a map application's own nearby search without reading device location.
abstract final class NearbyMosquesLauncher {
  static const _channel = MethodChannel('quran/external_maps');
  static const _query = 'mosques near me';

  static Future<bool> open() async {
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          if (await _channel.invokeMethod<bool>('openGoogleMapsMosques') ==
              true) {
            return true;
          }
        } catch (_) {
          // Missing or unavailable native handlers continue to the web fallback.
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final googleMaps = Uri(
          scheme: 'comgooglemaps',
          host: '',
          // Non-HTTP app schemes need percent-encoded spaces rather than '+'.
          query: 'q=${Uri.encodeComponent(_query)}',
        );
        try {
          if (await canLaunchUrl(googleMaps) &&
              await _launch(googleMaps, LaunchMode.externalApplication)) {
            return true;
          }
        } catch (_) {
          // Google Maps may not be installed or may reject its URL scheme.
        }
        if (await _openAppleMaps()) return true;
      }
    }

    return _launch(
      Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': _query,
      }),
      LaunchMode.externalApplication,
    );
  }

  static Future<bool> _openAppleMaps() async {
    // Universal-link-only mode requires an installed app to handle these URLs;
    // a browser must not prematurely satisfy the Apple Maps fallback step.
    if (await _launch(
      Uri.https('maps.apple.com', '/search', {'query': 'mosques'}),
      LaunchMode.externalNonBrowserApplication,
    )) {
      return true;
    }
    return _launch(
      Uri.https('maps.apple.com', '/', {'q': _query}),
      LaunchMode.externalNonBrowserApplication,
    );
  }

  static Future<bool> _launch(Uri uri, LaunchMode mode) async {
    try {
      return await launchUrl(uri, mode: mode);
    } catch (_) {
      return false;
    }
  }
}
