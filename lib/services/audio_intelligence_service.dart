part of hrgg_app;

enum NoiseMaskingType { brown, pink, white, unknown }

class AudioInsight {
  const AudioInsight({
    required this.db,
    required this.frequencyHz,
    required this.label,
    required this.maskingType,
    required this.confidence,
    required this.shouldMask,
  });

  final double db;
  final double frequencyHz;
  final String label;
  final NoiseMaskingType maskingType;
  final double confidence;
  final bool shouldMask;

  Color get color {
    return switch (maskingType) {
      NoiseMaskingType.brown => HrggColors.brownNoise,
      NoiseMaskingType.pink => HrggColors.pinkNoise,
      NoiseMaskingType.white => HrggColors.whiteNoise,
      NoiseMaskingType.unknown => HrggColors.whiteNoise,
    };
  }

  String get maskingLabel {
    return switch (maskingType) {
      NoiseMaskingType.brown => '브라운 노이즈',
      NoiseMaskingType.pink => '핑크 노이즈',
      NoiseMaskingType.white => '화이트 노이즈',
      NoiseMaskingType.unknown => '화이트 노이즈',
    };
  }
}

abstract class AudioIntelligenceService {
  Stream<AudioInsight> get insights;
  Future<void> start();
  Future<void> stop();
}

class MockAudioIntelligenceService implements AudioIntelligenceService {
  @override
  Stream<AudioInsight> get insights async* {
    final samples = [
      const AudioInsight(
          db: 42,
          frequencyHz: 64,
          label: '충격음 감지 · 저주파',
          maskingType: NoiseMaskingType.brown,
          confidence: 0.86,
          shouldMask: true),
      const AudioInsight(
          db: 48,
          frequencyHz: 520,
          label: '교통·실외기 지속음',
          maskingType: NoiseMaskingType.pink,
          confidence: 0.74,
          shouldMask: true),
      const AudioInsight(
          db: 39,
          frequencyHz: 1800,
          label: '생활·대화음',
          maskingType: NoiseMaskingType.white,
          confidence: 0.69,
          shouldMask: false),
    ];
    var i = 0;
    while (true) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      yield samples[i % samples.length];
      i++;
    }
  }

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

class YamnetAudioIntelligenceService implements AudioIntelligenceService {
  @override
  Stream<AudioInsight> get insights {
    // Production path:
    // 1. Capture 16 kHz mono PCM windows from the mic.
    // 2. Feed 0.975 s frames into YAMNet TFLite.
    // 3. Map YAMNet labels to HRGG masking classes.
    // 4. Merge with dB/RMS and low-frequency impact heuristics.
    // 5. Emit AudioInsight to Home/Monitor/Report.
    throw UnimplementedError('Wire this to the platform YAMNet pipeline.');
  }

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  static NoiseMaskingType mapYamnetLabel(String label, double frequencyHz) {
    final normalized = label.toLowerCase();
    if (frequencyHz <= 120 ||
        normalized.contains('thump') ||
        normalized.contains('knock') ||
        normalized.contains('footstep')) {
      return NoiseMaskingType.brown;
    }
    if (normalized.contains('traffic') ||
        normalized.contains('vehicle') ||
        normalized.contains('engine') ||
        normalized.contains('air conditioner')) {
      return NoiseMaskingType.pink;
    }
    if (normalized.contains('speech') ||
        normalized.contains('conversation') ||
        normalized.contains('television')) {
      return NoiseMaskingType.white;
    }
    return NoiseMaskingType.white;
  }
}

class PersistingAudioIntelligenceService implements AudioIntelligenceService {
  PersistingAudioIntelligenceService(this._source);

  final AudioIntelligenceService _source;
  final StreamController<AudioInsight> _controller =
      StreamController<AudioInsight>.broadcast();
  StreamSubscription<AudioInsight>? _subscription;
  DateTime? _lastSavedAt;

  @override
  Stream<AudioInsight> get insights {
    unawaited(start());
    return _controller.stream;
  }

  @override
  Future<void> start() async {
    if (_subscription != null) return;
    await _source.start();
    _subscription = _source.insights.listen((insight) {
      _controller.add(insight);
      final now = DateTime.now();
      final canPersist = _lastSavedAt == null ||
          now.difference(_lastSavedAt!) >= const Duration(seconds: 30);
      if (FirebaseAuth.instance.currentUser != null &&
          canPersist &&
          (insight.shouldMask || insight.db >= 45)) {
        _lastSavedAt = now;
        unawaited(appDataService.recordNoiseEvent(insight).catchError(
              (Object error) => debugPrint('Noise event persistence failed: $error'),
            ));
      }
    }, onError: _controller.addError);
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _source.stop();
  }
}
