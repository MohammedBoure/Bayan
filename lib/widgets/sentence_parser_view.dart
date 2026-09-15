import 'package:flutter/material.dart';
import '../models/nlp_token_model.dart';
import '../theme/app_theme.dart';

/// Interactive linguistic sentence parser component tailored for Classroom Data Show projection.
/// Displays massive, high-visibility interactive word tokens that children can easily see from
/// across a lecture room, with color-coded syntax roles and an expansive inspector card.
class SentenceParserView extends StatefulWidget {
  final List<NlpToken> tokens;
  final bool showTashkeel;
  final String title;
  final void Function(NlpToken token)? onEditToken;

  const SentenceParserView({
    super.key,
    required this.tokens,
    this.showTashkeel = true,
    this.title = 'المثال التفاعلي (انقر على الكلمة لعرض إعرابها على شاشة الصف):',
    this.onEditToken,
  });

  @override
  State<SentenceParserView> createState() => _SentenceParserViewState();
}

class _SentenceParserViewState extends State<SentenceParserView> {
  int? _selectedTokenIndex;

  @override
  void initState() {
    super.initState();
    if (widget.tokens.isNotEmpty) {
      _selectedTokenIndex = 0;
    }
  }

  Color _getTokenColor(NlpToken token) {
    if (token.pos == 'فعل') return AppTheme.verbColor;
    if (token.subType?.contains('فاعل') == true || token.subType?.contains('مبتدأ') == true) {
      return AppTheme.subjectColor;
    }
    if (token.subType?.contains('مفعول') == true || token.subType?.contains('خبر') == true) {
      return AppTheme.objectColor;
    }
    if (token.pos == 'حرف') return AppTheme.particleColor;
    return AppTheme.primaryTeal;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title
          Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: AppTheme.primaryTeal, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Horizontal Big Word Chips - Widescreen Layout
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: List.generate(widget.tokens.length, (index) {
              final token = widget.tokens[index];
              final isSelected = _selectedTokenIndex == index;
              final color = _getTokenColor(token);
              final displayWord = widget.showTashkeel ? token.word : token.plainWord;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTokenIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: color,
                      width: isSelected ? 3.5 : 2.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayWord,
                        style: TextStyle(
                          fontSize: 32, // Large font for classroom projector readability
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.black.withValues(alpha: 0.25)
                              : color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          token.subType ?? token.pos,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 24),
          const Divider(height: 2, thickness: 1.5),
          const SizedBox(height: 20),

          // Detail Card for selected token
          if (_selectedTokenIndex != null && _selectedTokenIndex! < widget.tokens.length) ...[
            _buildTokenDetailCard(widget.tokens[_selectedTokenIndex!]),
          ],
        ],
      ),
    );
  }

  Widget _buildTokenDetailCard(NlpToken token) {
    final color = _getTokenColor(token);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  token.word,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24, // Very prominent for pupils
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'النوع: ${token.pos} | ${token.subType ?? ""}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          if (token.caseMark != null && token.caseMark!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الإِعْرَابُ: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: AppTheme.textDark,
                  ),
                ),
                Expanded(
                  child: Text(
                    token.caseMark!,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (token.explanation != null && token.explanation!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              token.explanation!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
                height: 1.6,
              ),
            ),
          ],
          if (widget.onEditToken != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => widget.onEditToken!(token),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  side: BorderSide(color: color, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(Icons.edit_note_rounded, size: 22, color: color),
                label: Text(
                  'تَصْحِيحُ إِعْرَابِ الكَلِمَةِ فِي قَاعِدَةِ البَيَانَاتِ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
