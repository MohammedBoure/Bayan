# Services Directory (`lib/services`)

This directory contains application services handling persistence, progress tracking, local database caching, and user feedback loops.

## Files:
- [progress_service.dart](file:///C:/Users/moham/Desktop/aze2/lib/services/progress_service.dart): Implements `ProgressService` (`ChangeNotifier`) for storing completed lessons, stars earned, evaluation quiz scores, sound toggles, tashkeel preferences, teacher classroom presentation mode (`teacherModeEnabled`, `revealAnswersDirectly`, `timerDuration`, `spotlightReading`, `nlpAutoAnalysis`), font family preferences (`selectedFontFamily`), and reset capabilities using `SharedPreferences`.
- [nlp_database_service.dart](file:///C:/Users/moham/Desktop/aze2/lib/services/nlp_database_service.dart): Local SQLite database service providing fast lookup caching for analyzed sentences, pre-seeded elementary curriculum datasets, and the user correction feedback loop (`Override Priority`).
