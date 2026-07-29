import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../entities/quran_audio_queue_item.dart';
import '../entities/quran_word_timing.dart';

abstract interface class QuranWordTimingRepository {
  Future<QuranWordTimingResult> timingsFor({
    required QuranAudioReciter reciter,
    required QuranAudioQueueItem item,
  });
}
