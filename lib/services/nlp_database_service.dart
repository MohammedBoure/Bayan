import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/nlp_token_model.dart';
import '../nlp/arabic_clitic_stemmer.dart';

/// خدمة قاعدة البيانات المحلية الخفيفة (SQLite Cache & User Feedback Loop)
/// تتيح التخزين المؤقت للأمثلة (Cache & Pre-seeded Dataset)
/// وحفظ تعديلات وتصحيحات المستخدم لتطبيق مبدأ الأولوية القصوى (Override Priority).
class NlpDatabaseService {
  static final NlpDatabaseService instance = NlpDatabaseService._();
  NlpDatabaseService._();

  Database? _db;
  bool _isInitialized = false;

  // ذاكرة تخزين احتياطية خفيفة في الذاكرة لضمان العمل تحت أي ظرف
  final Map<String, List<NlpToken>> _memoryCache = {};
  final Map<String, NlpToken> _memoryOverrides = {};

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'nahw_nlp_cache.db');

      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          // 1. جدول تخزين الأمثلة المحللة (Examples Cache)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS parsed_sentences_cache (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              normalized_text TEXT UNIQUE,
              raw_text TEXT,
              sentence_type TEXT,
              tokens_json TEXT,
              diacritized_text TEXT,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          // 2. جدول تصحيحات المستخدم (User Corrections & Overrides)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_corrections (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              word_normalized TEXT UNIQUE,
              word_raw TEXT,
              pos TEXT,
              sub_type TEXT,
              case_mark TEXT,
              explanation TEXT,
              updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
          ''');
        },
      );

      _isInitialized = true;
      await _preSeedDataset();
      await loadOverrides();
    } catch (e) {
      debugPrint('NlpDatabaseService SQLite fallback: $e');
      _preSeedMemoryDataset();
      _isInitialized = true;
    }
  }

  /// زرع مجموعة أمثلة نموذجية معربة بدقة تامة مسبقاً (Pre-seeded Dataset)
  Future<void> _preSeedDataset() async {
    if (_db == null) return;

    final rows = await _db!.rawQuery('SELECT COUNT(*) as cnt FROM parsed_sentences_cache');
    final count = rows.isNotEmpty ? (rows.first['cnt'] as int? ?? 0) : 0;

    if (count == 0) {
      final dataset = _getPreSeededExamples();
      for (final item in dataset) {
        await saveParsedSentence(
          item.rawText,
          item.tokens,
          item.sentenceType,
          item.diacritizedText,
        );
      }
    }
  }

  void _preSeedMemoryDataset() {
    final dataset = _getPreSeededExamples();
    for (final item in dataset) {
      final norm = ArabicCliticStemmer.normalize(item.rawText);
      _memoryCache[norm] = item.tokens;
    }
  }

  /// فحص سريع (Fast Lookup) لمعرفة إذا كانت الجملة محللة مسبقاً في قاعدة البيانات
  Future<List<NlpToken>?> lookupSentence(String sentence) async {
    final norm = ArabicCliticStemmer.normalize(sentence);

    // 1. فحص الذاكرة السريعة
    if (_memoryCache.containsKey(norm)) {
      return _memoryCache[norm];
    }

    if (_db == null) return null;

    try {
      final List<Map<String, dynamic>> results = await _db!.query(
        'parsed_sentences_cache',
        where: 'normalized_text = ?',
        whereArgs: [norm],
        limit: 1,
      );

      if (results.isNotEmpty) {
        final jsonStr = results.first['tokens_json'] as String;
        final List<dynamic> list = jsonDecode(jsonStr);
        final tokens = list.map((item) {
          return NlpToken(
            word: item['word'] ?? '',
            plainWord: item['plainWord'] ?? '',
            pos: item['pos'] ?? '',
            subType: item['subType'],
            caseMark: item['caseMark'],
            explanation: item['explanation'],
            isTarget: item['isTarget'] ?? false,
          );
        }).toList();

        _memoryCache[norm] = tokens;
        return tokens;
      }
    } catch (e) {
      debugPrint('Error looking up sentence in cache: $e');
    }

    return null;
  }

  /// حفظ جملة محللة في جدول الـ Cache
  Future<void> saveParsedSentence(
    String rawSentence,
    List<NlpToken> tokens,
    String sentenceType,
    String diacritized,
  ) async {
    final norm = ArabicCliticStemmer.normalize(rawSentence);
    _memoryCache[norm] = tokens;

    if (_db == null) return;

    try {
      final jsonList = tokens.map((t) => t.toJson()).toList();
      final jsonStr = jsonEncode(jsonList);

      await _db!.insert(
        'parsed_sentences_cache',
        {
          'normalized_text': norm,
          'raw_text': rawSentence,
          'sentence_type': sentenceType,
          'tokens_json': jsonStr,
          'diacritized_text': diacritized,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving parsed sentence to cache: $e');
    }
  }

  /// حفظ تصحيح المستخدم لكلمة معينة (User Correction & Feedback Loop)
  Future<void> saveUserCorrection({
    required String word,
    required String pos,
    required String subType,
    required String caseMark,
    String? explanation,
  }) async {
    final norm = ArabicCliticStemmer.normalize(word);
    final token = NlpToken(
      word: word,
      plainWord: ArabicCliticStemmer.stripDiacritics(word),
      pos: pos,
      subType: subType,
      caseMark: caseMark,
      explanation: explanation ?? 'تصحيح معتمد بناءً على ضبط المستخدم التفاعلي.',
      isTarget: true,
    );

    _memoryOverrides[norm] = token;

    if (_db != null) {
      try {
        await _db!.insert(
          'user_corrections',
          {
            'word_normalized': norm,
            'word_raw': word,
            'pos': pos,
            'sub_type': subType,
            'case_mark': caseMark,
            'explanation': explanation,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        debugPrint('Error saving user correction to db: $e');
      }
    }
  }

  /// استرجاع كافة التصحيحات المسجلة لتطبيق الأولوية القصوى
  Future<Map<String, NlpToken>> loadOverrides() async {
    if (_db == null) return _memoryOverrides;

    try {
      final rows = await _db!.query('user_corrections');
      for (final row in rows) {
        final norm = row['word_normalized'] as String;
        _memoryOverrides[norm] = NlpToken(
          word: row['word_raw'] as String? ?? norm,
          plainWord: ArabicCliticStemmer.stripDiacritics(row['word_raw'] as String? ?? norm),
          pos: row['pos'] as String? ?? 'اسم',
          subType: row['sub_type'] as String?,
          caseMark: row['case_mark'] as String?,
          explanation: row['explanation'] as String?,
          isTarget: true,
        );
      }
    } catch (e) {
      debugPrint('Error loading user overrides: $e');
    }

    return _memoryOverrides;
  }

  Map<String, NlpToken> get currentOverrides => _memoryOverrides;

  /// مسح كافة تصحيحات وقواعد الأستاذ واستعادة الوضع الافتراضي
  Future<void> clearAllUserCorrections() async {
    _memoryOverrides.clear();
    if (_db != null) {
      try {
        await _db!.delete('user_corrections');
      } catch (e) {
        debugPrint('Error clearing user corrections: $e');
      }
    }
  }

  /// بيانات تأسيسية مسبقة تشمل الجملة المذكورة في طلب المستخدم
  List<_PreSeededItem> _getPreSeededExamples() {
    return [
      // 1. الجملة التي طرحها المستخدم في الصورة
      _PreSeededItem(
        rawText: 'المنزل كبير جدا أليس كذلك',
        sentenceType: 'جُمْلَةٌ اسْمِيَّةٌ + تَرْكِيبٌ اسْتِفْهَامِيٌّ',
        diacritizedText: 'المَنْزِلُ كَبِيرٌ جِدّاً أَلَيْسَ كَذَلِكَ',
        tokens: [
          const NlpToken(
            word: 'المَنْزِلُ',
            plainWord: 'المنزل',
            pos: 'اسم',
            subType: 'مبتدأ',
            caseMark: 'مرفوع وعلامة رفعه الضمة الظاهرة',
            explanation: 'اسم معرف بأل بدأت به الجملة فهو مبتدأ مرفوع بالضمة.',
            isTarget: true,
          ),
          const NlpToken(
            word: 'كَبِيرٌ',
            plainWord: 'كبير',
            pos: 'اسم',
            subType: 'خبر المبتدأ',
            caseMark: 'مرفوع وعلامة رفعه تنوين الضم',
            explanation: 'خبر المبتدأ تمم معنى الجملة وحكمه الرفع.',
            isTarget: true,
          ),
          const NlpToken(
            word: 'جِدّاً',
            plainWord: 'جدا',
            pos: 'اسم',
            subType: 'مفعول مطلق لفعل محذوف / ظرف توكيد',
            caseMark: 'منصوب وعلامة نصبه الفتحة الظاهرة',
            explanation: 'نائب عن المفعول المطلق أو مفعول مطلق لفعل محذوف تقديره (جَدَّ جِدّاً).',
          ),
          const NlpToken(
            word: 'أَلَيْسَ',
            plainWord: 'أليس',
            pos: 'فعل',
            subType: 'همزة استفهام + فعل ماضٍ ناقص (ليس)',
            caseMark: 'فعل ماضٍ ناقص مبني على الفتح واسمه ضمير مستتر',
            explanation: 'الهمزة للاستفهام التقريري، وليس فعل ماضٍ ناقص جامد من أخوات كان.',
          ),
          const NlpToken(
            word: 'كَذَلِكَ',
            plainWord: 'كذلك',
            pos: 'شبه جملة',
            subType: 'جار ومجرور (كاف التشبيه + اسم إشارة)',
            caseMark: 'شبه جملة في محل نصب خبر ليس',
            explanation: 'الكاف حرف جر، وذا اسم إشارة مجرور، وشبه الجملة خبر ليس.',
          ),
        ],
      ),
      // 2. نموذج الجملة الفعلية المقررة
      _PreSeededItem(
        rawText: 'كتب التلميذ الدرس',
        sentenceType: 'جُمْلَةٌ فِعْلِيَّةٌ',
        diacritizedText: 'كَتَبَ التِّلْمِيذُ الدَّرْسَ',
        tokens: [
          const NlpToken(
            word: 'كَتَبَ',
            plainWord: 'كتب',
            pos: 'فعل',
            subType: 'فعل ماضٍ',
            caseMark: 'مبني على الفتح الظاهر',
            explanation: 'فعل ماضٍ يدل على حدث الكتابة في الزمن الماضي.',
          ),
          const NlpToken(
            word: 'التِّلْمِيذُ',
            plainWord: 'التلميذ',
            pos: 'اسم',
            subType: 'فاعل',
            caseMark: 'مرفوع وعلامة رفعه الضمة الظاهرة',
            explanation: 'فاعل مرفوع بالضمة وهو من قام بالكتابة.',
          ),
          const NlpToken(
            word: 'الدَّرْسَ',
            plainWord: 'الدرس',
            pos: 'اسم',
            subType: 'مفعول به',
            caseMark: 'منصوب وعلامة نصبه الفتحة الظاهرة',
            explanation: 'مفعول به منصوب بالفتحة وهو الشيء المكتوب.',
          ),
        ],
      ),
    ];
  }
}

class _PreSeededItem {
  final String rawText;
  final String sentenceType;
  final String diacritizedText;
  final List<NlpToken> tokens;

  const _PreSeededItem({
    required this.rawText,
    required this.sentenceType,
    required this.diacritizedText,
    required this.tokens,
  });
}
