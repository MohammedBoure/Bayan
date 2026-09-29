import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Interactive Visual Matching Engine (آلية الربط البصري التفاعلي الحقيقي للأنشطة)
/// Displays two columns:
/// - Right Column: Verb Cards with interactive connecting plugs (نقاط الوصل)
/// - Left Column: Prominent, high-resolution illustrated Action Image Cards with quick-zoom and connection indicators
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
    if (widget.imagePaths != null) {
      if (widget.imagePaths!.containsKey(desc)) {
        return widget.imagePaths![desc];
      }
      for (final entry in widget.imagePaths!.entries) {
        if (desc.contains(entry.key) || entry.key.contains(desc)) {
          return entry.value;
        }
      }
    }
    // High-resolution authentic classroom illustrations for Grade 3 Lesson 1 (3_1)
    if (desc.contains('يأكل') || desc.contains('أكل') || desc.contains('طعام')) {
      return 'assets/images/3_1/طفل يأكل.jpg';
    }
    if (desc.contains('يشرب') || desc.contains('شرب') || desc.contains('ماء') || desc.contains('حليب')) {
      return 'assets/images/3_1/طفل يشرب.jpg';
    }
    if (desc.contains('نائم') || desc.contains('نام') || desc.contains('سرير')) {
      return 'assets/images/3_1/طفل نائم.jpg';
    }
    if (desc.contains('يركض') || desc.contains('ركض') || desc.contains('ملعب')) {
      return 'assets/images/3_1/طفل يركض.jpg';
    }
    return null;
  }

  /// Displays high-definition enlarged image dialog for classroom presentation
  void _showEnlargedImage(BuildContext context, String title, String? imageAsset) {
    if (imageAsset == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 960),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.zoom_in_rounded, color: AppTheme.accentOrange, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'مُعَايَنَةٌ بَصَرِيَّةٌ مُكَبَّرَةٌ: $title',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 28),
                    tooltip: 'إِغْلَاق',
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                  label: const Text(
                    'حَسَنًا، فَهِمْتُ المَعْنَى',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
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
            final isWide = constraints.maxWidth > 780;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Right Column: Verbs (الأفعال)
                  Expanded(
                    flex: 4,
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 36),
                    child: Column(
                      children: List.generate(
                        verbs.length,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Icon(
                            Icons.compare_arrows_rounded,
                            size: 32,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Left Column: Pictures & Action Descriptions (الصور والدلالات) in 2x2 Grid
                  Expanded(
                    flex: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildColumnHeader('2. الصُّوَرُ التَّعْبِيرِيَّةُ المُنَاسِبَةُ (انْقُرْ لِلرَّبْطِ أَوِ التَّكْبِيرِ)', Icons.image_rounded, AppTheme.accentOrange),
                        const SizedBox(height: 12),
                        _buildImagesGrid(),
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

  /// Builds a responsive, large 2x2 grid for images
  Widget _buildImagesGrid() {
    final rows = <Widget>[];
    for (int i = 0; i < _shuffledDescriptions.length; i += 2) {
      final desc1 = _shuffledDescriptions[i];
      final desc2 = (i + 1 < _shuffledDescriptions.length) ? _shuffledDescriptions[i + 1] : null;

      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildTargetCard(desc1)),
            const SizedBox(width: 14),
            if (desc2 != null)
              Expanded(child: _buildTargetCard(desc2))
            else
              const Spacer(),
          ],
        ),
      );
      if (i + 2 < _shuffledDescriptions.length) {
        rows.add(const SizedBox(height: 14));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
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
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color),
              overflow: TextOverflow.ellipsis,
            ),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentOrange : (matchedDesc != null ? color : const Color(0xFFF1F5F9)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: matchedDesc != null
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 20,
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
                        fontSize: 28,
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
                  icon: const Icon(Icons.close_rounded, size: 24, color: Colors.grey),
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

  /// Builds a large, prominent, high-resolution Action Image Card
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
      child: Material(
        color: Colors.transparent,
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
                color: isAssigned
                    ? color
                    : (_selectedVerb != null ? AppTheme.accentOrange.withValues(alpha: 0.6) : const Color(0xFFCBD5E1)),
                width: isAssigned ? 3.0 : (_selectedVerb != null ? 2.5 : 1.8),
              ),
              boxShadow: [
                BoxShadow(
                  color: isAssigned ? color.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Large, Crisp Illustration Container with 16:9 ratio and Quick Zoom Overlay
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: imageAsset != null
                            ? Image.asset(
                                imageAsset,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.amber.shade100,
                                  child: const Center(
                                    child: Icon(Icons.image_rounded, size: 50, color: AppTheme.accentOrange),
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.blue.shade50,
                                child: const Center(
                                  child: Icon(Icons.image_rounded, size: 50, color: AppTheme.verbColor),
                                ),
                              ),
                      ),
                    ),

                    // Quick Zoom Button Overlay
                    if (imageAsset != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Tooltip(
                          message: 'تَكْبِيرُ الصُّورَةِ مِلْءَ الشَّاشَةِ',
                          child: InkWell(
                            onTap: () => _showEnlargedImage(context, desc, imageAsset),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.zoom_in_rounded, size: 18, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'تَكْبِيرٌ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Assignment Ribbon
                    if (isAssigned)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                assignedVerb,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Action Description Label & Connection Indicator
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            desc,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isAssigned)
                            Text(
                              'مَرْبُوطٌ بِالفِعْلِ: «$assignedVerb»',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            )
                          else
                            Text(
                              _selectedVerb != null
                                  ? 'انْقُرْ هُنَا لِرَبْطِ «$_selectedVerb»'
                                  : 'انْقُرْ لِتَحْدِيدِ الرَّبْطِ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedVerb != null ? AppTheme.accentOrange : Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Connection Plug / Button
                    if (isAssigned)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22, color: Colors.grey),
                        tooltip: 'فَكُّ الرَّبْطِ',
                        onPressed: () {
                          setState(() {
                            _selectedPairs[assignedVerb!] = null;
                          });
                          _validate();
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedVerb != null ? AppTheme.accentOrange : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedVerb != null ? AppTheme.accentOrange : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.link_rounded,
                              size: 18,
                              color: _selectedVerb != null ? Colors.white : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedVerb != null ? 'ارْبِطْ' : 'وَصْل',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: _selectedVerb != null ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
