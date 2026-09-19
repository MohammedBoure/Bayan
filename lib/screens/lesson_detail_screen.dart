import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../models/reading_passage_model.dart';
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
  int _vocabFilter = 0; // 0 = الكل, 1 = المعاني والمفردات, 2 = الكلمة وضدها
  final Set<int> _revealedQuestionIndices = <int>{};
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
      for (int i = 0; i < widget.lesson.readingPassage!.comprehensionQuestions.length; i++) {
        _revealedQuestionIndices.add(i);
      }
    }
    if (widget.lesson.readingPassage?.hasAudio == true) {
      _audioHighlightedParagraphs = widget.lesson.readingPassage!.audioTracks.first.paragraphIndices;
    }
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
            final total = widget.lesson.readingPassage?.comprehensionQuestions.length ?? 0;
            _toggleAllComprehensionAnswers(total);
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

  // 2. كلماتي الجديدة (منظمة ومفروزة بدقة بين شرح المعاني والكلمة وضدها)
  Widget _buildStageVocabulary(double scale, ReadingPassageModel passage) {
    final meanings = passage.vocabulary.where((v) => !v.isAntonym).toList();
    final antonyms = passage.vocabulary.where((v) => v.isAntonym).toList();

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
                        'مُفْرَدَاتُ النَّصِّ مُصَنَّفَةٌ بَيْنَ شَرْحِ المَعَانِي وَالأَضْدَادِ',
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
                    label: 'الكُلُّ (${passage.vocabulary.length})',
                    icon: Icons.grid_view_rounded,
                    index: 0,
                    scale: scale,
                  ),
                  const SizedBox(width: 8),
                  _buildVocabFilterChip(
                    label: 'شَرْحُ المَعَانِي (${meanings.length})',
                    icon: Icons.lightbulb_outline_rounded,
                    index: 1,
                    scale: scale,
                    activeColor: AppTheme.primaryTeal,
                  ),
                  const SizedBox(width: 8),
                  _buildVocabFilterChip(
                    label: 'الْكَلِمَةُ وَضِدُّهَا (${antonyms.length})',
                    icon: Icons.compare_arrows_rounded,
                    index: 2,
                    scale: scale,
                    activeColor: AppTheme.accentCoral,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // القسم الأول: شرح المفردات والمعاني
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
                  '📖 شَرْحُ الْمُفْرَدَاتِ وَمَعَانِي الْكَلِمَاتِ (${meanings.length})',
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
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: meanings.map((vocab) => _buildMeaningCard(vocab, scale)).toList(),
          ),
          const SizedBox(height: 22),
        ],

        // القسم الثاني: الكلمة وضدها
        if ((_vocabFilter == 0 || _vocabFilter == 2) && antonyms.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.accentCoral.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
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
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: antonyms.map((vocab) => _buildAntonymCard(vocab, scale)).toList(),
          ),
        ],
      ],
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

  // بطاقة شرح المعنى (تصميم زمردي مريح للعين مع تحليل صرفي اختياري)
  Widget _buildMeaningCard(VocabularyItem vocab, double scale) {
    return Container(
      width: 380,
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
              Text(
                vocab.word,
                style: TextStyle(
                  fontSize: 26 * scale,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryTeal,
                ),
              ),
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

  // بطاقة الكلمة وضدها (تصميم مرجاني مميز مع إبراز التقابل اللغوي «الكلمة» ⟷ ≠ ⟷ «الضد»)
  Widget _buildAntonymCard(VocabularyItem vocab, double scale) {
    // تنظيف صيغة الضد إذا كانت مكتوبة كـ "ضدها: ..."
    String cleanExplanation = vocab.explanation;
    final regex = RegExp(r'ضِدُّهَا(?:\s+فِي\s+(?:النَّصِّ|المَعْنَى))?\s*:\s*', unicode: true);
    final match = regex.firstMatch(cleanExplanation);
    String oppositeWord = cleanExplanation;
    if (match != null) {
      oppositeWord = cleanExplanation.substring(match.end).replaceAll('.', '').trim();
    }

    return Container(
      width: 380,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.4), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentCoral.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'الكَلِمَةُ وَضِدُّهَا',
                  style: TextStyle(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentCoral,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // بطاقة المقابلة البصرية بين الكلمة وضدها
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.accentCoral.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Text(
                    vocab.word,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24 * scale,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCoral,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '≠ ضِدُّ',
                    style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    oppositeWord,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24 * scale,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.accentCoral,
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
