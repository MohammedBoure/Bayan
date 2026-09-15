# Arabic Computational Linguistics Engine (`lib/nlp`)

This directory houses the core Natural Language Processing (NLP) and Computational Linguistics algorithms built specifically for Arabic grammar education in elementary schools.

## Files:
- [arabic_clitic_stemmer.dart](file:///C:/Users/moham/Desktop/aze2/lib/nlp/arabic_clitic_stemmer.dart): Lightweight morphological algorithm for stripping proclitics (`الـ`, `و`, `ف`, `ب`, `ك`, `ل`, `س`, `أ`) and enclitics (attached pronouns, feminine/plural markers) while detecting unequivocal noun markers.
- [arabic_lexicon.dart](file:///C:/Users/moham/Desktop/aze2/lib/nlp/arabic_lexicon.dart): In-memory lightweight lexical database of inherent common nouns (`بحر`, `شمس`, `قمر`...), adjectives, adverbs, defective verbs (*كان وأخواتها*), particles (*إن وأخواتها*), and demonstratives ensuring Lexical Priority.
- [arabic_hybrid_parser.dart](file:///C:/Users/moham/Desktop/aze2/lib/nlp/arabic_hybrid_parser.dart): Hybrid rule-based parsing engine featuring a syntax decision tree, bigram context checks (e.g. indefinite noun + indefinite adjective confirms nominal status), sentence classification (nominal, verbal, defective), and contextual role assignment.
- [arabic_linguistics_engine.dart](file:///C:/Users/moham/Desktop/aze2/lib/nlp/arabic_linguistics_engine.dart): High-level linguistics coordinator that bridges the Hybrid Parser, the local SQLite database cache, user override priority, diacritizer, and grammar checker.
