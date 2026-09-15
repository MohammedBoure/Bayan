/// Represents a tokenized Arabic word with linguistic, syntactic, and morphological annotations.
class NlpToken {
  final String word; // Word with tashkeel
  final String plainWord; // Word without diacritics
  final String pos; // Part of speech: فعل، اسم، حرف
  final String? subType; // e.g. ماض، مضارع، أمر، فاعل، مفعول به، اسم مجرور
  final String? caseMark; // e.g. مرفوع بالضمة، منصوب بالفتحة، مجرور بالكسرة، مبني على الفتح
  final String? explanation; // Educational pedagogical explanation
  final bool isTarget; // If this token is the focus of an interactive question

  const NlpToken({
    required this.word,
    required this.plainWord,
    required this.pos,
    this.subType,
    this.caseMark,
    this.explanation,
    this.isTarget = false,
  });

  Map<String, dynamic> toJson() => {
    'word': word,
    'plainWord': plainWord,
    'pos': pos,
    'subType': subType,
    'caseMark': caseMark,
    'explanation': explanation,
    'isTarget': isTarget,
  };
}
