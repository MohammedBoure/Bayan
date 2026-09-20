# Services Directory (`lib/services`)

This directory contains application services handling persistence, progress tracking, local database caching, hardware display adaptations, and user feedback loops.

## Files:
- [progress_service.dart](file:///C:/Users/moham/Desktop/Bayan/lib/services/progress_service.dart): Implements `ProgressService` (`ChangeNotifier`) managing active session state and persistent classroom presentation preferences (general app/UI scaling `uiScale`, educational font scaling `fontSizeScale`, hardware display profiles for Laptops/Desktops/SmartBoards/DataShow, sound toggles, tashkeel preferences, teacher classroom presentation mode, font family preferences, timer duration, spotlight reading). Ensures clean, stateless curriculum navigation across launches and provides `resetSettingsToDefault()`.
- [nlp_database_service.dart](file:///C:/Users/moham/Desktop/Bayan/lib/services/nlp_database_service.dart): Local SQLite database service providing fast lookup caching for analyzed sentences, pre-seeded elementary curriculum datasets, and the user correction feedback loop (`Override Priority`).
- [audio_player_service.dart](file:///C:/Users/moham/Desktop/Bayan/lib/services/audio_player_service.dart): Lightweight Windows native audio playback service utilizing `winmm.dll` (`mciSendStringW`) via `dart:ffi`. Provides zero-dependency, offline playback, pausing, resuming, seeking, position tracking, and paragraph synchronization for curriculum reading passages.

