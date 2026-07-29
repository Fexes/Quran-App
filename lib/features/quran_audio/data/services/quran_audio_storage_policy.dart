import 'package:flutter/services.dart';

class QuranAudioStoragePolicy {
  const QuranAudioStoragePolicy._();

  static const MethodChannel _channel = MethodChannel('quran/audio_storage');

  static Future<void> excludeFromBackup(String path) async {
    try {
      await _channel.invokeMethod<void>('excludeFromBackup', {'path': path});
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
