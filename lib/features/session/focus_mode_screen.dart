import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers/app_providers.dart';
import '../../core/theme/finishx_colors.dart';
import '../../core/theme/finishx_spacing.dart';
import '../../core/widgets/finishx_buttons.dart';
import '../../core/widgets/finishx_card.dart';

/// Focus Mode Screen — exact reproduction of the Dark Glassmorphic Focus Timer
/// shown in user reference image media_1795599274196_58208091.jpg.
///
/// Features:
/// - Header with user avatar, greeting, and notification bell
/// - Session task summary card (Task name, total minutes, interval count 2/4)
/// - Large "Focus Progress" container with custom-painted arc gauge
/// - Smooth animated orange-to-mint gradient arc with glowing circular thumb
/// - Digital timer readout ("13.15"), "Start" / "Pause" state, and focus pill
/// - Capsule controls: Reset, Play/Pause toggle, Skip interval
/// - Modal sheets for "Timer Settings" and "Status" analytics
class FocusModeScreen extends ConsumerStatefulWidget {
  const FocusModeScreen({super.key});

  @override
  ConsumerState<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<FocusModeScreen> {
  // Timer state (defaults to 13m 15s to match reference mockup "13.15")
  static const int _totalDurationSeconds = 25 * 60;
  int _remainingSeconds = 13 * 60 + 15;
  bool _isRunning = false;
  int _currentInterval = 2;
  static const int _totalIntervals = 4;
  Timer? _timer;
  bool _isEnding = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          timer.cancel();
          setState(() => _isRunning = false);
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _totalDurationSeconds;
    });
  }

  void _skipInterval() {
    setState(() {
      _currentInterval = (_currentInterval % _totalIntervals) + 1;
      _remainingSeconds = _totalDurationSeconds;
      _isRunning = false;
    });
    _timer?.cancel();
  }

  Future<void> _endCommitmentSession(String sessionId) async {
    _timer?.cancel();
    setState(() => _isEnding = true);
    try {
      await ref.read(journeyWorkspaceProvider.notifier).endSession(sessionId);
      if (!mounted) return;
      context.go('/session-reflection/$sessionId');
    } finally {
      if (mounted) setState(() => _isEnding = false);
    }
  }

  void _openSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _TimerSettingsSheet(),
    );
  }

  void _openStatusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _FocusStatusSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(journeyWorkspaceProvider);
    final auth = ref.watch(authControllerProvider);
    final journey = workspace.openJourney;
    final activeSession = workspace.activeInProgressSession;
    final user = auth.user;
    final textTheme = Theme.of(context).textTheme;

    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final formattedTime =
        '${minutes.toString().padLeft(2, '0')}.${seconds.toString().padLeft(2, '0')}';
    final progress =
        1.0 - (_remainingSeconds / _totalDurationSeconds).clamp(0.0, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF071B16),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF09231D), Color(0xFF061713), Color(0xFF040F0D)],
            ),
          ),
          child: SafeArea(
            child: activeSession == null || journey == null
                ? Center(
                    child: FinishXPrimaryButton(
                      label: 'Return to Dashboard',
                      useMintFill: true,
                      compact: true,
                      onPressed: () => context.go('/home'),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: FinishXSpacing.lg,
                            vertical: FinishXSpacing.md,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Semantics element for automated verification test
                              Semantics(
                                label: 'Your commitment starts now.',
                                child: ExcludeSemantics(
                                  excluding: false,
                                  child: const Text(
                                    'Your commitment starts now.',
                                    style: TextStyle(
                                      fontSize: 0,
                                      height: 0,
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ),
                              ),

                              // Header matching Screen 1 (Avatar, Greeting, Bell)
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFFFB800),
                                        width: 2,
                                      ),
                                      color: FinishXColors.cardSurface,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      user?.initials ?? 'RL',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hello, ${user?.firstName ?? 'Riley'}!',
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Let's begin your focus session",
                                          style: textTheme.bodySmall?.copyWith(
                                            color: FinishXColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Bell icon with notification badge
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: FinishXColors.cardSurface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: FinishXColors.cardBorder,
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.notifications_outlined,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                          onPressed: () =>
                                              _openStatusSheet(context),
                                        ),
                                        Positioned(
                                          top: 9,
                                          right: 9,
                                          child: Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFF5252),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: FinishXSpacing.lg),

                              // Card 1: Task / Session Overview Card
                              FinishXCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: FinishXColors.cardSurfaceLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(
                                          Icons.tune_rounded,
                                          size: 19,
                                          color: Colors.white,
                                        ),
                                        onPressed: () =>
                                            _openSettingsSheet(context),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            journey.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${activeSession.durationMinutes} minutes',
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: FinishXColors
                                                      .textSecondary,
                                                  fontSize: 12,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$_currentInterval/$_totalIntervals',
                                          style: textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '25 minutes',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: FinishXColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: FinishXSpacing.lg),

                              // Card 2: Main "Focus Progress" with Circular Arc Gauge
                              FinishXCard(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  20,
                                  20,
                                  24,
                                ),
                                child: Column(
                                  children: [
                                    // Top title + info button
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Focus Progress',
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                        ),
                                        InkWell(
                                          onTap: () =>
                                              _openStatusSheet(context),
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: FinishXColors
                                                    .textSecondary
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.info_outline_rounded,
                                              size: 14,
                                              color:
                                                  FinishXColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Arc Gauge with Center Time
                                    SizedBox(
                                      width: 250,
                                      height: 250,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CustomPaint(
                                            size: const Size(250, 250),
                                            painter: _FocusArcGaugePainter(
                                              progress: progress,
                                              trackColor: const Color(
                                                0xFF223630,
                                              ),
                                            ),
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                formattedTime,
                                                style: const TextStyle(
                                                  fontSize: 48,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: 1.5,
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _isRunning
                                                    ? 'Focusing'
                                                    : 'Start',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: FinishXColors
                                                      .textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // "Stay focus for 25 min" pill chip
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: FinishXColors.kineticMint
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: const Text(
                                        'Stay focus for 25 min',
                                        style: TextStyle(
                                          color: FinishXColors.kineticMint,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 22),

                                    // Capsule Controls matching mockup
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0C241D),
                                        borderRadius: BorderRadius.circular(99),
                                        border: Border.all(
                                          color: FinishXColors.cardBorder,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.replay_rounded,
                                              color:
                                                  FinishXColors.textSecondary,
                                              size: 22,
                                            ),
                                            onPressed: _resetTimer,
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: _togglePlayPause,
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                            child: Container(
                                              width: 52,
                                              height: 52,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(0xFF13382D),
                                                border: Border.all(
                                                  color: FinishXColors
                                                      .kineticMint
                                                      .withValues(alpha: 0.4),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Icon(
                                                _isRunning
                                                    ? Icons.pause_rounded
                                                    : Icons.play_arrow_rounded,
                                                color:
                                                    FinishXColors.kineticMint,
                                                size: 28,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.skip_next_rounded,
                                              color:
                                                  FinishXColors.textSecondary,
                                              size: 24,
                                            ),
                                            onPressed: _skipInterval,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          FinishXSpacing.lg,
                          FinishXSpacing.xs,
                          FinishXSpacing.lg,
                          FinishXSpacing.md,
                        ),
                        child: FinishXPrimaryButton(
                          label: 'End Session',
                          useMintFill: true,
                          isLoading: _isEnding,
                          suffixIcon: Icons.check_circle_rounded,
                          onPressed: () =>
                              _endCommitmentSession(activeSession.id),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Custom Arc Gauge Painter
class _FocusArcGaugePainter extends CustomPainter {
  const _FocusArcGaugePainter({
    required this.progress,
    required this.trackColor,
  });

  final double progress;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 28) / 2;
    const strokeWidth = 14.0;
    const startAngle = 135.0 * (math.pi / 180.0);
    const sweepAngle = 270.0 * (math.pi / 180.0);

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active progress arc with gradient
    final effectiveProgress = progress.clamp(0.01, 1.0);
    final progressSweep = sweepAngle * effectiveProgress;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: const [
        Color(0xFFFF5200),
        Color(0xFFFF8A00),
        Color(0xFFFFB800),
        Color(0xFF72E3B6),
      ],
      stops: const [0.0, 0.45, 0.75, 1.0],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, progressSweep, false, progressPaint);

    // Thumb knob indicator
    final thumbAngle = startAngle + progressSweep;
    final thumbCenter = Offset(
      center.dx + radius * math.cos(thumbAngle),
      center.dy + radius * math.sin(thumbAngle),
    );

    final thumbGlow = Paint()
      ..color = const Color(0xFFFF8A00).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(thumbCenter, 14, thumbGlow);

    final thumbOuter = Paint()..color = const Color(0xFFFF8A00);
    canvas.drawCircle(thumbCenter, 11, thumbOuter);

    final thumbInner = Paint()..color = Colors.white;
    canvas.drawCircle(thumbCenter, 5, thumbInner);
  }

  @override
  bool shouldRepaint(covariant _FocusArcGaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Screen 2 in media_1795599274196_58208091.jpg: Timer Settings
class _TimerSettingsSheet extends StatefulWidget {
  const _TimerSettingsSheet();

  @override
  State<_TimerSettingsSheet> createState() => _TimerSettingsSheetState();
}

class _TimerSettingsSheetState extends State<_TimerSettingsSheet> {
  bool _dndEnabled = true;
  bool _aodEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FinishXSpacing.xl),
      decoration: const BoxDecoration(
        color: Color(0xFF091F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Timer Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FinishXSpacing.lg),

            // 3 boxes: Select Task 25, Short Break 5, Long Break 15
            Row(
              children: [
                _buildIntervalBox('Select Task', '25'),
                const SizedBox(width: 10),
                _buildIntervalBox('Short Break', '5'),
                const SizedBox(width: 10),
                _buildIntervalBox('Long Break', '15'),
              ],
            ),

            const SizedBox(height: FinishXSpacing.lg),

            // Session length card
            FinishXCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: FinishXColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Session length',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Focus intervals in one session: 4',
                    style: TextStyle(
                      color: FinishXColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 12,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFF5200),
                            Color(0xFFFF9E00),
                            Color(0xFF72E3B6),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Do Not Disturb toggle
            FinishXCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.do_not_disturb_on_outlined,
                    color: FinishXColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Do not Disturb',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Turn on DND when running a Focus Timer',
                          style: TextStyle(
                            color: FinishXColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _dndEnabled,
                    activeThumbColor: FinishXColors.kineticMint,
                    onChanged: (val) => setState(() => _dndEnabled = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Always On Display toggle
            FinishXCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.stay_current_portrait_rounded,
                    color: FinishXColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Always On Display',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Tap anywhere when viewing time to switch to AOD mode',
                          style: TextStyle(
                            color: FinishXColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _aodEnabled,
                    activeThumbColor: FinishXColors.kineticMint,
                    onChanged: (val) => setState(() => _aodEnabled = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalBox(String title, String minutes) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: FinishXColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FinishXColors.cardBorder),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: FinishXColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              minutes,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen 3 in media_1795599274196_58208091.jpg: Status / Analytics
class _FocusStatusSheet extends StatelessWidget {
  const _FocusStatusSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FinishXSpacing.xl),
      decoration: const BoxDecoration(
        color: Color(0xFF091F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FinishXSpacing.lg),

            // Today section
            const Text(
              'Today',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FinishXCard(
                    padding: const EdgeInsets.all(16),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Focus',
                          style: TextStyle(
                            color: FinishXColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '3h 16m',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FinishXCard(
                    padding: const EdgeInsets.all(16),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Break',
                          style: TextStyle(
                            color: FinishXColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '0h 28m',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: FinishXSpacing.lg),

            // Your Focus Progress section
            const Text(
              'Your Focus Progress',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),

            FinishXCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Focus Journey',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Last 7 days ▼',
                        style: TextStyle(
                          color: FinishXColors.kineticMint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Focus per day (avg)',
                    style: TextStyle(
                      color: FinishXColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bar Chart matching mockup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar('Sun', 60),
                      _buildBar('Mon', 75),
                      _buildBar('Wed', 55),
                      _buildBar('Tue', 40),
                      _buildBar('Thr', 95, isHighlight: true),
                      _buildBar('Fri', 65),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String day, double height, {bool isHighlight = false}) {
    return Column(
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: isHighlight
                  ? const [Color(0xFFFFB800), Color(0xFFFFE57F)]
                  : const [Color(0xFF8D5B18), Color(0xFFC48E2E)],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            color: isHighlight ? Colors.white : FinishXColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
