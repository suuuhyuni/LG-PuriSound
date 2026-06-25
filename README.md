# LG PuriSound Flutter Prototype

AI 기반 층간소음 마스킹 디바이스 컨트롤러 앱의 Flutter 프로토타입입니다.

## 실행

Flutter SDK 설치 후 실행합니다.

```bash
flutter create . --platforms=ios,android
flutter pub get
flutter run
```

현재 작업 환경에는 `flutter` 및 `dart` 명령이 없어 빌드 검증은 수행하지 못했습니다.

## YAMNet / 사운드 측정 연동

앱 UI는 `lib/services/audio_intelligence_service.dart`의 `AudioIntelligenceService`를 통해 소리 분석 결과를 받습니다.

현재는 `MockAudioIntelligenceService`가 dB, 대표 주파수, 분류 라벨, 마스킹 타입을 스트림으로 내보냅니다. 실제 연동 시에는 `YamnetAudioIntelligenceService`를 구현해서 같은 `AudioInsight`를 emit하면 됩니다.

권장 파이프라인:

1. 마이크에서 16 kHz mono PCM을 수집합니다.
2. 사운드 측정 모델 또는 RMS 계산으로 dB 값을 산출합니다.
3. 0.975초 단위 오디오 frame을 YAMNet TFLite 모델에 넣습니다.
4. YAMNet label과 주파수/지속시간 heuristic을 합쳐 `NoiseMaskingType`으로 매핑합니다.
5. `AudioInsight`를 Home, Monitor, Report로 전달합니다.
6. `shouldMask == true`이면 PuriSound Speaker API로 노이즈 타입과 음량을 전송합니다.

마스킹 매핑 기준:

- 저주파 충격음, footstep, thump, knock, 120 Hz 이하: Brown Noise
- traffic, vehicle, engine, air conditioner: Pink Noise
- speech, conversation, television, 분류 불가 생활음: White Noise

실제 모델 패키지는 Flutter SDK 설치 후 `tflite_flutter`, 마이크 캡처 패키지, 권한 처리 패키지를 추가해서 연결하면 됩니다.
