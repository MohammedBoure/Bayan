import 'package:flutter/material.dart';
import '../nlp/arabic_clitic_stemmer.dart';
import '../theme/app_theme.dart';

/// Evaluation result for student-entered passive sentence transformation.
class TransformationEvaluation {
  final bool isValid;
  final String? errorCategory; // 'لُغَوِيّ', 'شَكْلِيّ', 'إِمْلَائِيّ', or null
  final String feedback;

  const TransformationEvaluation({
    required this.isValid,
    this.errorCategory,
    required this.feedback,
  });
}

/// Interactive Sentence Transformation Widget (تحويل الجملة من المبني للمعلوم إلى المبني للمجهول).
/// Designed for classroom whiteboard, interactive touchscreens, and Data Show projectors.
///
/// Features:
/// - Clear question prompt: «حَوِّلِ الجُمْلَةَ مِنَ المَبْنِيِّ لِلْمَعْلُومِ إِلَى المَبْنِيِّ لِلْمَجْهُولِ»
/// - Empty text input field for each sentence (no candidate chips to arrange).
/// - Instant real-time pedagogical error diagnosis:
///   1) الأخطاء اللغوية: حذف الفاعل، تأنيث الفعل، الحفاظ على زمن الفعل.
///   2) الأخطاء الشكلية: ضم أول الماضي وكسر ما قبل آخره، ضم أول المضارع وفتح ما قبل آخره، رفع نائب الفاعل بالضمة.
///   3) الأخطاء الإملائية: التاء المربوطة مقابل الهاء، كتابة الحروف والهمزات.
/// - Quick Tashkeel toolbar for whiteboard touch input.
/// - 1-Click teacher model answer reveal.
class SentenceTransformationWidget extends StatefulWidget {
  final List<String> sentenceItems;
  final Map<String, String> targetSolutions;
  final String? prompt;
  final bool areAnswersRevealed;
  final ValueChanged<bool> onValidationChanged;

  const SentenceTransformationWidget({
    super.key,
    required this.sentenceItems,
    required this.targetSolutions,
    this.prompt,
    required this.areAnswersRevealed,
    required this.onValidationChanged,
  });

  @override
  State<SentenceTransformationWidget> createState() => _SentenceTransformationWidgetState();
}

class _SentenceTransformationWidgetState extends State<SentenceTransformationWidget> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  final Map<int, TransformationEvaluation?> _evaluations = {};
  int _activeSentenceIndex = 0;

  static const List<String> _tashkeelSymbols = ['َ', 'ُ', 'ِ', 'ْ', 'ّ', 'ً', 'ٌ', 'ٍ'];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (int i = 0; i < widget.sentenceItems.length; i++) {
      final sentence = widget.sentenceItems[i];
      final initialText = widget.areAnswersRevealed ? (widget.targetSolutions[sentence] ?? '') : '';
      final ctrl = TextEditingController(text: initialText);
      final focusNode = FocusNode();

      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          setState(() {
            _activeSentenceIndex = i;
          });
        }
      });

      _controllers[i] = ctrl;
      _focusNodes[i] = focusNode;

      if (widget.areAnswersRevealed) {
        _evaluations[i] = const TransformationEvaluation(
          isValid: true,
          feedback: 'أَحْسَنْتَ! إِجَابَةٌ نَمُوذَجِيَّةٌ صَحِيحَةٌ.',
        );
      }
    }
    _checkOverallValidation();
  }

  @override
  void didUpdateWidget(SentenceTransformationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.areAnswersRevealed && !oldWidget.areAnswersRevealed) {
      for (int i = 0; i < widget.sentenceItems.length; i++) {
        final sentence = widget.sentenceItems[i];
        final model = widget.targetSolutions[sentence] ?? '';
        _controllers[i]?.text = model;
        _evaluations[i] = const TransformationEvaluation(
          isValid: true,
          feedback: 'الحَلُّ النَّمُوذَجِيُّ كَامِلٌ مَعَ الشَّكْلِ التَّامِّ.',
        );
      }
      widget.onValidationChanged(true);
    } else if (!widget.areAnswersRevealed && oldWidget.areAnswersRevealed) {
      for (int i = 0; i < widget.sentenceItems.length; i++) {
        _controllers[i]?.clear();
        _evaluations[i] = null;
      }
      _checkOverallValidation();
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    for (final fn in _focusNodes.values) {
      fn.dispose();
    }
    super.dispose();
  }

  void _insertTashkeel(String diacritic) {
    final ctrl = _controllers[_activeSentenceIndex];
    if (ctrl == null) return;

    final text = ctrl.text;
    final selection = ctrl.selection;

    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, diacritic);
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + diacritic.length),
      );
    } else {
      ctrl.text = '$text$diacritic';
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    }

    _evaluateSentence(_activeSentenceIndex, shouldSetState: true);
  }

  void _evaluateSentence(int index, {bool shouldSetState = true}) {
    final original = widget.sentenceItems[index];
    final model = widget.targetSolutions[original] ?? '';
    final ctrl = _controllers[index];
    final input = ctrl?.text.trim() ?? '';

    final result = _analyzeTransformation(original, input, model);

    if (shouldSetState) {
      setState(() {
        _evaluations[index] = result;
      });
    } else {
      _evaluations[index] = result;
    }

    _checkOverallValidation();
  }

  void _checkOverallValidation() {
    if (widget.areAnswersRevealed) {
      widget.onValidationChanged(true);
      return;
    }

    bool allValid = true;
    for (int i = 0; i < widget.sentenceItems.length; i++) {
      if (_evaluations[i]?.isValid != true) {
        allValid = false;
        break;
      }
    }
    widget.onValidationChanged(allValid);
  }

  /// Evaluates student transformation identifying Linguistic, Diacritical, and Spelling mistakes.
  static TransformationEvaluation _analyzeTransformation(String original, String input, String model) {
    if (input.trim().isEmpty) {
      return const TransformationEvaluation(
        isValid: false,
        errorCategory: null,
        feedback: 'اكْتُبِ الجُمْلَةَ هُنَا بَعْدَ تَحْوِيلِهَا لِلْمَبْنِيِّ لِلْمَجْهُولِ مَعَ الشَّكْلِ التَّامِّ.',
      );
    }

    // Clean punctuation and normalize for lexical comparison
    String cleanPunct(String s) =>
        s.replaceAll(RegExp(r'[.؛،!؟«»\(\)]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    final cleanInput = cleanPunct(input);
    final strippedInput = ArabicCliticStemmer.stripDiacritics(cleanInput);
    final normInput = ArabicCliticStemmer.normalize(strippedInput);

    final cleanModel = cleanPunct(model);
    final strippedModel = ArabicCliticStemmer.stripDiacritics(cleanModel);
    final normModel = ArabicCliticStemmer.normalize(strippedModel);

    // ==========================================
    // 1. الأخطاء اللغوية (Grammar & Syntactic Errors)
    // ==========================================

    // a) Did the student keep the active subject (الفاعل)?
    final activeSubjects = ['التلميذ', 'الجنود', 'التلاميذ', 'الفلاح', 'العمال', 'الفلاحون', 'الفلاحين'];
    for (final subj in activeSubjects) {
      if (ArabicCliticStemmer.normalize(original).contains(subj) && normInput.contains(subj)) {
        return TransformationEvaluation(
          isValid: false,
          errorCategory: 'لُغَوِيّ',
          feedback: '❌ خَطَأٌ لُغَوِيٌّ: يَجِبُ حَذْفُ الفَاعِلِ ($subj) عِنْدَ البِنَاءِ لِلْمَجْهُولِ، وَإِنَابَةُ المَفْعُولِ بِهِ مَكَانَهُ!',
        );
      }
    }

    // b) Check tense preservation (الماضي يبقى ماضيًا، والمضارع يبقى مضارعًا)
    final cleanOriginal = ArabicCliticStemmer.stripDiacritics(original);
    final isOriginalPresent = cleanOriginal.startsWith('يقرأ') ||
        cleanOriginal.startsWith('يرفع') ||
        cleanOriginal.startsWith('يزرع') ||
        cleanOriginal.startsWith('يقرا');

    if (isOriginalPresent) {
      if (normInput.startsWith('قر') ||
          normInput.startsWith('رفع') ||
          normInput.startsWith('زرع') ||
          normInput.startsWith('حفظ') ||
          normInput.startsWith('كتب')) {
        return const TransformationEvaluation(
          isValid: false,
          errorCategory: 'لُغَوِيّ',
          feedback: '❌ خَطَأٌ لُغَوِيٌّ: الفِعْلُ فِي الجُمْلَةِ الأَصْلِيَّةِ مُضَارِعٌ، فَيَجِبُ أَنْ يَبْقَى مُضَارِعًا مَبْنِيًّا لِلْمَجْهُولِ!',
        );
      }
    } else {
      if (normInput.startsWith('يكتب') ||
          normInput.startsWith('يرفع') ||
          normInput.startsWith('يحفظ') ||
          normInput.startsWith('يزرع') ||
          normInput.startsWith('يشيد')) {
        return const TransformationEvaluation(
          isValid: false,
          errorCategory: 'لُغَوِيّ',
          feedback: '❌ خَطَأٌ لُغَوِيٌّ: الفِعْلُ فِي الجُمْلَةِ الأَصْلِيَّةِ مَاضٍ، فَيَجِبُ أَنْ يَبْقَى مَاضِيًا مَبْنِيًّا لِلْمَجْهُولِ!',
        );
      }
    }

    // c) Feminization of verbs with feminine or broken plural naib fa'il
    if (cleanModel.startsWith('حُفِظَت') && (normInput.startsWith('حفظ ') || normInput.startsWith('حفظت'))) {
      if (normInput.startsWith('حفظ ')) {
        return const TransformationEvaluation(
          isValid: false,
          errorCategory: 'لُغَوِيّ',
          feedback: '❌ خَطَأٌ لُغَوِيٌّ: نَائِبُ الفَاعِلِ (القَصِيدَةُ) مُؤَنَّثٌ؛ فَيَجِبُ تَأْنِيثُ الفِعْلِ بِالتَّاءِ: (حُفِظَتِ القَصِيدَةُ)!',
        );
      }
    }

    if (cleanModel.startsWith('زُرِعَت') && normInput.startsWith('زرع ')) {
      return const TransformationEvaluation(
        isValid: false,
        errorCategory: 'لُغَوِيّ',
        feedback: '❌ خَطَأٌ لُغَوِيٌّ: (الأَشْجَارُ) جَمْعُ تَكْسِيرٍ لِغَيْرِ العَاقِلِ فَيُؤَنَّثُ الفِعْلُ مَعَهُ بِالتَّاءِ: (زُرِعَتِ الأَشْجَارُ)!',
      );
    }

    if (cleanModel.startsWith('شُيِّدَت') && normInput.startsWith('شيد ')) {
      return const TransformationEvaluation(
        isValid: false,
        errorCategory: 'لُغَوِيّ',
        feedback: '❌ خَطَأٌ لُغَوِيٌّ: (المَصَانِعُ) جَمْعٌ لِغَيْرِ العَاقِلِ فَيُؤَنَّثُ الفِعْلُ مَعَهُ بِالتَّاءِ: (شُيِّدَتِ المَصَانِعُ)!',
      );
    }

    if (cleanModel.startsWith('تُقْرَأ') && (normInput.startsWith('يقرا') || normInput.startsWith('يقرأ'))) {
      return const TransformationEvaluation(
        isValid: false,
        errorCategory: 'لُغَوِيّ',
        feedback: '❌ خَطَأٌ لُغَوِيٌّ: نَائِبُ الفَاعِلِ (القِصَصُ) مُؤَنَّثٌ مَجَازِيٌّ فَيُؤَنَّثُ الفِعْلُ المُضَارِعُ بِالتَّاءِ: (تُـقْرَأُ القِصَصُ)!',
      );
    }

    if (cleanModel.startsWith('تُزْرَع') && (normInput.startsWith('يزرع') || normInput.startsWith('يزرع '))) {
      return const TransformationEvaluation(
        isValid: false,
        errorCategory: 'لُغَوِيّ',
        feedback: '❌ خَطَأٌ لُغَوِيٌّ: (الأَشْجَارُ) جَمْعٌ لِغَيْرِ العَاقِلِ فَيُؤَنَّثُ الفِعْلُ المُضَارِعُ بِالتَّاءِ: (تُـزْرَعُ الأَشْجَارُ)!',
      );
    }

    // ==========================================
    // 2. الأخطاء الإملائية (Spelling Errors)
    // ==========================================

    // Taa marbuta written as Haa
    if (input.contains('القصيده')) {
      return const TransformationEvaluation(
        isValid: false,
        errorCategory: 'إِمْلَائِيّ',
        feedback: '❌ خَطَأٌ إِمْلَائِيٌّ: انْتَبِهْ لِلتَّاءِ المَرْبُوطَةِ فِي كَلِمَةِ (القَصِيدَةُ)؛ فَهِيَ تُكْتَبُ تَاءً مَرْبُوطَةً بِنُقْطَتَيْنِ (ـة) وَلَيْسَتْ هَاءً!',
      );
    }

    // Check if stripped words match the expected lexical model
    final inputWords = normInput.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final modelWords = normModel.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    if (inputWords.length != modelWords.length || normInput != normModel) {
      // If words don't match after normalization, explain spelling/word mismatch
      return TransformationEvaluation(
        isValid: false,
        errorCategory: 'إِمْلَائِيّ',
        feedback: '❌ خَطَأٌ إِمْلَائِيٌّ: تَأَكَّدْ مِنْ صِحَّةِ كَلِمَاتِ الجُمْلَةِ وَإِمْلَائِهَا: (المَطْلُوبُ: $strippedModel).',
      );
    }

    // ==========================================
    // 3. الأخطاء الشكلية (Tashkeel / Diacritic Errors)
    // ==========================================

    // Check if the student omitted diacritics entirely
    final hasAnyDiacritics = RegExp(r'[\u064B-\u0652]').hasMatch(cleanInput);

    // Extract first word (the verb) and second word (naib fa'il) from raw input
    final rawWords = cleanInput.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (rawWords.isNotEmpty) {
      final verbRaw = rawWords.first;

      // Rule: Past passive verb must have Damma on first letter (كُتِبَ، رُفِعَ، حُفِظَتْ، زُرِعَتْ، شُيِّدَتْ)
      if (!isOriginalPresent) {
        // If first letter has Fatha instead of Damma
        if (RegExp(r'^[كرحزش][\u064E]').hasMatch(verbRaw)) {
          return const TransformationEvaluation(
            isValid: false,
            errorCategory: 'شَكْلِيّ',
            feedback: '❌ خَطَأٌ شَكْلِيٌّ: الفِعْلُ المَاضِي المَبْنِيُّ لِلْمَجْهُولِ يُضَمُّ أَوَّلُهُ (ضَمَّة ُ) وَيُكْسَرُ مَا قَبْلَ آخِرِهِ (كَسْرَة ِ)، وَلَا يُفْتَحُ أَوَّلُهُ!',
          );
        }
      } else {
        // Rule: Present passive verb must have Damma on first letter (تُقْرَأُ، يُرْفَعُ، تُزْرَعُ)
        if (RegExp(r'^[يت][\u064E]').hasMatch(verbRaw)) {
          return const TransformationEvaluation(
            isValid: false,
            errorCategory: 'شَكْلِيّ',
            feedback: '❌ خَطَأٌ شَكْلِيٌّ: الفِعْلُ المُضَارِعُ المَبْنِيُّ لِلْمَجْهُولِ يُضَمُّ أَوَّلُهُ (ضَمَّة ُ) وَيُفْتَحُ مَا قَبْلَ آخِرِهِ (فَتْحَة َ)، وَلَا يُفْتَحُ أَوَّلُهُ!',
          );
        }
      }

      // Check naib fa'il diacritic (must be nominative with Damma)
      if (rawWords.length >= 2) {
        final naibRaw = rawWords.sublist(1).join(' ');
        // If naib fa'il explicitly ends with Fatha (مفتوح - منصوب)
        if (naibRaw.endsWith('\u064E')) {
          return const TransformationEvaluation(
            isValid: false,
            errorCategory: 'شَكْلِيّ',
            feedback: '❌ خَطَأٌ شَكْلِيٌّ: نَائِبُ الفَاعِلِ يَكُونُ مَرْفُوعًا بِالضَّمَّةِ ( ُ) وَلَا يَكُونُ مَنْصُوبًا بِالفَتْحَةِ ( َ)!',
          );
        }
        // If naib fa'il explicitly ends with Kasra
        if (naibRaw.endsWith('\u0640\u0650') || naibRaw.endsWith('\u0650')) {
          return const TransformationEvaluation(
            isValid: false,
            errorCategory: 'شَكْلِيّ',
            feedback: '❌ خَطَأٌ شَكْلِيٌّ: نَائِبُ الفَاعِلِ يَكُونُ مَرْفُوعًا بِالضَّمَّةِ ( ُ) وَلَا يَكُونُ مَجْرُورًا بِالكَسْرَةِ ( ِ)!',
          );
        }
      }
    }

    if (!hasAnyDiacritics) {
      return const TransformationEvaluation(
        isValid: false,
        errorCategory: 'شَكْلِيّ',
        feedback: '⚠️ انْتَبِهْ لِلشَّكْلِ: الكَلِمَاتُ صَحِيحَةٌ، وَلَكِنْ يَجِبُ ضَبْطُ الفِعْلِ وَنَائِبِ الفَاعِلِ بِالشَّكْلِ التَّامِّ (ضَمُّ أَوَّلِ الفِعْلِ، وَرَفْعُ نَائِبِ الفَاعِلِ بِالضَّمَّةِ).',
      );
    }

    // All linguistic, spelling, and diacritic checks passed!
    return const TransformationEvaluation(
      isValid: true,
      errorCategory: null,
      feedback: '✅ مُمْتَازٌ! إِجَابَةٌ صَحِيحَةٌ: حُذِفَ الفَاعِلُ، وَرُفِعَ نَائِبُ الفَاعِلِ، وَصِيغَ الفِعْلُ بِشَكْلٍ سَلِيمٍ.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _evaluations.values.where((e) => e?.isValid == true).length;
    final totalCount = widget.sentenceItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Classroom Title Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.transform_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.prompt ?? 'حَوِّلِ الجُمْلَةَ مِنَ المَبْنِيِّ لِلْمَعْلُومِ إِلَى المَبْنِيِّ لِلْمَجْهُولِ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: completedCount == totalCount ? const Color(0xFFDCFCE7) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: completedCount == totalCount ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  'المُكْتَمَلُ: $completedCount / $totalCount',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: completedCount == totalCount ? const Color(0xFF15803D) : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Quick Tashkeel Toolbar for Whiteboard and Touch Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.keyboard_outlined, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              const Text(
                'حَرَكَاتُ التَّشْكِيلِ لِلَّوْحَةِ:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _tashkeelSymbols.map((t) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _insertTashkeel(t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Sentence Transformation Cards List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.sentenceItems.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final sentence = widget.sentenceItems[index];
            final modelAnswer = widget.targetSolutions[sentence] ?? '';
            final eval = _evaluations[index];
            final isCorrect = eval?.isValid == true;
            final isFocused = _activeSentenceIndex == index;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCorrect
                    ? const Color(0xFFF0FDF4)
                    : isFocused
                        ? const Color(0xFFF8FAFC)
                        : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isCorrect
                      ? const Color(0xFF86EFAC)
                      : isFocused
                          ? AppTheme.primaryTeal.withValues(alpha: 0.5)
                          : const Color(0xFFE2E8F0),
                  width: isCorrect || isFocused ? 2 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sentence Header Row
                  Row(
                    children: [
                      // Item Number
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCorrect ? const Color(0xFF16A34A) : AppTheme.primaryTeal,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Original Active Sentence
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                sentence,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'مَبْنِيٌّ لِلْمَعْلُومِ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Conversion Input Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryTeal, size: 24),
                      const SizedBox(width: 10),

                      // Text Field (The blank for the student to write in)
                      Expanded(
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          readOnly: widget.areAnswersRevealed,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? const Color(0xFF15803D) : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isCorrect ? const Color(0xFFDCFCE7) : Colors.white,
                            hintText: '«اكْتُبِ الجُمْلَةَ هُنَا بَعْدَ تَحْوِيلِهَا لِلْمَبْنِيِّ لِلْمَجْهُولِ مَعَ الشَّكْلِ...»',
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                                width: isCorrect ? 1.8 : 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                            ),
                            suffixIcon: _controllers[index]?.text.isNotEmpty == true && !widget.areAnswersRevealed
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                                    onPressed: () {
                                      _controllers[index]?.clear();
                                      _evaluateSentence(index);
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (_) {
                            _evaluateSentence(index);
                          },
                          onFieldSubmitted: (_) {
                            _evaluateSentence(index);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Validate Button per row
                      ElevatedButton(
                        onPressed: () => _evaluateSentence(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCorrect ? const Color(0xFF16A34A) : AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isCorrect ? 'تَمَّ التَّحَقُّقُ' : 'تَحَقَّقْ',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  // Real-time Diagnosis Banner
                  if (eval != null && eval.feedback.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? const Color(0xFFDCFCE7)
                            : eval.errorCategory == 'لُغَوِيّ'
                                ? const Color(0xFFFEF2F2)
                                : eval.errorCategory == 'شَكْلِيّ'
                                    ? const Color(0xFFFFFBEB)
                                    : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCorrect
                              ? const Color(0xFF86EFAC)
                              : eval.errorCategory == 'لُغَوِيّ'
                                  ? const Color(0xFFFCA5A5)
                                  : eval.errorCategory == 'شَكْلِيّ'
                                      ? const Color(0xFFFDE68A)
                                      : const Color(0xFFFCA5A5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                            size: 20,
                            color: isCorrect
                                ? const Color(0xFF16A34A)
                                : eval.errorCategory == 'لُغَوِيّ'
                                    ? const Color(0xFFDC2626)
                                    : eval.errorCategory == 'شَكْلِيّ'
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          if (eval.errorCategory != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: eval.errorCategory == 'لُغَوِيّ'
                                    ? const Color(0xFFFEE2E2)
                                    : eval.errorCategory == 'شَكْلِيّ'
                                        ? const Color(0xFFFEF3C7)
                                        : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '[خَطَأٌ ${eval.errorCategory}]',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: eval.errorCategory == 'لُغَوِيّ'
                                      ? const Color(0xFFB91C1C)
                                      : eval.errorCategory == 'شَكْلِيّ'
                                          ? const Color(0xFFB45309)
                                          : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              eval.feedback,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isCorrect
                                    ? const Color(0xFF15803D)
                                    : eval.errorCategory == 'لُغَوِيّ'
                                        ? const Color(0xFF991B1B)
                                        : eval.errorCategory == 'شَكْلِيّ'
                                            ? const Color(0xFF92400E)
                                            : const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Teacher Answer Reveal Container
                  if (widget.areAnswersRevealed) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school_rounded, size: 18, color: Color(0xFF059669)),
                          const SizedBox(width: 8),
                          const Text(
                            'الحَلُّ النَّمُوذَجِيُّ: ',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                          ),
                          Text(
                            modelAnswer,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
