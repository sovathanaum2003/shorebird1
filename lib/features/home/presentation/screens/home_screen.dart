import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import '../../../../core/widgets/liquid_glass_button.dart';
import '../../../../core/widgets/liquid_glass_card.dart';

/// Home Feature Screen featuring Shorebird OTA status, live message, and interactive counter.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Application details
  static const String _appName = 'shorebird';

  /// Manually editable version string shown on the Home UI.
  static const String _displayVersion = '1.0.5+8';

  // Dynamic message - Change this string when publishing OTA Patch V2
  static const String _demoMessage = 'Hello from Shorebird OTA Patch';

  // Counter state
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
  }

  // Shorebird Code Push Updater instance
  final ShorebirdUpdater _updater = ShorebirdUpdater();
  bool _isUpdaterAvailable = false;
  Patch? _currentPatch;

  @override
  void initState() {
    super.initState();
    _initializeShorebird();
  }

  void _initializeShorebird() {
    setState(() {
      _isUpdaterAvailable = _updater.isAvailable;
    });

    if (_isUpdaterAvailable) {
      _loadCurrentPatch();
    }
  }

  Future<void> _loadCurrentPatch() async {
    try {
      final patch = await _updater.readCurrentPatch();
      if (mounted) {
        setState(() {
          _currentPatch = patch;
        });
      }
    } catch (error) {
      debugPrint('Error reading Shorebird current patch: $error');
    }
  }

  bool _isRestarting = false;

  Future<void> _restartApp() async {
    if (_isRestarting) return;
    setState(() {
      _isRestarting = true;
    });

    try {
      final result = await Restart.restartApp(
        mode: RestartMode.process,
        forceKill: true,
      );
      debugPrint('Restart app result: success=${result.success}, mode=${result.mode}, code=${result.code}, message=${result.message}');

      if (!result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restart warning: ${result.message ?? "Attempting fallback exit..."}'),
              backgroundColor: Colors.orange.shade800,
            ),
          );
        }
        await SystemNavigator.pop();
      }
    } catch (error) {
      debugPrint('Error restarting app: $error');
      try {
        await SystemNavigator.pop();
      } catch (_) {}
    } finally {
      if (mounted) {
        setState(() {
          _isRestarting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: AppBar(
              backgroundColor: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.55),
              elevation: 0,
              centerTitle: true,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Shorebird OTA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                    ),
                    child: Icon(
                      Icons.restart_alt_rounded,
                      color: isDark ? Colors.white : const Color(0xFF4F46E5),
                      size: 18,
                    ),
                  ),
                  tooltip: 'Restart App',
                  onPressed: _restartApp,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Liquid Gradient Layer with Glowing Orbs
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF0F172A),
                          Color(0xFF1E1B4B),
                          Color(0xFF0F172A),
                        ]
                      : const [
                          Color(0xFFEEF2FF),
                          Color(0xFFF3E8FF),
                          Color(0xFFE0E7FF),
                        ],
                ),
              ),
            ),
          ),

          // Glowing Liquid Ambient Orb Top Right
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.45 : 0.35),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Glowing Liquid Ambient Orb Center Left
          Positioned(
            top: 280,
            left: -70,
            child: Container(
              width: 290,
              height: 290,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEC4899).withValues(alpha: isDark ? 0.40 : 0.28),
                    const Color(0xFFEC4899).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Glowing Liquid Ambient Orb Bottom Right
          Positioned(
            bottom: 60,
            right: -40,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.35 : 0.25),
                    const Color(0xFF06B6D4).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main Scrollable Content Area
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // Hero Banner in Liquid Gradient Glass
                  _buildHeroHeader(theme, isDark),
                  const SizedBox(height: 20),

                  // Live OTA Message Card (Liquid Glass)
                  _buildLiveMessageCard(theme, isDark),
                  const SizedBox(height: 20),

                  // Engine & Patch Dashboard Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildDashboardCard(
                          isDark: isDark,
                          icon: _isUpdaterAvailable
                              ? Icons.check_circle_rounded
                              : Icons.warning_rounded,
                          iconColor: _isUpdaterAvailable
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          label: 'Shorebird Engine',
                          value: _isUpdaterAvailable ? 'Active' : 'Unavailable',
                          subtitle: _isUpdaterAvailable ? 'Release Build' : 'Debug Mode',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDashboardCard(
                          isDark: isDark,
                          icon: Icons.system_update_rounded,
                          iconColor: const Color(0xFF6366F1),
                          label: 'Installed Patch',
                          value: _currentPatch != null
                              ? 'Patch #${_currentPatch!.number}'
                              : 'Base Version',
                          subtitle: _currentPatch != null ? 'OTA Active' : 'No Patch Applied',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Interactive Counter Component
                  _buildCounterCard(theme, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF312E81), Color(0xFF581C87), Color(0xFF831843)]
              : const [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFDB2777)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF4F46E5)).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -25,
            child: Icon(
              Icons.auto_awesome,
              size: 160,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _appName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        'v$_displayVersion',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Shorebird Code Push',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Instantly deploy Dart code updates over-the-air directly to end users without app store delays.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.90),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMessageCard(ThemeData theme, bool isDark) {
    return LiquidGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.cell_tower_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIVE OTA PATCH MESSAGE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Code Update Verification Payload',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF6366F1).withValues(alpha: 0.25),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      ]
                    : [
                        const Color(0xFFEEF2FF),
                        const Color(0xFFF3E8FF),
                      ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.4 : 0.25),
                width: 1.2,
              ),
            ),
            child: Text(
              _demoMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF312E81),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return LiquidGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              color: iconColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterCard(ThemeData theme, bool isDark) {
    return LiquidGlassCard(
      isDark: isDark,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.touch_app_rounded,
                      size: 18,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Interactive Counter',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
                tooltip: 'Reset Counter',
                onPressed: _resetCounter,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.black.withValues(alpha: 0.2),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.6),
                        Colors.white.withValues(alpha: 0.3),
                      ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.3 : 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '$_counter',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          LiquidGlassButton(
            onPressed: _incrementCounter,
            isHighlight: false,
            icon: Icons.add_rounded,
            label: 'Increment Counter',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}
