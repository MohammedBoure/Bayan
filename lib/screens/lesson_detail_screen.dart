import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../models/reading_passage_model.dart';
import '../nlp/arabic_clitic_stemmer.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/sentence_parser_view.dart';
import '../widgets/teacher_toolbar_widget.dart';
import 'interactive_activity_screen.dart';

/// [04] صفحة الدرس الصفي الشاملة (Classroom 5-Stage Lesson Presentation)
/// Aligned with the official 5-stage primary pedagogy:
/// 1. النص القرائي (Reading Anchor Story)
/// 2. كلماتي الجديدة (Vocabulary Glossary & Antonyms)
/// 3. أقرأ وأفهم (Comprehension Classroom Questions)
/// 4. ألاحظ وأميز (Inductive Grammar Discovery)
/// 5. أتعلم (Consolidated Rule & Interactive Syntactic Breakdown)
class LessonDetailScreen extends StatefulWidget {
  final LessonModel lesson;
  final ProgressService progressService;

  const LessonDetailScreen({
    super.key,
    required this.lesson,
    required this.progressService,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  late bool _showTashkeel;
  late bool _areAnswersRevealed;
  late bool _isSpotlightActive;
  int _activeStageIndex = 0;
  int? _spotlightedParagraphIndex;

  @override
  void initState() {
    super.initState();
    _showTashkeel = widget.progressService.showTashkeel;
    _areAnswersRevealed = widget.progressService.revealAnswersDirectly;
    _isSpotlightActive = widget.progressService.spotlightReading;
  }

  void _inspectWord(String word) {
    if (!widget.progressService.nlpAutoAnalysis) return;

    final cleanWord = word.replaceAll(RegExp(r'[^\u0621-\u064A\u064B-\u0652]'), '');
    if (cleanWord.isEmpty) return;

    final stemResult = ArabicCliticStemmer.analyzeWord(cleanWord);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.smart_toy_rounded, color: AppTheme.verbColor, size: 30),
                  const SizedBox(width: 10),
                  const Text(
                    'التَّحْلِيلُ الصَّرْفِيُّ اللِّسَانِيُّ لِلْكَلِمَةِ:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.primaryTeal, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('الكَلِمَةُ', style: TextStyle(fontSize: 16, color: AppTheme.textMuted)),
                        const SizedBox(height: 4),
                        Text(cleanWord, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('السَّوَابِقُ (الـ، بـ، و...)', style: TextStyle(fontSize: 16, color: AppTheme.textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          stemResult.proclitics.isEmpty ? 'لا يُوجَد' : stemResult.proclitics.join(' + '),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.particleColor),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('الأَصْلُ / الجِذْرُ', style: TextStyle(fontSize: 16, color: AppTheme.textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          stemResult.stem,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.verbColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('إِغْلاقُ التَّحْلِيلِ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.progressService.fontSizeScale;
    final passage = widget.lesson.readingPassage;
    final discovery = widget.lesson.discovery;

    // Build the stages available for this lesson
    final List<String> stageTitles = [
      if (passage != null) '1. النَّصُّ القِرَائِيُّ',
      if (passage != null && passage.vocabulary.isNotEmpty) '2. كَلِمَاتِي الجَدِيدَةُ',
      if (passage != null && passage.comprehensionQuestions.isNotEmpty) '3. أَقْرَأُ وَأَفْهَمُ',
      if (discovery != null) '4. أُلاحِظُ وَأُمَيِّزُ',
      '5. القَاعِدَةُ النَّحْوِيَّةُ',
    ];

    return AppScaffold(
      title: widget.lesson.title,
      progressService: widget.progressService,
      actions: [
        TeacherHeaderActions(
          progressService: widget.progressService,
          areAnswersRevealed: _areAnswersRevealed,
          onToggleAnswers: () {
            setState(() {
              _areAnswersRevealed = !_areAnswersRevealed;
            });
          },
          isSpotlightActive: _isSpotlightActive,
          onToggleSpotlight: () {
            setState(() {
              _isSpotlightActive = !_isSpotlightActive;
            });
          },
          showTashkeel: _showTashkeel,
          onToggleTashkeel: () {
            setState(() {
              _showTashkeel = !_showTashkeel;
            });
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Lesson Header
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryTeal, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lesson.title,
                          style: TextStyle(
                            fontSize: 28 * scale,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.lesson.subtitle,
                          style: TextStyle(
                            fontSize: 18 * scale,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stage Navigation Tabs
            if (stageTitles.length > 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: stageTitles.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final title = entry.value;
                    final isSelected = _activeStageIndex == idx;

                    return Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: ChoiceChip(
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _activeStageIndex = idx;
                            });
                          }
                        },
                        label: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18 * scale,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                        selectedColor: AppTheme.primaryTeal,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryTeal : const Color(0xFFCBD5E1),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 22),

            // Display Active Stage Content
            _buildActiveStageContent(scale, passage, discovery),

            const SizedBox(height: 32),

            // Classroom Activities Launch Button
            SizedBox(
              height: 72,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => InteractiveActivityScreen(
                        activities: widget.lesson.activities,
                        lessonTitle: widget.lesson.title,
                        lessonIdToComplete: widget.lesson.id,
                        progressService: widget.progressService,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                icon: const Icon(Icons.sports_esports_rounded, size: 36),
                label: Text(
                  'الاِنْتِقَالُ إِلَى التَّمَارِينِ التَّفَاعُلِيَّةِ (${widget.lesson.activities.length} أَنْشِطَة)',
                  style: TextStyle(
                    fontSize: 22 * scale,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveStageContent(double scale, ReadingPassageModel? passage, GrammarDiscoveryModel? discovery) {
    if (passage == null) {
      return _buildStageRule(scale);
    }

    switch (_activeStageIndex) {
      case 0:
        return _buildStageReading(scale, passage);
      case 1:
        return _buildStageVocabulary(scale, passage);
      case 2:
        return _buildStageComprehension(scale, passage);
      case 3:
        return discovery != null ? _buildStageDiscovery(scale, discovery) : _buildStageRule(scale);
      case 4:
      default:
        return _buildStageRule(scale);
    }
  }

  // 1. النص القرائي
  Widget _buildStageReading(double scale, ReadingPassageModel passage) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_stories_rounded, color: AppTheme.primaryTeal, size: 32),
                  const SizedBox(width: 10),
                  Text(
                    'نَصُّ الاِنْطِلاقِ: "${passage.title}"',
                    style: TextStyle(fontSize: 24 * scale, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                  ),
                ],
              ),
              if (passage.author.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    passage.author,
                    style: TextStyle(fontSize: 15 * scale, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                  ),
                ),
            ],
          ),
          const Divider(height: 28, thickness: 1.5),

          // Paragraphs
          ...passage.paragraphs.asMap().entries.map((entry) {
            final idx = entry.key;
            final text = entry.value;
            final isSpotlighted = _isSpotlightActive && _spotlightedParagraphIndex == idx;

            return InkWell(
              onTap: () {
                if (_isSpotlightActive) {
                  setState(() {
                    _spotlightedParagraphIndex = (_spotlightedParagraphIndex == idx) ? null : idx;
                  });
                }
              },
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSpotlighted ? AppTheme.primaryLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSpotlighted ? AppTheme.primaryTeal : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: SelectableText(
                  text,
                  style: TextStyle(
                    fontSize: (isSpotlighted ? 26 : 22) * scale,
                    height: 2.0,
                    fontWeight: isSpotlighted ? FontWeight.bold : FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded, color: AppTheme.primaryTeal, size: 22),
                SizedBox(width: 8),
                Text(
                  'إرشاد للأستاذ: انقر على أي فقرة لتسليط الضوء عليها وتكبيرها لتلاميذ المقاعد الخلفية.',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. كلماتي الجديدة
  Widget _buildStageVocabulary(double scale, ReadingPassageModel passage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accentOrange, width: 2),
          ),
          child: Row(
            children: const [
              Icon(Icons.menu_book_rounded, color: AppTheme.accentOrange, size: 30),
              SizedBox(width: 10),
              Text(
                'كَلِمَاتِي الجَدِيدَةُ وَإِثْرَاءُ الرَّصِيدِ اللُّغَوِيِّ (مَعَانٍ وَأَضْدَاد):',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: passage.vocabulary.map((vocab) {
            return Container(
              width: 380,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: vocab.isAntonym ? AppTheme.accentCoral : AppTheme.primaryTeal,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        vocab.word,
                        style: TextStyle(
                          fontSize: 26 * scale,
                          fontWeight: FontWeight.w900,
                          color: vocab.isAntonym ? AppTheme.accentCoral : AppTheme.primaryTeal,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.psychology_alt_rounded, color: AppTheme.primaryTeal, size: 24),
                            tooltip: 'تَحْلِيلٌ صَرْفِيٌّ لِسَانِيٌّ',
                            onPressed: () => _inspectWord(vocab.word),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: vocab.isAntonym
                                  ? AppTheme.accentCoral.withValues(alpha: 0.15)
                                  : AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              vocab.isAntonym ? 'ضِدٌّ' : 'مَعْنًى',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.bold,
                                color: vocab.isAntonym ? AppTheme.accentCoral : AppTheme.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    vocab.explanation,
                    style: TextStyle(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 3. أقرأ وأفهم
  Widget _buildStageComprehension(double scale, ReadingPassageModel passage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.verbColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.verbColor, width: 2),
          ),
          child: Row(
            children: const [
              Icon(Icons.question_answer_rounded, color: AppTheme.verbColor, size: 30),
              SizedBox(width: 10),
              Text(
                'أَقْرَأُ وَأَفْهَمُ (أَسْئِلَةُ الحِوَارِ وَالاسْتِيعَابِ الصَّفِّيِّ):',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        ...passage.comprehensionQuestions.asMap().entries.map((entry) {
          final idx = entry.key;
          final q = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.verbColor,
                      child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        q.question,
                        style: TextStyle(
                          fontSize: 22 * scale,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Model Answer
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _areAnswersRevealed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: InkWell(
                    onTap: () {
                      setState(() {
                        _areAnswersRevealed = true;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.visibility_rounded, size: 20, color: AppTheme.textMuted),
                          SizedBox(width: 8),
                          Text('انْقُرْ هُنَا لِعَرْضِ الإِجَابَةِ النَّمُوذَجِيَّةِ', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  secondChild: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryTeal, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            q.modelAnswer,
                            style: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // 4. ألاحظ وأميز
  Widget _buildStageDiscovery(double scale, GrammarDiscoveryModel discovery) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.primaryTeal, width: 2.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.find_in_page_rounded, color: AppTheme.primaryTeal, size: 34),
              SizedBox(width: 12),
              Text(
                'أُلاحِظُ وَأُمَيِّزُ (بِنَاءُ الظَّاهِرَةِ النَّحْوِيَّةِ اسْتِقْرَائِيّاً):',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textDark),
              ),
            ],
          ),
          const Divider(height: 28, thickness: 1.5),

          // Trigger Sentences
          ...discovery.triggerSentences.map((sentence) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: Text(
                '« $sentence »',
                style: TextStyle(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.8,
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
          // Observation Prompt
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.accentAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.accentAmber, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  discovery.observationPrompt,
                  style: TextStyle(fontSize: 22 * scale, fontWeight: FontWeight.w900, color: AppTheme.accentOrange),
                ),
                const SizedBox(height: 12),
                ...discovery.observations.map((obs) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_right_rounded, color: AppTheme.accentOrange, size: 28),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            obs,
                            style: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. القاعدة النحوية والمثال التفاعلي
  Widget _buildStageRule(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Rule Card
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppTheme.accentAmber, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentAmber.withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.lightbulb_rounded, color: AppTheme.accentAmber, size: 34),
                  SizedBox(width: 10),
                  Text(
                    'القَاعِدَةُ النَّحْوِيَّةُ الأَسَاسِيَّةُ (أَتَعَلَّمُ):',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.lesson.ruleSummary,
                style: TextStyle(
                  fontSize: 24 * scale,
                  height: 1.85,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 26),

        // Interactive Examples
        ...widget.lesson.examples.map((example) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: SentenceParserView(
              tokens: example.tokens,
              showTashkeel: _showTashkeel,
              title: 'مِثَالٌ تَفَاعُلِيٌّ عَلَى السَّبُّورَةِ: "${example.sentence}"',
            ),
          );
        }),

        // Key Takeaways
        if (widget.lesson.keyTakeaways.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.star_rounded, color: AppTheme.accentAmber, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'خُلاصَةُ الدَّرْسِ لِلتَّلامِيذِ:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...widget.lesson.keyTakeaways.map((point) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            point,
                            style: TextStyle(fontSize: 19 * scale, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}
