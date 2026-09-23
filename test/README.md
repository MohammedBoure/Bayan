# Test Directory (`test`)

This directory contains automated unit and widget test suites for the Arabic Grammar application.

## Files:
- [widget_test.dart](file:///C:/Users/moham/Desktop/Bayan/test/widget_test.dart): Comprehensive automated test suite (25 passing test suites) verifying:
  1. Arabic Clitic Stemming and affixes stripping (`ArabicCliticStemmer`).
  2. Offline Hybrid Arabic Syntactic Parser (`ArabicHybridParser`).
  3. Context-aware bigram analysis distinguishing nouns from verbs.
  4. Extensible curriculum repository dynamic unit/lesson registration.
  5. User correction feedback loop and SQLite persistence overrides.
  6. High-speed database caching and pre-seeded sentence lookups.
  7. Flutter application startup and home screen rendering for classroom projectors.
  8. Grade 3 & Grade 4 authentic curriculum packs structure (5 pedagogical stages, authentic reading texts, interactive word meaning matching, and linguistic enrichment exercises like complementary pairs, morphology derivations, and odd-word-out identification).
  9. Grade 4 Lesson 3 («بين جارين - المفعول به») authentic content integrity: vocabulary («رصيدي الجديد»), textbook phrase meanings, antonyms, comprehension questions, inductive grammar discovery («ألاحظ وأكتشف»), rules, and all 5 interactive activities (`sentenceTargetTap`, `openSentenceFill` without suggestions, `sentencePartsAnalysis`, `writtenParsing` with accusative model resolution, and `textWordExtraction`).
  10. Teacher presentation settings persistence and configuration (`ProgressService`).
  11. Child-friendly typography and Arabic font family switching (`AppTheme.buildTheme`).
  12. Interactive activity types including multi-selection, sentence blanks, word ordering, multi-sentence choice, written parsing with auto-correction, open-ended sentence fill, text extraction tables, and full lesson presentation workflows.


