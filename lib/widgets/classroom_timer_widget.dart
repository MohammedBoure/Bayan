import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Classroom Challenge Timer Widget for interactive whiteboard activities.
class ClassroomTimerWidget extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback? onTimerFinished;

  const ClassroomTimerWidget({
    super.key,
    required this.initialSeconds,
    this.onTimerFinished,
  });

  @override
  State<ClassroomTimerWidget> createState() => _ClassroomTimerWidgetState();
}

class _ClassroomTimerWidgetState extends State<ClassroomTimerWidget> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_remainingSeconds <= 0) return;

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        widget.onTimerFinished?.call();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = widget.initialSeconds;
      _isRunning = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWarning = _remainingSeconds <= 10 && _remainingSeconds > 0;
    final isFinished = _remainingSeconds == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isFinished
            ? AppTheme.errorRed.withValues(alpha: 0.15)
            : (isWarning ? AppTheme.accentOrange.withValues(alpha: 0.15) : AppTheme.primaryTeal.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFinished ? AppTheme.errorRed : (isWarning ? AppTheme.accentOrange : AppTheme.primaryTeal),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFinished ? Icons.alarm_off_rounded : Icons.timer_rounded,
            color: isFinished ? AppTheme.errorRed : (isWarning ? AppTheme.accentOrange : AppTheme.primaryTeal),
            size: 26,
          ),
          const SizedBox(width: 8),
          Text(
            '$_remainingSeconds ث',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isFinished ? AppTheme.errorRed : (isWarning ? AppTheme.accentOrange : AppTheme.primaryDark),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: Icon(_isRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
            iconSize: 28,
            color: AppTheme.primaryTeal,
            tooltip: _isRunning ? 'إيقاف مؤقت' : 'استئناف',
            onPressed: () {
              if (_isRunning) {
                _pauseTimer();
              } else {
                _startTimer();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            iconSize: 24,
            color: AppTheme.textMuted,
            tooltip: 'إعادة ضبط المؤقت',
            onPressed: _resetTimer,
          ),
        ],
      ),
    );
  }
}
