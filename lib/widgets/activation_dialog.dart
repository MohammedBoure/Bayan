import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/license_service.dart';
import '../theme/app_theme.dart';

/// Modal dialog allowing the user to view their unique Device Code,
/// copy it to send to the developer, and enter their Activation Key.
class ActivationDialog extends StatefulWidget {
  final LicenseService licenseService;

  const ActivationDialog({
    super.key,
    required this.licenseService,
  });

  /// Static helper to display the activation dialog
  static Future<bool?> show(BuildContext context, LicenseService licenseService) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: licenseService.canAccessCurriculum,
      builder: (_) => ActivationDialog(licenseService: licenseService),
    );
  }

  @override
  State<ActivationDialog> createState() => _ActivationDialogState();
}

class _ActivationDialogState extends State<ActivationDialog> {
  late final TextEditingController _keyController;
  String? _errorMessage;
  bool _isSuccess = false;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.licenseService.deviceCode));
    setState(() => _isCopied = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تَمَّ نَسْخُ كَوْدِ الجِهَازِ إِلَى الحَافِظَةِ بِنَجَاحٍ.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  Future<void> _handleActivate() async {
    final text = _keyController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'يُرْجَى إِدْخَالُ كَوْدِ التَّفْعِيلِ.');
      return;
    }

    final success = await widget.licenseService.activate(text);
    if (success) {
      setState(() {
        _isSuccess = true;
        _errorMessage = null;
      });
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        _errorMessage = 'كَوْدُ التَّفْعِيلِ غَيْرُ صَحِيحٍ لِهَذَا الجِهَازِ. يُرْجَى التَّأَكُّدُ مِنَ الرَّمْزِ.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = widget.licenseService.isTrialExpired;
    final isActivated = widget.licenseService.isActivated;
    final days = widget.licenseService.daysRemaining;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActivated
                    ? AppTheme.successGreen.withValues(alpha: 0.12)
                    : isExpired
                        ? AppTheme.errorRed.withValues(alpha: 0.12)
                        : AppTheme.accentAmber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActivated
                    ? Icons.verified_rounded
                    : isExpired
                        ? Icons.lock_clock_rounded
                        : Icons.key_rounded,
                color: isActivated
                    ? AppTheme.successGreen
                    : isExpired
                        ? AppTheme.errorRed
                        : AppTheme.accentOrange,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                isActivated
                    ? 'تَفْعِيلُ النُّسْخَةِ الدَّائِمَةِ'
                    : isExpired
                        ? 'انْتِهَاءُ الفَتْرَةِ التَّجْرِيبِيَّةِ'
                        : 'تَفْعِيلُ بَرْنَامِجِ بُسْتَانِ النَّحْوِ',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Status Banner
                if (_isSuccess || isActivated) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.successGreen, width: 1.5),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'تَمَّ تَفْعِيلُ البَرْنَامِجِ بِنَجَاحٍ! جَمِيعُ دُرُوسِ المِنْهَاجِ وَالأَنْشِطَةِ مُتَاحَةٌ الآنَ بِصِفَةٍ دَائِمَةٍ.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successGreen,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (isExpired) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.errorRed, width: 1.5),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 30),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'انْتَهَتِ الفَتْرَةُ التَّجْرِيبِيَّةُ المَجَّانِيَّةُ (7 أَيَّامٍ).\nلِمُوَاصَلَةِ اسْتِخْدَامِ دُرُوسِ المِنْهَاجِ وَالأَنْشِطَةِ الصَّفِّيَّةِ، يُرْجَى إِدْخَالُ كَوْدِ التَّفْعِيلِ.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.errorRed,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accentOrange, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: AppTheme.accentOrange, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'الفَتْرَةُ التَّجْرِيبِيَّةُ سَارِيَةٌ (مُتَبَقٍّ $days أَيَّامٍ). يُمْكِنُكَ تَنْشِيطُ النُّسْخَةِ الدَّائِمَةِ فِي أَيِّ وَقْتٍ.',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // 2. Device Code Section
                const Text(
                  'كَوْدُ تَعْرِيفِ هَذَا الجِهَازِ (Device Code):',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          widget.licenseService.deviceCode,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryDark,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _handleCopy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCopied ? AppTheme.successGreen : AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(_isCopied ? Icons.check_rounded : Icons.copy_rounded, size: 18),
                        label: Text(
                          _isCopied ? 'تَمَّ النَّسْخُ' : 'نَسْخُ الكَوْدِ',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '💡 انْقُرْ عَلَى "نَسْخُ الكَوْدِ" وَأَرْسِلْهُ لِلْمُطَوِّرِ لِلْحُصُولِ عَلَى كَوْدِ التَّفْعِيلِ المُنَاسِبِ لِجِهَازِكَ.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                ),

                if (!isActivated && !_isSuccess) ...[
                  const SizedBox(height: 22),
                  // 3. Activation Code Input
                  const Text(
                    'أَدْخِلْ كَوْدَ التَّفْعِيلِ (Activation Code):',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keyController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ACT-XXXX-XXXX-XXXX',
                      hintStyle: const TextStyle(color: Colors.black26),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppTheme.primaryTeal),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                      ),
                    ),
                    onSubmitted: (_) => _handleActivate(),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.errorRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        actions: [
          if (widget.licenseService.canAccessCurriculum && !_isSuccess)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إِغْلاق', style: TextStyle(fontSize: 16, color: AppTheme.textMuted)),
            ),
          if (!isActivated && !_isSuccess)
            ElevatedButton(
              onPressed: _handleActivate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'تَفْعِيلُ البَرْنَامِجِ الآنَ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'مُمْتَاز، مُوَاصَلَةُ الاسْتِخْدَامِ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
