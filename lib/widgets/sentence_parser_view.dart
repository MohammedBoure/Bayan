import 'package:flutter/material.dart';
import '../models/nlp_token_model.dart';
import '../theme/app_theme.dart';

/// Interactive linguistic sentence parser component.
/// Shows sentence tokens as clickable interactive words, allowing pupils
/// to explore syntactic structures, grammatical cases, and morphological explanations.
class SentenceParserView extends StatefulWidget {
  final List<NlpToken> tokens;
  final bool showTashkeel;
  final String title;

  const SentenceParserView({
    super.key,
    required this.tokens,
    this.showTashkeel = true,
    this.title = 'المثال التفاعلي (انقر على الكلمة لمعرفة إعرابها):',
  });

  @override
  State<SentenceParserView> createState() => _SentenceParserViewState();
}

class _SentenceParserViewState extends State<SentenceParserView> {
  int? _selectedTokenIndex;

  @override
  void initState() {
    super.initState();
    // Default select first token (usually the verb)
    if (widget.tokens.isNotEmpty) {
      _selectedTokenIndex = 0;
    }
  }

  Color _getTokenColor(NlpToken token) {
    if (token.pos == 'فعل') return AppTheme.verbColor;
    if (token.subType?.contains('فاعل') == true) return AppTheme.subjectColor;
    if (token.subType?.contains('مفعول') == true) return AppTheme.objectColor;
    if (token.pos == 'حرف') return AppTheme.particleColor;
    return AppTheme.primaryTeal;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.2)),
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
            children: [
              const Icon(Icons.psychology_alt_rounded, color: AppTheme.primaryTeal, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal word tags
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
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
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color,
                      width: isSelected ? 2.5 : 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayWord,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        token.subType ?? token.pos,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white.withValues(alpha: 0.9) : color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  token.word,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'النوع: ${token.pos} (${token.subType ?? ""})',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (token.caseMark != null && token.caseMark!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'الإعراب: ${token.caseMark}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
          ],
          if (token.explanation != null && token.explanation!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              token.explanation!,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
