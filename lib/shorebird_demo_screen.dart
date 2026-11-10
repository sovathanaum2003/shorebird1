import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Shorebird Demonstration Screen featuring a modern Material 3 design,
/// dynamic version detection via package_info_plus, track configuration, and OTA patch state.
class ShorebirdDemoScreen extends StatefulWidget {
  const ShorebirdDemoScreen({super.key});

  @override
  State<ShorebirdDemoScreen> createState() => _ShorebirdDemoScreenState();
}

class _ShorebirdDemoScreenState extends State<ShorebirdDemoScreen> {
  // Application details
  static const String _appName = 'shorebird';
  String _displayVersion = '1.0.2+3';

  // Dynamic message - Change this string when publishing OTA Patch V2
  static const String _demoMessage = 'Hello from Shorebird OTA Patch V2 (Live Test 🎉)';

  // Counter state
  int _counter = 0;

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
    _initializeShorebird();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _displayVersion = '${info.version}+${info.buildNumber}';
        });
      }
    } catch (error) {
      debugPrint('Error reading package info: $error');
    }
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
            _statusMessage = 'Your application is on the latest version of "${_currentTrack.name}".';
          });
        case UpdateStatus.outdated:
          setState(() {
            _statusMessage = 'New patch update found on track "${_currentTrack.name}". Downloading...';
          });
          await _downloadPatch();
        case UpdateStatus.restartRequired:
          setState(() {
            _isRestartRequired = true;
            _statusMessage = 'Update ready! Restart the app to apply the latest patch snapshot.';
          });
        case UpdateStatus.unavailable:
          setState(() {
            _errorMessage = 'Shorebird updater service is unavailable in this environment.';
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
          _errorMessage = 'Unexpected error during update: $error';
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

  Future<void> _restartApp() async {
    try {
      final result = await Restart.restartApp();
      debugPrint('Restart app result: $result');
    } catch (error) {
      debugPrint('Error restarting app: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not restart app: $error'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bolt_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Shorebird OTA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Restart App',
            onPressed: _restartApp,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Banner with Gradient & App Meta Info
              _buildHeroHeader(theme, isDark),
              const SizedBox(height: 20),

              // Live OTA Demonstration Card
              _buildLiveMessageCard(theme, isDark),
              const SizedBox(height: 20),

              // Engine & Patch Dashboard Grid
              Row(
                children: [
                  Expanded(
                    child: _buildDashboardCard(
                      theme: theme,
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
                      theme: theme,
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

              // Track Selector & Code Push Control Panel
              _buildControlPanelCard(theme, isDark),
              const SizedBox(height: 20),

              // Interactive Counter Component
              _buildCounterCard(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF312E81), Color(0xFF4C1D95)]
              : const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF4F46E5)).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.auto_awesome,
              size: 140,
              color: Colors.white.withValues(alpha: 0.08),
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
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
                              fontWeight: FontWeight.w600,
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
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'v$_displayVersion',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Shorebird Code Push',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Instantly deploy Dart code updates over-the-air directly to end users without app store delays.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13.5,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cell_tower_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LIVE OTA PATCH MESSAGE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Code Update Verification Payload',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                _demoMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanelCard(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Update Track & Management',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Track Selector
            Text(
              'Select Deployment Track:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<UpdateTrack>(
                segments: const [
                  ButtonSegment(
                    value: UpdateTrack.stable,
                    label: Text('Stable'),
                    icon: Icon(Icons.verified_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: UpdateTrack.staging,
                    label: Text('Staging'),
                    icon: Icon(Icons.construction_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: UpdateTrack.beta,
                    label: Text('Beta'),
                    icon: Icon(Icons.science_rounded, size: 16),
                  ),
                ],
                selected: {_currentTrack},
                onSelectionChanged: (selection) {
                  setState(() {
                    _currentTrack = selection.single;
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: theme.colorScheme.primaryContainer,
                  selectedForegroundColor: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Button: Check & Download OTA Patch
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: (_isUpdaterAvailable && !_isCheckingForUpdates && !_isDownloading)
                    ? _checkForUpdate
                    : null,
                icon: (_isCheckingForUpdates || _isDownloading)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_download_rounded),
                label: Text(
                  _isDownloading
                      ? 'Downloading Patch...'
                      : _isCheckingForUpdates
                          ? 'Checking Shorebird Server...'
                          : 'Check & Download OTA Patch',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action Button: Restart App (Always visible & interactive)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: _isRestartRequired
                  ? FilledButton.icon(
                      onPressed: _restartApp,
                      icon: const Icon(Icons.published_with_changes_rounded),
                      label: const Text(
                        'Restart App Now (Apply Update)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: _restartApp,
                      icon: Icon(
                        Icons.restart_alt_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        'Restart App',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
            ),

            // Status Notification Box
            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isRestartRequired
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
                      : const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isRestartRequired
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                        : const Color(0xFF3B82F6).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isRestartRequired
                              ? Icons.published_with_changes_rounded
                              : Icons.info_outline_rounded,
                          color: _isRestartRequired
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF3B82F6),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: _isRestartRequired ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isRestartRequired) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _restartApp,
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('Restart App Now to Apply Patch'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Error Notification Box
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCounterCard(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Interactive Counter',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Reset Counter',
                  onPressed: _resetCounter,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_counter',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _incrementCounter,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Increment Counter',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
