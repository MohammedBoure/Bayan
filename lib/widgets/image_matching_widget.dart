import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Image Verb Matching Widget pairing verbs with visual action descriptions.
class ImageMatchingWidget extends StatefulWidget {
  final Map<String, String> pairs;
  final ValueChanged<bool> onValidationChanged;

  const ImageMatchingWidget({
    super.key,
    required this.pairs,
    required this.onValidationChanged,
  });

  @override
  State<ImageMatchingWidget> createState() => _ImageMatchingWidgetState();
}

class _ImageMatchingWidgetState extends State<ImageMatchingWidget> {
  late Map<String, String?> _selectedPairs;
  String? _selectedVerb;

  @override
  void initState() {
    super.initState();
    _selectedPairs = {for (var verb in widget.pairs.keys) verb: null};
  }

  @override
  void didUpdateWidget(ImageMatchingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pairs != widget.pairs) {
      _selectedPairs = {for (var verb in widget.pairs.keys) verb: null};
      _selectedVerb = null;
    }
  }

  void _onVerbTapped(String verb) {
    setState(() {
      _selectedVerb = (_selectedVerb == verb) ? null : verb;
    });
  }

  void _onTargetTapped(String targetDescription) {
    if (_selectedVerb == null) return;

    setState(() {
      // Remove this description from any other verb
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

  @override
  Widget build(BuildContext context) {
    final verbs = widget.pairs.keys.toList();
    final descriptions = widget.pairs.values.toList()..shuffle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: const [
              Icon(Icons.touch_app_rounded, color: AppTheme.verbColor, size: 28),
              SizedBox(width: 8),
              Text(
                'اخْتَرِ الفِعْلَ ثُمَّ انْقُرْ عَلَى الصُّورَةِ المُنَاسِبَةِ لِمُطَابَقَتِهِمَا:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Verbs Grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: verbs.map((verb) {
            final isSelected = _selectedVerb == verb;
            final matchedWith = _selectedPairs[verb];

            return InkWell(
              onTap: () => _onVerbTapped(verb),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accentAmber
                      : (matchedWith != null ? AppTheme.primaryLight : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.accentOrange : (matchedWith != null ? AppTheme.primaryTeal : const Color(0xFFCBD5E1)),
                    width: 2.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      matchedWith != null ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: matchedWith != null ? AppTheme.primaryTeal : AppTheme.textMuted,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      verb,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Target Descriptions / Illustrations
        Column(
          children: descriptions.map((desc) {
            String? assignedVerb;
            for (var entry in _selectedPairs.entries) {
              if (entry.value == desc) {
                assignedVerb = entry.key;
                break;
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _onTargetTapped(desc),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: assignedVerb != null ? AppTheme.primaryLight : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: assignedVerb != null ? AppTheme.primaryTeal : const Color(0xFFCBD5E1),
                      width: assignedVerb != null ? 2.5 : 1.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.image_rounded, color: AppTheme.accentOrange, size: 36),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          desc,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                      ),
                      if (assignedVerb != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            assignedVerb,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        )
                      else
                        Text(
                          _selectedVerb != null ? 'انقر لربط "$_selectedVerb"' : 'انقر للربط',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedVerb != null ? AppTheme.primaryTeal : Colors.grey.shade400,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
