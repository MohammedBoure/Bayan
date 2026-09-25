# Test Directory (`test`)

This directory contains automated unit and widget test suites for the Arabic Grammar application.

## Files:
- [widget_test.dart](file:///C:/Users/moham/Desktop/Bayan/test/widget_test.dart): Comprehensive automated test suite (31 passing test suites) verifying:
  1. Arabic Clitic Stemming and affixes stripping (`ArabicCliticStemmer`).
  2. Offline Hybrid Arabic Syntactic Parser (`ArabicHybridParser`).
  3. Context-aware bigram analysis distinguishing nouns from verbs.
  4. Extensible curriculum repository dynamic unit/lesson registration.
  5. User correction feedback loop and SQLite persistence overrides.
  6. High-speed database caching and pre-seeded sentence lookups.
  7. Flutter application startup and home screen rendering for classroom projectors.
  8. Grade 3, Grade 4, and Grade 5 authentic curriculum packs structure (5 pedagogical stages, authentic reading texts, interactive word meaning matching, and linguistic enrichment exercises like complementary pairs, grouped morphology derivations, and odd-word-out identification).
  9. Grade 4 Lesson 3 («بين جارين - المفعول به») authentic content integrity: vocabulary («رصيدي الجديد»), textbook phrase meanings, antonyms, comprehension questions, inductive grammar discovery («ألاحظ وأكتشف»), rules, and all 5 interactive activities (`sentenceTargetTap`, `openSentenceFill` without suggestions, `sentencePartsAnalysis`, `writtenParsing` with accusative model resolution, and `textWordExtraction`).
  10. Grade 5 authentic curriculum coverage across all 3 lessons: Lesson 1 («نواصب الفعل المضارع»), Lesson 2 («جوازم الفعل المضارع»), Lesson 3 («الفعل المبني للمجهول ونائب الفاعل»), verifying target tap interactivity, subjunctive/jussive particle filling, arbitrary multi-column extraction tables (3-column case mark classifications and 5-column passive verb/deputy subject analyses), and comprehensive quiz validation.
  11. Grade 5 teacher audio narration integration: WAV file validation (`assets/sounds/5_1/1.wav`, `5_2/1.wav`, `5_3/1.wav`), duration parsing (> 130s), and `LessonDetailScreen` teacher audio bar controls.
  12. Teacher presentation settings persistence and configuration (`ProgressService`).
  13. Child-friendly typography and Arabic font family switching (`AppTheme.buildTheme`).
  14. Interactive activity types including multi-selection, sentence blanks, word ordering, multi-sentence choice, written parsing with auto-correction, open-ended sentence fill, arbitrary multi-column text extraction tables, and full lesson presentation workflows.


