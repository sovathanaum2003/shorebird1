import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'shorebird_demo_screen.dart';

/// Main Shell Screen providing a 4-button Material 3 NavigationBar:
/// 1. Home
/// 2. Manage
/// 3. Notification
/// 4. Profile
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Widget> pages = [
      const ShorebirdDemoScreen(),
      const ManageTabScreen(),
      const NotificationsTabScreen(),
      const ProfileTabScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        elevation: 3,
        height: 65,
        indicatorColor: theme.colorScheme.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF6366F1)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts_rounded, color: Color(0xFF6366F1)),
            label: 'Manage',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded, color: Color(0xFF6366F1)),
            label: 'Notification',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF6366F1)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Dedicated Manage Tab Screen for Shorebird Updates
class ManageTabScreen extends StatefulWidget {
  const ManageTabScreen({super.key});

  @override
  State<ManageTabScreen> createState() => _ManageTabScreenState();
}

class _ManageTabScreenState extends State<ManageTabScreen> {
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
            _statusMessage = 'New patch available on track "${_currentTrack.name}". Downloading...';
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
          _errorMessage = 'Update check error: $error';
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
    });

    try {
      await _updater.update(track: _currentTrack);
      if (!mounted) return;
      await _loadCurrentPatch();
      setState(() {
        _isRestartRequired = true;
        _statusMessage = 'Patch downloaded! Tap "Restart App" to apply.';
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

  Future<void> _restartApp() async {
    try {
      await Restart.restartApp();
    } catch (error) {
      debugPrint('Error restarting app: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Updates', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Engine Overview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _isUpdaterAvailable
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.15),
                        child: Icon(
                          _isUpdaterAvailable ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                          color: _isUpdaterAvailable ? const Color(0xFF10B981) : Colors.orange,
                        ),
                      ),
                      title: const Text('Engine Status', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_isUpdaterAvailable ? 'Shorebird Engine Active (Release Build)' : 'Shorebird Inactive (Debug Mode)'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEEF2FF),
                        child: Icon(Icons.system_update_rounded, color: Color(0xFF6366F1)),
                      ),
                      title: const Text('Installed Patch Version', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        _currentPatch != null ? 'Patch #${_currentPatch!.number}' : 'No Patch Installed (Base Version)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Track Selector Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Deployment Track', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
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
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Actions
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: (_isUpdaterAvailable && !_isCheckingForUpdates && !_isDownloading)
                            ? _checkForUpdate
                            : null,
                        icon: (_isCheckingForUpdates || _isDownloading)
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.cloud_download_rounded),
                        label: Text(_isDownloading ? 'Downloading...' : 'Check & Download OTA Patch'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: _isRestartRequired
                          ? FilledButton.icon(
                              onPressed: _restartApp,
                              icon: const Icon(Icons.published_with_changes_rounded),
                              label: const Text('Restart App Now (Apply Update)', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                              ),
                            )
                          : OutlinedButton.icon(
                              onPressed: _restartApp,
                              icon: const Icon(Icons.restart_alt_rounded),
                              label: const Text('Restart App Now'),
                            ),
                    ),

                    if (_statusMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_statusMessage!, style: const TextStyle(color: Colors.blue))),
                          ],
                        ),
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Notification Tab Screen
class NotificationsTabScreen extends StatelessWidget {
  const NotificationsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final notifications = [
      {
        'title': 'Patch #3 Live Deployed',
        'subtitle': 'Dynamic package_info_plus and restart actions updated over-the-air.',
        'time': 'Just now',
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFF6366F1),
      },
      {
        'title': 'Release v1.0.2+3 Built',
        'subtitle': 'App Bundle and APK compiled with Shorebird Engine.',
        'time': '10 mins ago',
        'icon': Icons.rocket_launch_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Shorebird Engine Connected',
        'subtitle': 'Application ID 0a6c4441-042f-428d-a801-468e68e86598 bound to Stable track.',
        'time': '1 hour ago',
        'icon': Icons.verified_user_rounded,
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20.0),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = notifications[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (item['color'] as Color).withValues(alpha: 0.15),
                child: Icon(item['icon'] as IconData, color: item['color'] as Color),
              ),
              title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(item['subtitle'] as String),
              ),
              trailing: Text(item['time'] as String, style: theme.textTheme.labelSmall),
            ),
          );
        },
      ),
    );
  }
}

/// Profile Tab Screen
class ProfileTabScreen extends StatefulWidget {
  const ProfileTabScreen({super.key});

  @override
  State<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends State<ProfileTabScreen> {
  String _version = '1.0.2+3';

  @override
  void initState() {
    super.initState();
    _loadVersion();
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
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // User Header Avatar Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        'V',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('vathso077@gmail.com', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Shorebird Developer Account', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Environment Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildProfileTile(
                      icon: Icons.apps_rounded,
                      title: 'App Name',
                      subtitle: 'shorebird',
                    ),
                    const Divider(),
                    _buildProfileTile(
                      icon: Icons.fingerprint_rounded,
                      title: 'App ID (Shorebird)',
                      subtitle: '0a6c4441-042f-428d-a801-468e68e86598',
                    ),
                    const Divider(),
                    _buildProfileTile(
                      icon: Icons.info_outline_rounded,
                      title: 'App Version',
                      subtitle: 'v$_version',
                    ),
                    const Divider(),
                    _buildProfileTile(
                      icon: Icons.flutter_dash_rounded,
                      title: 'Flutter Engine',
                      subtitle: 'Flutter 3.47.9 • Dart 3.13.7',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6366F1)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
    );
  }
}
