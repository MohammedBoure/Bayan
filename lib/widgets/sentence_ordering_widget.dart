import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Sentence Ordering Widget allowing students to arrange shuffled word chips
/// to assemble a valid verbal sentence (فعل + فاعل + مفعول به).
class SentenceOrderingWidget extends StatefulWidget {
  final List<String> initialWords;
  final List<String> targetSequence;
  final ValueChanged<bool> onValidationChanged;

  const SentenceOrderingWidget({
    super.key,
    required this.initialWords,
    required this.targetSequence,
    required this.onValidationChanged,
  });

  @override
  State<SentenceOrderingWidget> createState() => _SentenceOrderingWidgetState();
}

class _SentenceOrderingWidgetState extends State<SentenceOrderingWidget> {
  late List<String> _currentWords;

  @override
  void initState() {
    super.initState();
    _currentWords = List.from(widget.initialWords);
    _validate();
  }

  @override
  void didUpdateWidget(SentenceOrderingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialWords != widget.initialWords) {
      _currentWords = List.from(widget.initialWords);
      _validate();
    }
  }

  void _validate() {
    bool isMatch = _currentWords.length == widget.targetSequence.length;
    if (isMatch) {
      for (int i = 0; i < _currentWords.length; i++) {
        if (_currentWords[i] != widget.targetSequence[i]) {
          isMatch = false;
          break;
        }
      }
    }
    widget.onValidationChanged(isMatch);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryTeal, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.swap_horiz_rounded, color: AppTheme.verbColor, size: 30),
              SizedBox(width: 10),
              Text(
                'اسْحَبْ وَرَتِّبِ الكَلِمَاتِ لِتَبْدَأَ بِالفِعْلِ المُضَارِعِ:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Reorderable Chips Wrap / List
          SizedBox(
            height: 90,
            child: ReorderableListView(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: true,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final item = _currentWords.removeAt(oldIndex);
                  _currentWords.insert(newIndex, item);
                });
                _validate();
              },
              children: _currentWords.asMap().entries.map((entry) {
                final idx = entry.key;
                final word = entry.value;
                return Container(
                  key: ValueKey(word),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.primaryTeal, width: 2.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.primaryTeal,
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        word,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.drag_indicator_rounded, color: AppTheme.primaryTeal, size: 24),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),
          // Preview of the sentence assembled
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('الجُمْلَةُ المُرَتَّبَةُ: ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                Text(
                  _currentWords.join(' '),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryTeal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
