# Library Source Directory (`lib`)

This directory contains the entire source code for the **Bustan Al-Nahw** (بستان النحو العربي) educational Flutter application.

## Subdirectories:
- [theme](file:///C:/Users/moham/Desktop/aze2/lib/theme): Material 3 educational theme, Arabic Cairo typography, and syntax color palettes.
- [models](file:///C:/Users/moham/Desktop/aze2/lib/models): Data structures for tokens, activities, lessons, quizzes, grades, and progress.
- [data](file:///C:/Users/moham/Desktop/aze2/lib/data): Complete textbook curricula for Grades 3, 4, and 5 aligned with `tasks.md`.
- [nlp](file:///C:/Users/moham/Desktop/aze2/lib/nlp): Arabic Computational Linguistics Engine (morpho-syntactic parser, automated diacritizer, grammar checker, and feedback generator).
- [services](file:///C:/Users/moham/Desktop/aze2/lib/services): Persistence and state management for scores, stars, and user preferences.
- [widgets](file:///C:/Users/moham/Desktop/aze2/lib/widgets): Reusable UI components including interactive sentence parsers, grammatical badges, and feedback dialogs.
- [screens](file:///C:/Users/moham/Desktop/aze2/lib/screens): The 9 specified screens matching `tasks.md` plus the Computational Linguistics Lab.

## Root Files:
- [main.dart](file:///C:/Users/moham/Desktop/aze2/lib/main.dart): Application entry point, initializing services, setting RTL directionality, and launching `HomeScreen`.
