import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/data/services/surah_cover_cache.dart';

void main() {
  test('downloads a cover once and reuses the cached file', () async {
    var requestCount = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final subscription = server.listen((request) async {
      requestCount += 1;
      request.response.headers.contentType = ContentType('image', 'jpeg');
      request.response.add(const [1, 2, 3, 4]);
      await request.response.close();
    });
    final directory = await Directory.systemTemp.createTemp(
      'surah_cover_cache_test_',
    );
    addTearDown(() async {
      await subscription.cancel();
      await server.close(force: true);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final cache = SurahCoverCache(
      directoryProvider: () async => directory,
      imageUrlBuilder: (surahNumber) =>
          'http://${server.address.host}:${server.port}/cover_$surahNumber.jpeg',
    );

    final first = await cache.fileFor(7);
    final second = await cache.fileFor(7);

    expect(first, isNotNull);
    expect(second?.path, first?.path);
    expect(await first!.readAsBytes(), const [1, 2, 3, 4]);
    expect(requestCount, 1);
  });
}
