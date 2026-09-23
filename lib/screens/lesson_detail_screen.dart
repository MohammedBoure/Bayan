import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../models/reading_passage_model.dart';
import '../nlp/arabic_clitic_stemmer.dart';
import '../services/audio_player_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/audio_player_widget.dart';
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
  int _vocabFilter = 0; // 0 = الكل, 1 = المعاني والمفردات, 2 = الكلمة وضدها / تعويض المرادفات / اختيار المعاني, 3 = أثري لغتي
  final Set<int> _revealedQuestionIndices = <int>{};
  final Set<int> _revealedSynonymIndices = <int>{};
  final Set<int> _revealedMeaningMatchIndices = <int>{};
  final Set<int> _revealedAntonymIndices = <int>{};
  final Set<int> _revealedPairIndices = <int>{};
  final Set<int> _revealedDerivationIndices = <int>{};
  List<int> _audioHighlightedParagraphs = const [];
  bool _showAudioPlayer = false;

  @override
  void dispose() {
    AudioPlayerService.instance.removeListener(_onAudioPlayerStateChange);
    AudioPlayerService.instance.stop();
    super.dispose();
  }

  void _onAudioPlayerStateChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _showTashkeel = widget.progressService.showTashkeel;
    _areAnswersRevealed = widget.progressService.revealAnswersDirectly;
    _isSpotlightActive = widget.progressService.spotlightReading;
    AudioPlayerService.instance.addListener(_onAudioPlayerStateChange);
    if (_areAnswersRevealed && widget.lesson.readingPassage != null) {
      final passage = widget.lesson.readingPassage!;
      for (int i = 0; i < passage.comprehensionQuestions.length; i++) {
        _revealedQuestionIndices.add(i);
      }
      for (int i = 0; i < passage.synonymReplacements.length; i++) {
        _revealedSynonymIndices.add(i);
      }
      for (int i = 0; i < passage.meaningMatches.length; i++) {
        _revealedMeaningMatchIndices.add(i);
      }
      final antonymsCount = passage.vocabulary.where((v) => v.isAntonym).length;
      for (int i = 0; i < antonymsCount; i++) {
        _revealedAntonymIndices.add(i);
      }
      if (passage.hasEnrichment) {
        for (int i = 0; i < passage.enrichment!.complementaryPairs.length; i++) {
          _revealedPairIndices.add(i);
        }
        for (int i = 0; i < passage.enrichment!.derivations.length; i++) {
          _revealedDerivationIndices.add(i);
        }
      }
    }
    if (widget.lesson.readingPassage?.hasAudio == true) {
      _audioHighlightedParagraphs = widget.lesson.readingPassage!.audioTracks.first.paragraphIndices;
    }
  }

  void _toggleAllAntonyms(int total) {
    setState(() {
      if (_revealedAntonymIndices.length == total) {
        _revealedAntonymIndices.clear();
      } else {
        _revealedAntonymIndices.addAll(List.generate(total, (i) => i));
      }
    });
  }

  void _toggleAllSynonymReplacements(int total) {
    setState(() {
      if (_revealedSynonymIndices.length == total) {
        _revealedSynonymIndices.clear();
      } else {
        _revealedSynonymIndices.addAll(List.generate(total, (i) => i));
      }
    });
  }

  void _toggleAllMeaningMatches(int total) {
    setState(() {
      if (_revealedMeaningMatchIndices.length == total) {
        _revealedMeaningMatchIndices.clear();
      } else {
        _revealedMeaningMatchIndices.addAll(List.generate(total, (i) => i));
      }
    });
  }

  void _toggleAllEnrichment(int totalPairs, int totalDerivations) {
    setState(() {
      final allPairsRevealed = _revealedPairIndices.length == totalPairs;
      final allDerivationsRevealed = _revealedDerivationIndices.length == totalDerivations;
      if (allPairsRevealed && allDerivationsRevealed) {
        _revealedPairIndices.clear();
        _revealedDerivationIndices.clear();
      } else {
        _revealedPairIndices.addAll(List.generate(totalPairs, (i) => i));
        _revealedDerivationIndices.addAll(List.generate(totalDerivations, (i) => i));
      }
    });
  }

  void _toggleAllComprehensionAnswers(int totalQuestions) {
    setState(() {
      if (_revealedQuestionIndices.length == totalQuestions) {
        _revealedQuestionIndices.clear();
        _areAnswersRevealed = false;
      } else {
        _revealedQuestionIndices.clear();
        for (int i = 0; i < totalQuestions; i++) {
          _revealedQuestionIndices.add(i);
        }
        _areAnswersRevealed = true;
      }
    });
  }

  void _toggleSingleQuestionAnswer(int index) {
    setState(() {
      if (_revealedQuestionIndices.contains(index)) {
        _revealedQuestionIndices.remove(index);
      } else {
        _revealedQuestionIndices.add(index);
      }
      final total = widget.lesson.readingPassage?.comprehensionQuestions.length ?? 0;
      _areAnswersRevealed = total > 0 && _revealedQuestionIndices.length == total;
    });
  }


  @override
  Widget build(BuildContext context) {
    // Font scaling is applied globally via MediaQuery.textScaler in main.dart
    const scale = 1.0;
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
          hasAudio: passage?.hasAudio == true,
          isAudioActive: _showAudioPlayer,
          isAudioPlaying: AudioPlayerService.instance.isPlaying,
          onToggleAudio: () {
            setState(() {
              _showAudioPlayer = !_showAudioPlayer;
              if (_showAudioPlayer && passage != null) {
                _activeStageIndex = 0; // jump directly to reading text
              }
            });
          },
          areAnswersRevealed: _areAnswersRevealed,
          onToggleAnswers: () {
            final totalQuestions = widget.lesson.readingPassage?.comprehensionQuestions.length ?? 0;
            final totalSynonyms = widget.lesson.readingPassage?.synonymReplacements.length ?? 0;
            final totalMeaningMatches = widget.lesson.readingPassage?.meaningMatches.length ?? 0;
            final totalAntonyms = widget.lesson.readingPassage?.vocabulary.where((v) => v.isAntonym).length ?? 0;
            final totalPairs = widget.lesson.readingPassage?.enrichment?.complementaryPairs.length ?? 0;
            final totalDerivations = widget.lesson.readingPassage?.enrichment?.derivations.length ?? 0;
            setState(() {
              _areAnswersRevealed = !_areAnswersRevealed;
              if (_areAnswersRevealed) {
                _revealedQuestionIndices.addAll(List.generate(totalQuestions, (i) => i));
                _revealedSynonymIndices.addAll(List.generate(totalSynonyms, (i) => i));
                _revealedMeaningMatchIndices.addAll(List.generate(totalMeaningMatches, (i) => i));
                _revealedAntonymIndices.addAll(List.generate(totalAntonyms, (i) => i));
                _revealedPairIndices.addAll(List.generate(totalPairs, (i) => i));
                _revealedDerivationIndices.addAll(List.generate(totalDerivations, (i) => i));
              } else {
                _revealedQuestionIndices.clear();
                _revealedSynonymIndices.clear();
                _revealedMeaningMatchIndices.clear();
                _revealedAntonymIndices.clear();
                _revealedPairIndices.clear();
                _revealedDerivationIndices.clear();
              }
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
            // Streamlined Compact Lesson Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.primaryTeal, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            widget.lesson.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 22 * scale,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.lesson.subtitle,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

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
                            if (_activeStageIndex == 0 && idx != 0) {
                              AudioPlayerService.instance.stop();
                            }
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_stories_rounded, color: AppTheme.primaryTeal, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'نَصُّ الاِنْطِلاقِ: "${passage.title}"',
                    style: TextStyle(fontSize: 22 * scale, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                  ),
                ],
              ),
              Row(
                children: [
                  if (passage.author.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        passage.author,
                        style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.touch_app_rounded, size: 16, color: AppTheme.primaryTeal),
                        SizedBox(width: 4),
                        Text(
                          'انقر على أي فقرة لتكبيرها',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 18, thickness: 1.2),

          // Audio Narration Player (only displayed when requested by teacher from the top bar)
          if (passage.hasAudio && _showAudioPlayer)
            AudioPlayerWidget(
              tracks: passage.audioTracks,
              onClose: () {
                setState(() {
                  _showAudioPlayer = false;
                });
              },
              onTrackChanged: (indices) {
                setState(() {
                  _audioHighlightedParagraphs = indices;
                });
              },
            ),

          // Paragraphs
          ...passage.paragraphs.asMap().entries.map((entry) {
            final idx = entry.key;
            final text = entry.value;
            final hasSpotlight = _spotlightedParagraphIndex != null;
            final isSpotlighted = _spotlightedParagraphIndex == idx;
            final isDimmed = hasSpotlight && !isSpotlighted;
            final isAudioRelevant = _audioHighlightedParagraphs.contains(idx);

            return InkWell(
              onTap: () {
                setState(() {
                  _spotlightedParagraphIndex = (_spotlightedParagraphIndex == idx) ? null : idx;
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                margin: EdgeInsets.only(
                  bottom: isSpotlighted ? 12 : 6,
                  top: isSpotlighted ? 6 : 0,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSpotlighted ? 18 : 10,
                  vertical: isSpotlighted ? 14 : 6,
                ),
                decoration: BoxDecoration(
                  color: isSpotlighted
                      ? AppTheme.primaryLight
                      : (isAudioRelevant
                          ? const Color(0xFFF0FDF4)
                          : (isDimmed ? Colors.transparent : const Color(0xFFFAFAFA))),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSpotlighted
                        ? AppTheme.primaryTeal
                        : (isAudioRelevant
                            ? AppTheme.successGreen.withValues(alpha: 0.4)
                            : (isDimmed ? Colors.transparent : const Color(0xFFF1F5F9))),
                    width: isSpotlighted ? 2.5 : (isAudioRelevant ? 1.5 : 1),
                  ),
                  boxShadow: isSpotlighted
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryTeal.withValues(alpha: 0.18),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Opacity(
                  opacity: isDimmed ? 0.45 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isSpotlighted) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTeal,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'فَقْرَةٌ مُكَبَّرَةٌ لِلصَّفِّ (${idx + 1})',
                                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _spotlightedParagraphIndex = null;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                              label: const Text(
                                'إلغاء التكبير',
                                style: TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        text,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: (isSpotlighted ? 28 : 21) * scale,
                          height: isSpotlighted ? 2.0 : 1.75,
                          fontWeight: isSpotlighted ? FontWeight.bold : FontWeight.w600,
                          color: isSpotlighted ? AppTheme.primaryDark : AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.info_outline_rounded, color: AppTheme.primaryTeal, size: 18),
              SizedBox(width: 6),
              Text(
                'انقر مباشرة على نص أي فقرة لتكبيرها فوريًا لتلاميذ المقاعد الخلفية.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageVocabulary(double scale, ReadingPassageModel passage) {
    final meanings = passage.vocabulary.where((v) => !v.isAntonym).toList();
    final antonyms = passage.vocabulary.where((v) => v.isAntonym).toList();
    final hasSynonyms = passage.hasSynonyms;
    final hasMeaningMatches = passage.hasMeaningMatches;
    final hasEnrichment = passage.hasEnrichment;
    final totalCount = meanings.length +
        (hasSynonyms ? passage.synonymReplacements.length : 0) +
        antonyms.length +
        (hasMeaningMatches ? passage.meaningMatches.length : 0) +
        (hasEnrichment ? (passage.enrichment!.complementaryPairs.length + passage.enrichment!.derivations.length) : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // شريط العنوان والمحدد الفئوي (Filter Bar) لراحة الأستاذ على شاشة العرض
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: AppTheme.accentOrange, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'كَلِمَاتِي الجَدِيدَةُ وَإِثْرَاءُ الرَّصِيدِ اللُّغَوِيِّ',
                        style: TextStyle(
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        hasEnrichment
                            ? 'مُفْرَدَاتُ النَّصِّ، تَعْوِيضُ المُرَادِفَاتِ، وَتَمَارِينُ إِثْرَاءِ اللُّغَةِ'
                            : (hasMeaningMatches
                                ? 'مُفْرَدَاتُ النَّصِّ، رَصِيدِي الجَدِيدُ، وَاخْتِيَارُ مَعَانِي الكَلِمَاتِ'
                                : (hasSynonyms
                                    ? 'مُفْرَدَاتُ النَّصِّ مُصَنَّفَةٌ بَيْنَ شَرْحِ المَعَانِي وَتَعْوِيضِ المُرَادِفَاتِ'
                                    : 'مُفْرَدَاتُ النَّصِّ مُصَنَّفَةٌ بَيْنَ شَرْحِ المَعَانِي وَالأَضْدَادِ')),
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // أزرار الفلترة السريعة للأستاذ
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildVocabFilterChip(
                    label: 'الكُلُّ ($totalCount)',
                    icon: Icons.grid_view_rounded,
                    index: 0,
                    scale: scale,
                  ),
                  const SizedBox(width: 8),
                  if (meanings.isNotEmpty) ...[
                    _buildVocabFilterChip(
                      label: hasMeaningMatches
                          ? 'رَصِيدِي الجَدِيدُ (${meanings.length})'
                          : 'شَرْحُ المَعَانِي (${meanings.length})',
                      icon: Icons.lightbulb_outline_rounded,
                      index: 1,
                      scale: scale,
                      activeColor: AppTheme.primaryTeal,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (antonyms.isNotEmpty)
                    _buildVocabFilterChip(
                      label: 'الْكَلِمَةُ وَضِدُّهَا (${antonyms.length})',
                      icon: Icons.compare_arrows_rounded,
                      index: 2,
                      scale: scale,
                      activeColor: AppTheme.accentCoral,
                    ),
                  if (hasSynonyms)
                    _buildVocabFilterChip(
                      label: 'تَعْوِيضُ المُرَادِفَاتِ (${passage.synonymReplacements.length})',
                      icon: Icons.find_replace_rounded,
                      index: 2,
                      scale: scale,
                      activeColor: const Color(0xFF2563EB),
                    ),
                  if (hasMeaningMatches)
                    _buildVocabFilterChip(
                      label: 'اخْتَرْ لِكُلِّ كَلِمَةٍ مَعْنَاهَا (${passage.meaningMatches.length})',
                      icon: Icons.checklist_rounded,
                      index: 2,
                      scale: scale,
                      activeColor: const Color(0xFF0284C7),
                    ),
                  if (hasEnrichment) ...[
                    const SizedBox(width: 8),
                    _buildVocabFilterChip(
                      label: 'أُثْرِي لُغَتِي',
                      icon: Icons.auto_awesome_rounded,
                      index: 3,
                      scale: scale,
                      activeColor: const Color(0xFF7C3AED),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // القسم الأول: شرح المفردات والمعاني / رصيدي الجديد
        if ((_vocabFilter == 0 || _vocabFilter == 1) && meanings.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.bookmark_added_rounded, color: AppTheme.primaryTeal, size: 24),
                const SizedBox(width: 10),
                Text(
                  hasMeaningMatches
                      ? '📖 رَصِيدِي الجَدِيدُ (${meanings.length})'
                      : '📖 شَرْحُ الْمُفْرَدَاتِ وَمَعَانِي الْكَلِمَاتِ (${meanings.length})',
                  style: TextStyle(
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final crossAxisCount = availableWidth >= 1150 ? 3 : (availableWidth >= 720 ? 2 : 1);
              final cardWidth = (availableWidth - (crossAxisCount - 1) * 16) / crossAxisCount;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: meanings.map((vocab) => _buildMeaningCard(vocab, scale, width: cardWidth)).toList(),
              );
            },
          ),
          const SizedBox(height: 22),
        ],

        // القسم الثاني: الكلمة وضدها
        if ((_vocabFilter == 0 || _vocabFilter == 2) && antonyms.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.accentCoral.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swap_horiz_rounded, color: AppTheme.accentCoral, size: 26),
                    const SizedBox(width: 10),
                    Text(
                      '⚖️ الْكَلِمَةُ وَضِدُّهَا فِي النَّصِّ (${antonyms.length})',
                      style: TextStyle(
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accentCoral,
                      ),
                    ),
                  ],
                ),
                // أزرار التحكم الصفي للأستاذ: إظهار جميع الأضداد / إخفاء الأضداد
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _revealedAntonymIndices.isNotEmpty
                            ? AppTheme.accentCoral.withValues(alpha: 0.15)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _revealedAntonymIndices.isNotEmpty
                            ? AppTheme.accentCoral.withValues(alpha: 0.4)
                            : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        'المَعْرُوضُ: ${_revealedAntonymIndices.length} مِنْ ${antonyms.length}',
                        style: TextStyle(
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.bold,
                          color: _revealedAntonymIndices.isNotEmpty ? AppTheme.accentCoral : AppTheme.textMuted,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _toggleAllAntonyms(antonyms.length),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _revealedAntonymIndices.length == antonyms.length
                            ? const Color(0xFF64748B)
                            : AppTheme.accentCoral,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(
                        _revealedAntonymIndices.length == antonyms.length
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _revealedAntonymIndices.length == antonyms.length
                            ? 'إِخْفَاءُ جَمِيعِ الأَضْدَادِ'
                            : 'إِظْهَارُ جَمِيعِ الأَضْدَادِ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final isTwoCol = availableWidth >= 960 && antonyms.length > 1;
              final cardWidth = isTwoCol ? (availableWidth - 16) / 2 : availableWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: antonyms.asMap().entries.map((entry) {
                  return _buildAntonymCard(entry.value, entry.key, scale, width: cardWidth);
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 22),
        ],

        // القسم الثالث: تمرين التعويض بالمرادفات (مطابق تماماً للكتاب المدرسي)
        if ((_vocabFilter == 0 || _vocabFilter == 2) && hasSynonyms) ...[
          _buildSynonymReplacementSection(passage, scale),
          const SizedBox(height: 22),
        ],

        // القسم الرابع: اختيار المعنى المناسب (مطابق تماماً للكتاب المدرسي)
        if ((_vocabFilter == 0 || _vocabFilter == 2) && hasMeaningMatches) ...[
          _buildMeaningMatchingSection(passage, scale),
          const SizedBox(height: 22),
        ],

        // القسم الخامس: أثري لغتي (الكلمتان المتكاملتان والمشتقات الصرفية)
        if ((_vocabFilter == 0 || _vocabFilter == 3) && hasEnrichment) ...[
          _buildEnrichmentSection(passage.enrichment!, scale),
          const SizedBox(height: 22),
        ],
      ],
    );
  }

  Widget _buildSynonymReplacementSection(ReadingPassageModel passage, double scale) {
    final allRevealed = _revealedSynonymIndices.length == passage.synonymReplacements.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط العنوان مع بنك الكلمات وزر التحكم
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.find_replace_rounded, color: Color(0xFF2563EB), size: 26),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'عَوِّضِ الْكَلِمَةَ الْمُلَوَّنَةَ بِكَلِمَةٍ لَهَا نَفْسُ الْمَعْنَى:',
                    style: TextStyle(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),

              ElevatedButton.icon(
                onPressed: () => _toggleAllSynonymReplacements(passage.synonymReplacements.length),
                icon: Icon(allRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                label: Text(
                  allRevealed ? 'إِخْفَاءُ جَمِيعِ البَدَائِلِ' : 'إِظْهَارُ جَمِيعِ البَدَائِلِ',
                  style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: allRevealed ? Colors.grey.shade700 : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // بنك الكلمات المتاحة للتعويض
          if (passage.availableSynonyms.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category_rounded, color: Color(0xFF2563EB), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'بَنْكُ المُرَادِفَاتِ البَدِيلَةِ: ',
                    style: TextStyle(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: passage.availableSynonyms.map((syn) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            syn,
                            style: TextStyle(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // قائمة الجمل
          ...passage.synonymReplacements.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isRevealed = _revealedSynonymIndices.contains(idx);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isRevealed ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isRevealed ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // رقم الجملة
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isRevealed ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // نص الجملة مع إبراز الكلمة المستهدفة
                      Expanded(
                        child: _buildHighlightedSentence(item, scale),
                      ),

                      const SizedBox(width: 12),

                      // زر الإظهار / الإخفاء الفردي
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            if (isRevealed) {
                              _revealedSynonymIndices.remove(idx);
                            } else {
                              _revealedSynonymIndices.add(idx);
                            }
                          });
                        },
                        icon: Icon(
                          isRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 18,
                          color: isRevealed ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                        ),
                        label: Text(
                          isRevealed ? 'إِخْفَاءُ البَدِيلِ' : 'كَشْفُ البَدِيلِ',
                          style: TextStyle(
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.bold,
                            color: isRevealed ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isRevealed ? const Color(0xFF86EFAC) : const Color(0xFF93C5FD),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),

                  // الحل والتعليل عند الكشف
                  if (isRevealed) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 16 * scale,
                                  fontFamily: 'Cairo',
                                  color: AppTheme.textDark,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'المُرَادِفُ البَدِيلُ هُوَ: ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                  ),
                                  TextSpan(
                                    text: '«${item.replacementWord}» ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF15803D),
                                      fontSize: 18,
                                    ),
                                  ),
                                  if (item.note != null && item.note!.isNotEmpty)
                                    TextSpan(
                                      text: '(${item.note})',
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHighlightedSentence(SynonymReplacementItem item, double scale) {
    final sentence = item.sentence;
    final word = item.highlightedWord;
    final index = sentence.indexOf(word);

    if (index == -1) {
      return Text(
        sentence,
        style: TextStyle(
          fontSize: 18 * scale,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
          height: 1.6,
        ),
      );
    }

    final before = sentence.substring(0, index);
    final after = sentence.substring(index + word.length);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 18 * scale,
          fontFamily: 'Cairo',
          color: AppTheme.textDark,
          height: 1.6,
        ),
        children: [
          TextSpan(text: before),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
              ),
              child: Text(
                word,
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFB45309),
                ),
              ),
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  Widget _buildMeaningMatchingSection(ReadingPassageModel passage, double scale) {
    final allRevealed = _revealedMeaningMatchIndices.length == passage.meaningMatches.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط العنوان مع زر التحكم لكشف/إخفاء الكل
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.checklist_rounded, color: Color(0xFF0284C7), size: 26),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    passage.meaningMatchPrompt.isNotEmpty
                        ? passage.meaningMatchPrompt
                        : 'اخْتَرْ لِكُلِّ كَلِمَةٍ مَعْنَاهَا:',
                    style: TextStyle(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0369A1),
                    ),
                  ),
                ],
              ),

              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _revealedMeaningMatchIndices.isNotEmpty
                          ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _revealedMeaningMatchIndices.isNotEmpty
                            ? const Color(0xFF0284C7).withValues(alpha: 0.4)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      'المَعْرُوضُ: ${_revealedMeaningMatchIndices.length} مِنْ ${passage.meaningMatches.length}',
                      style: TextStyle(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.bold,
                        color: _revealedMeaningMatchIndices.isNotEmpty
                            ? const Color(0xFF0284C7)
                            : AppTheme.textMuted,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _toggleAllMeaningMatches(passage.meaningMatches.length),
                    icon: Icon(allRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                    label: Text(
                      allRevealed ? 'إِخْفَاءُ جَمِيعِ الإِجَابَاتِ' : 'إِظْهَارُ جَمِيعِ الإِجَابَاتِ',
                      style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allRevealed ? Colors.grey.shade700 : const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // بنك المعاني المتاحة للاختيار
          if (passage.availableMeanings.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_rounded, color: Color(0xFF0284C7), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'بَنْكُ المَعَانِي المُتَاحَةِ: ',
                        style: TextStyle(
                          fontSize: 15 * scale,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0369A1),
                        ),
                      ),
                    ],
                  ),
                  ...passage.availableMeanings.map((meaning) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.lightBlue.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        meaning,
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0369A1),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // قائمة الكلمات والمطابقة مع معانيها
          ...passage.meaningMatches.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isRevealed = _revealedMeaningMatchIndices.contains(idx);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isRevealed ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isRevealed ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 650;

                  final meaningSlot = InkWell(
                    onTap: () {
                      setState(() {
                        if (isRevealed) {
                          _revealedMeaningMatchIndices.remove(idx);
                        } else {
                          _revealedMeaningMatchIndices.add(idx);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isRevealed ? Colors.white : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRevealed ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                          width: isRevealed ? 2 : 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isRevealed ? Icons.check_circle_rounded : Icons.help_outline_rounded,
                            color: isRevealed ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: isRevealed
                                ? Text(
                                    '«${item.meaning}»',
                                    style: TextStyle(
                                      fontSize: 19 * scale,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF15803D),
                                    ),
                                  )
                                : Text(
                                    'انْقُرْ لِكَشْفِ المَعْنَى المُنَاسِبِ ...',
                                    style: TextStyle(
                                      fontSize: 14 * scale,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );

                  final toggleButton = OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (isRevealed) {
                          _revealedMeaningMatchIndices.remove(idx);
                        } else {
                          _revealedMeaningMatchIndices.add(idx);
                        }
                      });
                    },
                    icon: Icon(
                      isRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 18,
                      color: isRevealed ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                    ),
                    label: Text(
                      isRevealed ? 'إِخْفَاءُ المَعْنَى' : 'كَشْفُ المَعْنَى',
                      style: TextStyle(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.bold,
                        color: isRevealed ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isRevealed ? const Color(0xFF86EFAC) : const Color(0xFF7DD3FC),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isWide)
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isRevealed ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF7DD3FC), width: 1.5),
                              ),
                              child: Text(
                                item.word,
                                style: TextStyle(
                                  fontSize: 20 * scale,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0369A1),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF64748B),
                              size: 26,
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: meaningSlot),
                            const SizedBox(width: 12),
                            toggleButton,
                          ],
                        )
                      else ...[
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isRevealed ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF7DD3FC), width: 1.5),
                              ),
                              child: Text(
                                item.word,
                                style: TextStyle(
                                  fontSize: 18 * scale,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0369A1),
                                ),
                              ),
                            ),
                            const Spacer(),
                            toggleButton,
                          ],
                        ),
                        const SizedBox(height: 10),
                        meaningSlot,
                      ],

                      // تعليق توضيحي أو سياق عند الكشف
                      if (isRevealed && item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.note!,
                                  style: TextStyle(
                                    fontSize: 13 * scale,
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVocabFilterChip({
    required String label,
    required IconData icon,
    required int index,
    required double scale,
    Color activeColor = AppTheme.primaryTeal,
  }) {
    final isSelected = _vocabFilter == index;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _vocabFilter = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // قسم أُثْرِي لُغَتِي (تراكيب متكاملة وأوزان صرفية تفاعلية)
  // ---------------------------------------------------------------------------
  Widget _buildEnrichmentSection(LinguisticEnrichmentModel enrichment, double scale) {
    final totalPairs = enrichment.complementaryPairs.length;
    final totalDerivations = enrichment.derivations.length;
    final allRevealed = _revealedPairIndices.length == totalPairs &&
        _revealedDerivationIndices.length == totalDerivations;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. شريط العنوان الرئيسي لقسم أثري لغتي مع زر التحكم الصفي
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🌟 أُثْرِي لُغَتِي (الْكِتَابُ الْمَدْرَسِيُّ)',
                        style: TextStyle(
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF5B21B6),
                        ),
                      ),
                      Text(
                        'تَمَارِينُ التَّرَاكِيبِ الْمُتَكَامِلَةِ وَالأَوْزَانِ الصَّرْفِيَّةِ لِتَنْمِيَةِ الفَصَاحَةِ',
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              ElevatedButton.icon(
                onPressed: () => _toggleAllEnrichment(totalPairs, totalDerivations),
                icon: Icon(allRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                label: Text(
                  allRevealed ? 'إِخْفَاءُ جَمِيعِ الإِجَابَاتِ' : 'إِظْهَارُ جَمِيعِ الإِجَابَاتِ',
                  style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: allRevealed ? Colors.grey.shade700 : const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. التمرين الأول: الكلمتان المتكاملتان
          if (enrichment.hasPairs) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.link_rounded, color: Color(0xFF7C3AED), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          enrichment.pairPrompt,
                          style: TextStyle(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF4C1D95),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // بنك الكلمات المتاحة للتكامل
                  if (enrichment.availablePairTargets.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC4B5FD)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'بَنْكُ الكَلِمَاتِ:',
                              style: TextStyle(
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: enrichment.availablePairTargets.map((target) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E8FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFA855F7), width: 1.2),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      target,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 15 * scale,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF581C87),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // قائمة بطاقات الكلمات المتكاملة المتجاوبة
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isTwoCol = width >= 850;
                final cardWidth = isTwoCol ? (width - 14) / 2 : width;

                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: enrichment.complementaryPairs.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final pair = entry.value;
                    final isRevealed = _revealedPairIndices.contains(idx);

                    return SizedBox(
                      width: cardWidth,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isRevealed ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRevealed ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // الطرف الأول
                            Expanded(
                              flex: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    pair.firstPart,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 18 * scale,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.add_circle_outline_rounded,
                                color: isRevealed ? const Color(0xFF16A34A) : const Color(0xFF7C3AED),
                                size: 24,
                              ),
                            ),

                            // الطرف الثاني (تفاعلي للكشف والإخفاء)
                            Expanded(
                              flex: 5,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isRevealed) {
                                      _revealedPairIndices.remove(idx);
                                    } else {
                                      _revealedPairIndices.add(idx);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isRevealed
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFEDE9FE),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isRevealed
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFF8B5CF6),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isRevealed
                                      ? FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            pair.secondPart,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: 18 * scale,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFF15803D),
                                            ),
                                          ),
                                        )
                                      : FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.touch_app_rounded, color: Color(0xFF6D28D9), size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                'انْقُرْ لِلْكَشْفِ',
                                                style: TextStyle(
                                                  fontSize: 13 * scale,
                                                  fontWeight: FontWeight.w900,
                                                  color: const Color(0xFF6D28D9),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],

          const SizedBox(height: 28),

          // 3. التمرين الثاني: المشتقات الصرفية
          if (enrichment.hasDerivations) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.hub_rounded, color: Color(0xFFD97706), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          enrichment.derivationPrompt,
                          style: TextStyle(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // شريط الوزن النموذجي المتبع
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceAround,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildDerivationHeaderPill('الفِعْلُ المَاضِي', 'اشْتَرَكَ', scale),
                        const Icon(Icons.arrow_back_rounded, color: Color(0xFFD97706), size: 18),
                        _buildDerivationHeaderPill('اسْمُ الفَاعِلِ', 'مُشْتَرِكٌ', scale),
                        const Icon(Icons.arrow_back_rounded, color: Color(0xFFD97706), size: 18),
                        _buildDerivationHeaderPill('المَصْدَرُ', 'اشْتِرَاكٌ', scale),
                        const Icon(Icons.arrow_back_rounded, color: Color(0xFFD97706), size: 18),
                        _buildDerivationHeaderPill('اسْمُ المَفْعُولِ', 'مُشْتَرَكٌ', scale),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // بطاقات تصريف الأفعال المطلوبة (احترم، ساعد، عاون، عمل)
            ...enrichment.derivations.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isRevealed = _revealedDerivationIndices.contains(idx);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isRevealed ? const Color(0xFFF8FAFC) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isRevealed ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'الفِعْلُ: ${item.rootVerb}',
                            style: TextStyle(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isRevealed) {
                                _revealedDerivationIndices.remove(idx);
                              } else {
                                _revealedDerivationIndices.add(idx);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isRevealed
                                  ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isRevealed ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: isRevealed ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isRevealed ? 'إِخْفَاءُ المُشْتَقَّاتِ' : 'كَشْفُ المُشْتَقَّاتِ',
                                  style: TextStyle(
                                    fontSize: 12 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: isRevealed ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // شبكة المشتقات الأربعة
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width >= 800 ? 4 : (width >= 450 ? 2 : 1);
                        final itemWidth = (width - (crossAxisCount - 1) * 10) / crossAxisCount;

                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildDerivationCell('الفِعْلُ المَاضِي', item.pastForm, isRevealed, itemWidth, scale, const Color(0xFF2563EB)),
                            _buildDerivationCell('اسْمُ الفَاعِلِ', item.activeParticiple, isRevealed, itemWidth, scale, const Color(0xFF0D9488)),
                            _buildDerivationCell('المَصْدَرُ', item.verbalNoun, isRevealed, itemWidth, scale, const Color(0xFFD97706)),
                            _buildDerivationCell('اسْمُ المَفْعُولِ', item.passiveParticiple, isRevealed, itemWidth, scale, const Color(0xFF7C3AED)),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDerivationHeaderPill(String role, String example, double scale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            role,
            style: TextStyle(fontSize: 11 * scale, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
          ),
          Text(
            example,
            style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w900, color: const Color(0xFFB45309)),
          ),
        ],
      ),
    );
  }

  Widget _buildDerivationCell(
    String label,
    String value,
    bool isRevealed,
    double width,
    double scale,
    Color accentColor,
  ) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isRevealed ? accentColor.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRevealed ? accentColor.withValues(alpha: 0.35) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11 * scale,
                fontWeight: FontWeight.bold,
                color: isRevealed ? accentColor : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            if (isRevealed)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              )
            else
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '؟',
                  style: TextStyle(
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // بطاقة شرح المعنى (تصميم زمردي مريح للعين مع تحليل صرفي اختياري)
  Widget _buildMeaningCard(VocabularyItem vocab, double scale, {double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.35), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
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
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    vocab.word,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 26 * scale,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'مَعْنًى',
                  style: TextStyle(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              vocab.explanation,
              style: TextStyle(
                fontSize: 18 * scale,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة الكلمة وضدها (تدعم كشف وإخفاء الضد فردياً وجماعياً مع إخفاء مسبق لتفعيل مهارة البحث لدى التلاميذ)
  Widget _buildAntonymCard(VocabularyItem vocab, int index, double scale, {double? width}) {
    final isRevealed = _revealedAntonymIndices.contains(index);

    // تنظيف صيغة الضد إذا كانت مكتوبة كـ "ضدها: ..."
    String cleanExplanation = vocab.explanation;
    final regex = RegExp(r'ضِدُّهَا(?:\s+فِي\s+(?:النَّصِّ|المَعْنَى))?\s*:\s*', unicode: true);
    final match = regex.firstMatch(cleanExplanation);
    String oppositeWord = cleanExplanation;
    if (match != null) {
      oppositeWord = cleanExplanation.substring(match.end).replaceAll('.', '').trim();
    }

    // استخراج البدائل المتعددة إذا كانت مفصولة بـ /
    final oppositeAlternatives = oppositeWord
        .split('/')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRevealed
              ? AppTheme.accentCoral.withValues(alpha: 0.6)
              : const Color(0xFFCBD5E1),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط رأس البطاقة: علامة التصنيف وزر الكشف/الإخفاء السريع للأستاذ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.accentCoral.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.compare_arrows_rounded, color: AppTheme.accentCoral, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'الكَلِمَةُ وَضِدُّهَا',
                      style: TextStyle(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentCoral,
                      ),
                    ),
                  ],
                ),
              ),

              // زر تبديل كشف وإخفاء الضد للأستاذ
              InkWell(
                onTap: () {
                  setState(() {
                    if (isRevealed) {
                      _revealedAntonymIndices.remove(index);
                    } else {
                      _revealedAntonymIndices.add(index);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isRevealed
                        ? AppTheme.accentCoral.withValues(alpha: 0.12)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isRevealed ? AppTheme.accentCoral : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: isRevealed ? AppTheme.accentCoral : const Color(0xFF64748B),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isRevealed ? 'إِخْفَاءُ الضِّدِّ' : 'إِظْهَارُ الضِّدِّ',
                        style: TextStyle(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.bold,
                          color: isRevealed ? AppTheme.accentCoral : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // بطاقة المقابلة البصرية بين الكلمة وضدها
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isRevealed
                  ? AppTheme.accentCoral.withValues(alpha: 0.04)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRevealed
                    ? AppTheme.accentCoral.withValues(alpha: 0.25)
                    : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. الطرف الأيمن: الكلمة الأصلية في النص
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'الْكَلِمَةُ فِي النَّصِّ',
                          style: TextStyle(
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            vocab.word,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24 * scale,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. شارة التضاد المركزية (≠ ضِدُّهَا)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCoral,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentCoral.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '≠',
                          style: TextStyle(
                            fontSize: 18 * scale,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ضِدُّهَا',
                          style: TextStyle(
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. الطرف الأيسر: الضد المقابل (تفاعلي للكشف والإخفاء)
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isRevealed) {
                          _revealedAntonymIndices.remove(index);
                        } else {
                          _revealedAntonymIndices.add(index);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: isRevealed
                            ? Colors.white
                            : const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRevealed
                              ? AppTheme.accentCoral.withValues(alpha: 0.4)
                              : const Color(0xFFFDA4AF),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isRevealed
                                ? AppTheme.accentCoral.withValues(alpha: 0.06)
                                : const Color(0xFFF43F5E).withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isRevealed ? 'الضِّدُّ الْمُقَابِلُ' : 'اسْتَخْرِجِ الضِّدَّ',
                            style: TextStyle(
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.bold,
                              color: isRevealed ? AppTheme.accentCoral : const Color(0xFFE11D48),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (isRevealed) ...[
                            if (oppositeAlternatives.length > 1)
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 6,
                                runSpacing: 6,
                                children: oppositeAlternatives.map((alt) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentCoral.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.accentCoral.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        alt,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 18 * scale,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.accentCoral,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  oppositeWord,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24 * scale,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.accentCoral,
                                  ),
                                ),
                              ),
                          ] else
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.touch_app_rounded, color: Color(0xFFDC2626), size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    'انْقُرْ لِلْكَشْفِ',
                                    style: TextStyle(
                                      fontSize: 14 * scale,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. أقرأ وأفهم (دعم كامل للعرض والإخفاء الجزئي والكلي للإجابات النموذجية)
  Widget _buildStageComprehension(double scale, ReadingPassageModel passage) {
    final totalQuestions = passage.comprehensionQuestions.length;
    final allRevealed = _revealedQuestionIndices.length == totalQuestions;
    final anyRevealed = _revealedQuestionIndices.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // شريط العنوان مع أزرار التحكم الكلي (إظهار الكل / إخفاء الكل)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.verbColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.verbColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.question_answer_rounded, color: AppTheme.verbColor, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'أَقْرَأُ وَأَفْهَمُ (أَسْئِلَةُ الحِوَارِ وَالاسْتِيعَابِ الصَّفِّيِّ)',
                        style: TextStyle(
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'يُمْكِنُ عَرْضُ أَوْ إِخْفَاءُ الإِجَابَاتِ نَمُوذَجِيّاً لِكُلِّ سُؤَالٍ عَلَى حِدَةٍ أَوْ لِلْجَمِيعِ',
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // أزرار التحكم الكلي في الإجابات
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // شارة عدد الإجابات المعروضة
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: anyRevealed
                          ? AppTheme.primaryTeal.withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: anyRevealed ? AppTheme.primaryTeal.withValues(alpha: 0.3) : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      'المَعْرُوضُ: ${_revealedQuestionIndices.length} مِنْ $totalQuestions',
                      style: TextStyle(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.bold,
                        color: anyRevealed ? AppTheme.primaryDark : AppTheme.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // زر التبديل الكلي (إظهار الكل / إخفاء الكل)
                  ElevatedButton.icon(
                    onPressed: () => _toggleAllComprehensionAnswers(totalQuestions),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allRevealed ? AppTheme.accentOrange : AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(
                      allRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 18,
                    ),
                    label: Text(
                      allRevealed ? 'إِخْفَاءُ جَمِيعِ الإِجَابَاتِ' : 'إِظْهَارُ جَمِيعِ الإِجَابَاتِ',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // قائمة الأسئلة مع بطاقات التحكم الجزئي الفردي
        ...passage.comprehensionQuestions.asMap().entries.map((entry) {
          final idx = entry.key;
          final q = entry.value;
          final isRevealed = _revealedQuestionIndices.contains(idx);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isRevealed
                    ? AppTheme.primaryTeal.withValues(alpha: 0.6)
                    : const Color(0xFFCBD5E1),
                width: isRevealed ? 2 : 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isRevealed
                      ? AppTheme.primaryTeal.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isRevealed ? AppTheme.primaryTeal : AppTheme.verbColor,
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
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
                    const SizedBox(width: 8),

                    // زر التبديل الجزئي لهذا السؤال بالذات (عرض / إخفاء فردي)
                    InkWell(
                      onTap: () => _toggleSingleQuestionAnswer(idx),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isRevealed
                              ? AppTheme.accentOrange.withValues(alpha: 0.12)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isRevealed
                                ? AppTheme.accentOrange
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              size: 17,
                              color: isRevealed ? AppTheme.accentOrange : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isRevealed ? 'إِخْفَاءُ الإِجَابَةِ' : 'عَرْضُ الإِجَابَةِ',
                              style: TextStyle(
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.bold,
                                color: isRevealed ? AppTheme.accentOrange : AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // منطقة الإجابة النموذجية (ظهور متحرك فردي)
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: isRevealed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: InkWell(
                    onTap: () => _toggleSingleQuestionAnswer(idx),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.help_outline_rounded, size: 20, color: AppTheme.textMuted),
                          const SizedBox(width: 10),
                          Text(
                            'انْقُرْ هُنَا أَوْ عَلَى الزِّرِّ أَعْلَاهُ لِإِظْهَارِ الإِجَابَةِ النَّمُوذَجِيَّةِ لِهَذَا السُّؤَالِ',
                            style: TextStyle(
                              fontSize: 15 * scale,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  secondChild: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryTeal, width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الإِجَابَةُ النَّمُوذَجِيَّةُ:',
                                style: TextStyle(
                                  fontSize: 13 * scale,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryDark.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                q.modelAnswer,
                                style: TextStyle(
                                  fontSize: 20 * scale,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryDark,
                                  height: 1.5,
                                ),
                              ),
                            ],
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
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: const [
              Icon(Icons.find_in_page_rounded, color: AppTheme.primaryTeal, size: 34),
              Text(
                'أُلاحِظُ وَأُمَيِّزُ (بِنَاءُ الظَّاهِرَةِ النَّحْوِيَّةِ اسْتِقْرَائِيّاً):',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textDark),
              ),
            ],
          ),
          const Divider(height: 28, thickness: 1.5),

          // Trigger Sentences with Target Words Highlighted in Red
          ...discovery.triggerSentences.map((sentence) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: _buildDiscoveryTriggerSentence(sentence, discovery.allTargetWords, scale),
            );
          }),

          // Target Pattern Banner
          if (discovery.targetedPattern.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFFDC2626), size: 24),
                  Text(
                    'الْكَلِمَاتُ الْمُسْتَهْدَفَةُ: ',
                    style: TextStyle(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  Text(
                    discovery.targetedPattern,
                    style: TextStyle(
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFB91C1C),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
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

  /// Determines whether a token matches one of the target grammatical words for the lesson.
  bool _isDiscoveryTargetWord(String token, List<String> targetWords) {
    if (targetWords.isEmpty) return false;

    final cleanToken = ArabicCliticStemmer.stripDiacritics(token).trim();
    final normToken = ArabicCliticStemmer.normalize(token);

    for (final target in targetWords) {
      final cleanTarget = ArabicCliticStemmer.stripDiacritics(target).trim();
      final normTarget = ArabicCliticStemmer.normalize(target);

      // 1. Exact match with diacritics
      if (token.trim() == target.trim()) return true;

      // 2. Match without diacritics
      if (cleanToken == cleanTarget) return true;

      // 3. Match normalized (unifying Alef / Yaa / Taa Marbuta)
      if (normToken == normTarget) return true;

      // 4. Handle conjunction proclitic 'و' or 'ف' (e.g. وَأَطُوفُ vs أَطُوفُ)
      if (cleanToken.startsWith('و') && cleanToken.length > 2) {
        final subClean = cleanToken.substring(1);
        if (subClean == cleanTarget || ArabicCliticStemmer.normalize(subClean) == normTarget) {
          return true;
        }
      }
      if (cleanToken.startsWith('ف') && cleanToken.length > 2) {
        final subClean = cleanToken.substring(1);
        if (subClean == cleanTarget || ArabicCliticStemmer.normalize(subClean) == normTarget) {
          return true;
        }
      }
    }

    return false;
  }

  /// Renders a discovery trigger sentence highlighting target grammatical verbs/words in bold red.
  /// Uses pure TextSpans to guarantee natural right-to-left word ordering without BiDi WidgetSpan permutation.
  Widget _buildDiscoveryTriggerSentence(String sentence, List<String> targetWords, double scale) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'([\u0600-\u06FF]+|[^\u0600-\u06FF]+)');
    final matches = regex.allMatches(sentence.trim());

    for (final match in matches) {
      final token = match.group(0) ?? '';
      if (token.isEmpty) continue;

      final isWord = RegExp(r'^[\u0600-\u06FF]+$').hasMatch(token);
      final isTarget = isWord && _isDiscoveryTargetWord(token, targetWords);

      if (isTarget) {
        spans.add(
          TextSpan(
            text: token,
            style: TextStyle(
              fontSize: 25 * scale,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFDC2626), // Bold crimson red for discovery target
              backgroundColor: const Color(0xFFFFECEC), // Soft pastel red background highlight
              height: 1.9,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: token,
            style: TextStyle(
              fontSize: 24 * scale,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
              height: 1.9,
            ),
          ),
        );
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
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
                    Icon(Icons.lightbulb_rounded, color: AppTheme.accentAmber, size: 28),
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
