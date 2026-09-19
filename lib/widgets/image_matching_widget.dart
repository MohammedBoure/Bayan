import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Interactive Visual Matching Engine (آلية الربط البصري التفاعلي الحقيقي للأنشطة)
/// Displays two columns:
/// - Right Column: Verb Cards with interactive connecting plugs (نقاط الوصل)
/// - Left Column: Rich Illustrated Action Image Cards with connecting plugs
/// Supports authentic classroom matching with visual line feedback and clear connection indicators.
class ImageMatchingWidget extends StatefulWidget {
  final Map<String, String> pairs;
  final ValueChanged<bool> onValidationChanged;
  final Map<String, String>? imagePaths;

  const ImageMatchingWidget({
    super.key,
    required this.pairs,
    required this.onValidationChanged,
    this.imagePaths,
  });

  @override
  State<ImageMatchingWidget> createState() => _ImageMatchingWidgetState();
}

class _ImageMatchingWidgetState extends State<ImageMatchingWidget> {
  late Map<String, String?> _selectedPairs;
  String? _selectedVerb;
  late List<String> _shuffledDescriptions;

  // Distinct pedagogical pastel colors for active connections
  static const List<Color> _connectionColors = [
    Color(0xFF0D9488), // Teal
    Color(0xFFE11D48), // Rose
    Color(0xFFD97706), // Amber
    Color(0xFF7C3AED), // Violet
    Color(0xFF2563EB), // Blue
    Color(0xFF059669), // Emerald
  ];

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  @override
  void didUpdateWidget(ImageMatchingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pairs != widget.pairs) {
      _initEngine();
    }
  }

  void _initEngine() {
    _selectedPairs = {for (var verb in widget.pairs.keys) verb: null};
    _selectedVerb = null;
    final descs = widget.pairs.values.toList();
    descs.shuffle();
    _shuffledDescriptions = descs;
  }

  void _onVerbTapped(String verb) {
    setState(() {
      if (_selectedVerb == verb) {
        _selectedVerb = null;
      } else {
        _selectedVerb = verb;
      }
    });
  }

  void _onTargetTapped(String targetDescription) {
    if (_selectedVerb == null) {
      // If no verb selected, check if this target is already assigned to unbind or select its verb
      String? currentVerb;
      for (var entry in _selectedPairs.entries) {
        if (entry.value == targetDescription) {
          currentVerb = entry.key;
          break;
        }
      }
      if (currentVerb != null) {
        setState(() {
          _selectedPairs[currentVerb!] = null;
        });
        _validate();
      }
      return;
    }

    setState(() {
      // Remove this description if already paired elsewhere
      for (var v in _selectedPairs.keys) {
        if (_selectedPairs[v] == targetDescription) {
          _selectedPairs[v] = null;
        }
      }
      _selectedPairs[_selectedVerb!] = targetDescription;
      _selectedVerb = null;
    });

    _validate();
  }

  void _unlinkVerb(String verb) {
    setState(() {
      _selectedPairs[verb] = null;
      if (_selectedVerb == verb) _selectedVerb = null;
    });
    _validate();
  }

  void _validate() {
    bool allMatched = true;
    for (var entry in widget.pairs.entries) {
      if (_selectedPairs[entry.key] != entry.value) {
        allMatched = false;
        break;
      }
    }
    widget.onValidationChanged(allMatched);
  }

  Color _getColorForIndex(int idx) {
    return _connectionColors[idx % _connectionColors.length];
  }

  Color? _getColorForVerb(String verb) {
    final verbs = widget.pairs.keys.toList();
    final idx = verbs.indexOf(verb);
    if (idx >= 0 && _selectedPairs[verb] != null) {
      return _getColorForIndex(idx);
    }
    return null;
  }

  Color? _getColorForDesc(String desc) {
    final verbs = widget.pairs.keys.toList();
    for (int i = 0; i < verbs.length; i++) {
      if (_selectedPairs[verbs[i]] == desc) {
        return _getColorForIndex(i);
      }
    }
    return null;
  }

  String? _getImagePath(String desc) {
    if (widget.imagePaths != null && widget.imagePaths!.containsKey(desc)) {
      return widget.imagePaths![desc];
    }
    // Fallback dictionary for common Grade 3 verbs
    if (desc.contains('طعام') || desc.contains('يأكل') || desc.contains('أكل')) {
      return 'assets/images/action_eat.jpg';
    }
    if (desc.contains('ماء') || desc.contains('يشرب') || desc.contains('شرب')) {
      return 'assets/images/action_drink.jpg';
    }
    if (desc.contains('سرير') || desc.contains('نائم') || desc.contains('نام')) {
      return 'assets/images/action_sleep.jpg';
    }
    if (desc.contains('يركض') || desc.contains('ملعب') || desc.contains('ركض')) {
      return 'assets/images/action_run.jpg';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final verbs = widget.pairs.keys.toList();
    final matchedCount = _selectedPairs.values.where((v) => v != null).length;
    final totalCount = verbs.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pedagogical instructions header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cable_rounded, color: AppTheme.accentOrange, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'آلِيَّةُ الرَّبْطِ التَّفَاعُلِيِّ (صِلْ بَيْنَ الفِعْلِ وَالصُّورَةِ):',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'انْقُرْ عَلَى الفِعْلِ أَوَّلاً، ثُمَّ انْقُرْ عَلَى الصُّورَةِ المُنَاسِبَةِ الَّتِي تُمَثِّلُهُ لِرَبْطِهِمَا مَعاً.',
                      style: TextStyle(fontSize: 14, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: matchedCount == totalCount ? AppTheme.successGreen : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'المَرْبُوطُ: $matchedCount مِنْ $totalCount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: matchedCount == totalCount ? Colors.white : AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Two-Column Interactive Matching Canvas
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Right Column: Verbs (الأفعال)
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildColumnHeader('1. قَائِمَةُ الأَفْعَالِ', Icons.flash_on_rounded, AppTheme.primaryTeal),
                        const SizedBox(height: 12),
                        ...verbs.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final verb = entry.value;
                          return _buildVerbCard(verb, idx);
                        }),
                      ],
                    ),
                  ),

                  // Center Linking Graphic
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
                    child: Column(
                      children: List.generate(
                        verbs.length,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Icon(
                            Icons.compare_arrows_rounded,
                            size: 32,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Left Column: Pictures & Action Descriptions (الصور والدلالات)
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildColumnHeader('2. الصُّوَرُ التَّعْبِيرِيَّةُ المُنَاسِبَةُ', Icons.image_rounded, AppTheme.accentOrange),
                        const SizedBox(height: 12),
                        ..._shuffledDescriptions.map((desc) => _buildTargetCard(desc)),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // Compact column mode
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildColumnHeader('1. قَائِمَةُ الأَفْعَالِ', Icons.flash_on_rounded, AppTheme.primaryTeal),
                  const SizedBox(height: 12),
                  ...verbs.asMap().entries.map((entry) => _buildVerbCard(entry.value, entry.key)),
                  const SizedBox(height: 24),
                  _buildColumnHeader('2. الصُّوَرُ التَّعْبِيرِيَّةُ المُنَاسِبَةُ', Icons.image_rounded, AppTheme.accentOrange),
                  const SizedBox(height: 12),
                  ..._shuffledDescriptions.map((desc) => _buildTargetCard(desc)),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildColumnHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildVerbCard(String verb, int index) {
    final isSelected = _selectedVerb == verb;
    final matchedDesc = _selectedPairs[verb];
    final color = _getColorForVerb(verb) ?? AppTheme.primaryTeal;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _onVerbTapped(verb),
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accentAmber.withValues(alpha: 0.15)
                : (matchedDesc != null ? color.withValues(alpha: 0.08) : Colors.white),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? AppTheme.accentOrange
                  : (matchedDesc != null ? color : const Color(0xFFCBD5E1)),
              width: isSelected || matchedDesc != null ? 3.0 : 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppTheme.accentOrange.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Verb badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentOrange : (matchedDesc != null ? color : const Color(0xFFF1F5F9)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: matchedDesc != null
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 26)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Verb Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verb,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? AppTheme.accentOrange : (matchedDesc != null ? color : AppTheme.textDark),
                      ),
                    ),
                    if (matchedDesc != null)
                      Text(
                        'مَرْبُوطٌ مَعَ: $matchedDesc',
                        style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Linking Plug / Indicator
              if (matchedDesc != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22, color: Colors.grey),
                  tooltip: 'فَكُّ الرَّبْطِ',
                  onPressed: () => _unlinkVerb(verb),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accentOrange : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.radio_button_checked_rounded,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSelected ? 'اخْتَرْ صُورَةً' : 'انْقُرْ لِلرَّبْطِ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetCard(String desc) {
    String? assignedVerb;
    for (var entry in _selectedPairs.entries) {
      if (entry.value == desc) {
        assignedVerb = entry.key;
        break;
      }
    }

    final isAssigned = assignedVerb != null;
    final color = _getColorForDesc(desc) ?? AppTheme.primaryTeal;
    final imageAsset = _getImagePath(desc);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _onTargetTapped(desc),
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isAssigned ? color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isAssigned ? color : const Color(0xFFCBD5E1),
              width: isAssigned ? 3.0 : 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: isAssigned ? color.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Picture / Illustration thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 100,
                  height: 75,
                  child: imageAsset != null
                      ? Image.asset(
                          imageAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.amber.shade100,
                            child: const Icon(Icons.image_rounded, size: 40, color: AppTheme.accentOrange),
                          ),
                        )
                      : Container(
                          color: Colors.blue.shade50,
                          child: const Icon(Icons.image_rounded, size: 40, color: AppTheme.verbColor),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Description Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isAssigned)
                      Row(
                        children: [
                          Icon(Icons.link_rounded, size: 18, color: color),
                          const SizedBox(width: 6),
                          Text(
                            'مَرْبُوطٌ بِالفِعْلِ: «$assignedVerb»',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        _selectedVerb != null ? 'انْقُرْ هُنَا لِرَبْطِ «$_selectedVerb»' : 'انْقُرْ لِتَحْدِيدِ الرَّبْطِ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _selectedVerb != null ? AppTheme.accentOrange : Colors.grey.shade400,
                        ),
                      ),
                  ],
                ),
              ),

              // Plug Connection Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isAssigned ? color : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAssigned ? Icons.check_circle_rounded : Icons.cable_rounded,
                      size: 20,
                      color: isAssigned ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAssigned ? assignedVerb : 'غَيْرُ مَرْبُوطٍ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isAssigned ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
