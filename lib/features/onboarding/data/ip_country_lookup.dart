import 'dart:convert';
import 'dart:io';

/// Country only: precise coordinates are never sent to the IP service.
Future<String?> lookupIpCountry() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
  try {
    return await (() async {
      final request = await client.getUrl(Uri.https('api.country.is', '/'));
      request.followRedirects = false;
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) return null;
      final bytes = <int>[];
      await for (final chunk in response) {
        if (bytes.length + chunk.length > 2048) return null;
        bytes.addAll(chunk);
      }
      final data = jsonDecode(utf8.decode(bytes));
      if (data is! Map || data['country'] is! String) return null;
      final country = (data['country'] as String).trim().toUpperCase();
      return RegExp(r'^[A-Z]{2}$').hasMatch(country) && country != 'ZZ'
          ? country
          : null;
    })().timeout(const Duration(seconds: 4));
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
