import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import '../../../../core/widgets/liquid_glass_button.dart';
import '../../../../core/widgets/liquid_glass_card.dart';
import '../../../../core/widgets/liquid_status_banner.dart';

/// Profile Feature Screen displaying developer account details, environment info,
/// and hosting the Auto-Update Engine control panel.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _version = '1.0.5+8';

  // Shorebird Code Push Updater instance
  final ShorebirdUpdater _updater = ShorebirdUpdater();
  bool _isUpdaterAvailable = false;
  UpdateTrack _currentTrack = UpdateTrack.stable;
  bool _isCheckingForUpdates = false;
  bool _isDownloading = false;
  bool _isRestartRequired = false;
  Patch? _currentPatch;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _initializeShorebird();
  }

  void _initializeShorebird() {
    setState(() {
      _isUpdaterAvailable = _updater.isAvailable;
      _currentTrack = UpdateTrack.stable; // Explicitly ensure stable track on launch
    });

    if (_isUpdaterAvailable) {
      _loadCurrentPatch();
      // Automatically query and check for stable track background updates on startup
      _checkForUpdate();
    }
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = '${info.version}+${info.buildNumber}';
        });
      }
    } catch (e) {
      debugPrint('Error reading package info: $e');
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
      debugPrint('Error loading patch: $error');
    }
  }

  Future<void> _checkForUpdate() async {
    if (!_isUpdaterAvailable || _isCheckingForUpdates || _isDownloading) return;

    setState(() {
      _isCheckingForUpdates = true;
      _statusMessage = null;
      _errorMessage = null;
    });

    try {
      final status = await _updater.checkForUpdate(track: _currentTrack);
      if (!mounted) return;

      switch (status) {
        case UpdateStatus.upToDate:
          setState(() {
            _statusMessage = 'App is up to date on track "${_currentTrack.name}".';
          });
        case UpdateStatus.outdated:
          setState(() {
            _statusMessage = 'New patch update found on track "${_currentTrack.name}". Downloading...';
          });
          await _downloadPatch();
        case UpdateStatus.restartRequired:
          setState(() {
            _isRestartRequired = true;
            _statusMessage = 'Update ready! Restart app to activate changes.';
          });
        case UpdateStatus.unavailable:
          setState(() {
            _errorMessage = 'Shorebird service is unavailable for this release.';
          });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed checking for updates: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingForUpdates = false;
        });
      }
    }
  }

  Future<void> _downloadPatch() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    try {
      await _updater.update(track: _currentTrack);
      if (!mounted) return;

      try {
        await _loadCurrentPatch();
      } catch (error) {
        debugPrint('Could not reload patch metadata: $error');
      }

      setState(() {
        _isRestartRequired = true;
        _statusMessage = 'Patch downloaded successfully! Tap "Restart App" to activate changes.';
      });
    } on UpdateException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Download failed: ${error.message}';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unexpected download error: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
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
                        colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
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
                      Icons.person_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Developer Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Liquid Gradient Layer
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

          // Glowing Ambient Liquid Orbs
          Positioned(
            top: -50,
            left: -30,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: isDark ? 0.45 : 0.35),
                    const Color(0xFF6366F1).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 260,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFA855F7).withValues(alpha: isDark ? 0.40 : 0.30),
                    const Color(0xFFA855F7).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main Profile Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // User Header Glass Card
                  LiquidGlassCard(
                    isDark: isDark,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                            child: const Text(
                              'V',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'vathso077@gmail.com',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Text(
                            'Shorebird Developer Account',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Auto-Update Engine Control Card
                  _buildAutoUpdateEngineCard(isDark),

                  const SizedBox(height: 20),

                  // Environment & App Details Glass Grid
                  LiquidGlassCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        _buildProfileTile(
                          isDark: isDark,
                          icon: Icons.apps_rounded,
                          iconColor: const Color(0xFF6366F1),
                          title: 'App Name',
                          subtitle: 'shorebird',
                        ),
                        _buildDivider(isDark),
                        _buildProfileTile(
                          isDark: isDark,
                          icon: Icons.fingerprint_rounded,
                          iconColor: const Color(0xFFA855F7),
                          title: 'App ID (Shorebird)',
                          subtitle: '0a6c4441-042f-428d-a801-468e68e86598',
                        ),
                        _buildDivider(isDark),
                        _buildProfileTile(
                          isDark: isDark,
                          icon: Icons.info_outline_rounded,
                          iconColor: const Color(0xFF10B981),
                          title: 'App Version',
                          subtitle: 'v$_version',
                        ),
                        _buildDivider(isDark),
                        _buildProfileTile(
                          isDark: isDark,
                          icon: Icons.system_update_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          title: 'Installed Patch Version',
                          subtitle: _currentPatch != null
                              ? 'Patch #${_currentPatch!.number}'
                              : 'No Patch Installed (Base Version)',
                        ),
                        _buildDivider(isDark),
                        _buildProfileTile(
                          isDark: isDark,
                          icon: Icons.flutter_dash_rounded,
                          iconColor: const Color(0xFF06B6D4),
                          title: 'Flutter Engine',
                          subtitle: 'Flutter 3.47.9 • Dart 3.13.7',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoUpdateEngineCard(bool isDark) {
    return LiquidGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  Icons.sync_rounded,
                  size: 20,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Update Engine',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isUpdaterAvailable ? const Color(0xFF10B981) : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isUpdaterAvailable
                              ? 'Background Sync Active (Stable Track)'
                              : 'Engine Inactive (Debug Environment)',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _isUpdaterAvailable
                                ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Track Selector Label
          Text(
            'Deployment Track:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),

          // Liquid Segmented Track Selector
          _buildTrackSelector(isDark),
          const SizedBox(height: 20),

          // Real-time Auto-Update Sync Bar
          if (_isCheckingForUpdates || _isDownloading)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.2),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isDownloading
                          ? 'Downloading patch automatically in background...'
                          : 'Checking Shorebird server for updates...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF312E81),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Restart Action Button
            LiquidGlassButton(
              onPressed: _restartApp,
              isHighlight: _isRestartRequired,
              icon: _isRestartRequired
                  ? Icons.published_with_changes_rounded
                  : Icons.restart_alt_rounded,
              label: _isRestartRequired
                  ? 'Restart App Now (Apply Update)'
                  : 'Restart App Now',
              isDark: isDark,
            ),
          ],

          // Status Notification Banner
          if (_statusMessage != null && !_isCheckingForUpdates && !_isDownloading) ...[
            const SizedBox(height: 14),
            LiquidStatusBanner(
              icon: _isRestartRequired
                  ? Icons.published_with_changes_rounded
                  : Icons.check_circle_outline_rounded,
              message: _statusMessage!,
              color: _isRestartRequired ? const Color(0xFF8B5CF6) : const Color(0xFF10B981),
              isDark: isDark,
            ),
          ],

          // Error Notification Banner
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            LiquidStatusBanner(
              icon: Icons.error_outline_rounded,
              message: _errorMessage!,
              color: const Color(0xFFEF4444),
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.6),
          width: 1.2,
        ),
      ),
      child: Row(
        children: const [
          UpdateTrack.stable,
          UpdateTrack.staging,
          UpdateTrack.beta,
        ].map((track) {
          final isSelected = _currentTrack == track;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_currentTrack != track) {
                  setState(() {
                    _currentTrack = track;
                  });
                  _checkForUpdate();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      track == UpdateTrack.stable
                          ? Icons.verified_rounded
                          : track == UpdateTrack.staging
                              ? Icons.construction_rounded
                              : Icons.science_rounded,
                      size: 15,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      track.name[0].toUpperCase() + track.name.substring(1),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 12.5,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
