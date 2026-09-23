# Models Directory (`lib/models`)

This directory defines all structured data models used throughout the application.

## Files:
- [nlp_token_model.dart](file:///C:/Users/moham/Desktop/Bayan/lib/models/nlp_token_model.dart): Data model for tokenized Arabic words with linguistic annotations (POS tag, subtype, case mark, pedagogical explanation).
- [activity_model.dart](file:///C:/Users/moham/Desktop/Bayan/lib/models/activity_model.dart): Data model for interactive activities (`ActivityModel`), supporting single/multiple-choice, drag-and-drop fill-in-the-blank, multi-sentence verb completion (`multiSentenceFill`), sentence multi-selection and paragraph extraction (`multiSelect`), 2-column & 3-column categorization boards, sentence word ordering, nominal-to-verbal sentence transformation (`multiSentenceOrder`), multi-sentence choice (`sentenceMultiChoice`), written parsing with auto-correction (`writtenParsing`), open sentence fill (`openSentenceFill`), text extraction tables (`textExtractionTable`), sentence target word tapping (`sentenceTargetTap`), sentence parts analysis (`sentencePartsAnalysis`), and in-text word extraction (`textWordExtraction`).
- [quiz_model.dart](file:///C:/Users/moham/Desktop/Bayan/lib/models/quiz_model.dart): Data model for evaluation quizzes, individual questions, answer keys, and linguistic justifications.
- [lesson_model.dart](file:///C:/Users/moham/Desktop/Bayan/lib/models/lesson_model.dart): Data model for grammar lessons, containing instructional text, interactive examples, rules, and linked activities.
- [curriculum_unit_model.dart](file:///C:/Users/moham/Desktop/Bayan/lib/models/curriculum_unit_model.dart): Data model for organizing lessons hierarchically into educational units (*الوحدات التعليمية*).
- [grade_model.dart](file:///C:/Users/moham/Desktop/Bayan/lib/models/grade_model.dart): Data model for the three primary school grades (Years 3, 4, and 5) with curriculum units and metadata.
- [reading_passage_model.dart](file:///C:/Users/moham/Desktop/Bayan/lib/models/reading_passage_model.dart): Data models for reading stories (`ReadingPassageModel`), audio tracks (`ReadingAudioTrack`), vocabulary glossary items (`VocabularyItem`), word meaning matching (`WordMeaningMatchItem` for «اختر لكل كلمة معناها»), synonym replacement exercises (`SynonymReplacementItem`), oral comprehension questions (`ComprehensionQuestion`), inductive grammar discovery (`GrammarDiscoveryModel` with custom stage title «ألاحظ وأكتشف» / «ألاحظ وأميز» and dedicated observation questions), and linguistic enrichment sections (`LinguisticEnrichmentModel`, `ComplementaryPairItem`, `MorphologicalDerivationItem`, and `OddWordOutItem` for «أثري لغتي»).
- [progress_model.dart](file:///C:/Users/moham/Desktop/Bayan/lib/models/progress_model.dart): Data model for tracking student completion state, scores, stars, and achievements.


