import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/app_usage_service.dart';
import '../../widgets/app_icon_widget.dart';

class DashboardTab extends StatefulWidget {
  final bool isBlockerActive;
  final bool isUsageTrackerEnabled;
  final int blockedAppsCount;
  final int blockedDomainsCount;
  final int customWhitelistCount;
  final bool adultBlockActive;
  final bool socialBlockActive;
  final ValueChanged<bool> onToggleBlocker;
  final ValueChanged<int> onNavigateTab;
  final Function(String presetName, Duration? duration) onActivatePreset;

  const DashboardTab({
    super.key,
    required this.isBlockerActive,
    required this.isUsageTrackerEnabled,
    required this.blockedAppsCount,
    required this.blockedDomainsCount,
    required this.customWhitelistCount,
    required this.adultBlockActive,
    required this.socialBlockActive,
    required this.onToggleBlocker,
    required this.onNavigateTab,
    required this.onActivatePreset,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  String _activePresetName = '';
  bool _isSessionActive = false;

  @override
  void initState() {
    super.initState();
    AppUsageService.usageUpdateNotifier.addListener(_onUsageUpdated);
  }

  @override
  void dispose() {
    _timer?.cancel();
    AppUsageService.usageUpdateNotifier.removeListener(_onUsageUpdated);
    super.dispose();
  }

  void _onUsageUpdated() {
    if (mounted) setState(() {});
  }

  void _startFocusTimer(String presetName, Duration duration) {
    _timer?.cancel();
    setState(() {
      _activePresetName = presetName;
      _remainingTime = duration;
      _isSessionActive = true;
    });

    if (!widget.isBlockerActive) {
      widget.onToggleBlocker(true);
    }

    widget.onActivatePreset(presetName, duration);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds <= 1) {
        timer.cancel();
        setState(() {
          _isSessionActive = false;
          _remainingTime = Duration.zero;
        });
      } else {
        setState(() {
          _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        });
      }
    });
  }

  void _stopFocusSession() {
    _timer?.cancel();
    setState(() {
      _isSessionActive = false;
      _remainingTime = Duration.zero;
    });
  }

  void _extendSession(int minutes) {
    if (_isSessionActive) {
      setState(() {
        _remainingTime += Duration(minutes: minutes);
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = duration.inHours;
    return hours > 0 ? '${twoDigits(hours)}:$minutes:$seconds' : '$minutes:$seconds';
  }

  String _formatSeconds(int seconds) {
    if (seconds <= 0) return '0m';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topApp = AppUsageService.getTopApp();
    final topWeb = AppUsageService.getTopWebsite();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guardian Main Status Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: widget.isBlockerActive
                        ? [theme.colorScheme.primary.withValues(alpha: 0.12), Colors.transparent]
                        : [Colors.amber.withValues(alpha: 0.12), Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isBlockerActive
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.amber.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        widget.isBlockerActive ? Icons.verified_user : Icons.gpp_maybe,
                        size: 48,
                        color: widget.isBlockerActive ? Colors.green.shade700 : Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isBlockerActive
                                ? 'Guardian Protection Active'
                                : 'Protection Temporarily Paused',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isBlockerActive
                                ? 'Real-time interceptor guarding ${widget.blockedAppsCount} apps and ${widget.blockedDomainsCount} web domains.'
                                : 'Enable the protection master switch to resume process blocking and web filtering.',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.hub_outlined, size: 14, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Extension Sync API Active (Port 48192)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Transform.scale(
                      scale: 1.2,
                      child: Switch(
                        value: widget.isBlockerActive,
                        activeThumbColor: theme.colorScheme.primary,
                        onChanged: widget.onToggleBlocker,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Active Focus Session Countdown Card (If active)
            if (_isSessionActive) ...[
              Card(
                elevation: 4,
                color: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, size: 48, color: Colors.white),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Focus Sprint: $_activePresetName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDuration(_remainingTime),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _extendSession(10),
                        icon: const Icon(Icons.add_alarm, size: 16),
                        label: const Text('+10 Min'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _stopFocusSession,
                        icon: const Icon(Icons.stop, size: 16),
                        label: const Text('End Sprint'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Quick Stats Overview Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Banned Apps',
                    value: '${widget.blockedAppsCount}',
                    subtitle: 'Active app execution bans',
                    icon: Icons.app_blocking,
                    color: Colors.red.shade700,
                    onTap: () => widget.onNavigateTab(1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Allowed Whitelist',
                    value: '${widget.customWhitelistCount}',
                    subtitle: 'Trusted exception rules',
                    icon: Icons.verified_user_outlined,
                    color: Colors.green.shade700,
                    onTap: () => widget.onNavigateTab(1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Web Filter',
                    value: '${widget.blockedDomainsCount}',
                    subtitle: widget.adultBlockActive ? 'Adult Filter ON' : 'Web Protection Active',
                    icon: Icons.language,
                    color: theme.colorScheme.primary,
                    onTap: () => widget.onNavigateTab(2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Usage Analytics Summary Card (Greyed out if widget.isUsageTrackerEnabled is false)
            Opacity(
              opacity: widget.isUsageTrackerEnabled ? 1.0 : 0.45,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bar_chart,
                                  color: widget.isUsageTrackerEnabled ? Colors.purple : Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    'Usage Analytics Today',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: widget.isUsageTrackerEnabled ? theme.colorScheme.primary : Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (!widget.isUsageTrackerEnabled)
                                  const Chip(
                                    label: Text('TRACKER PAUSED', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                    backgroundColor: Colors.grey,
                                    side: BorderSide.none,
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: widget.isUsageTrackerEnabled
                                ? () => widget.onNavigateTab(3)
                                : null,
                            icon: const Icon(Icons.analytics, size: 16),
                            label: const Text('View Full Analytics'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.isUsageTrackerEnabled)
                        Row(
                          children: [
                            // Top App Summary
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    if (topApp != null)
                                      AppIconWidget(executable: topApp.key, displayName: topApp.key)
                                    else
                                      const Icon(Icons.apps, size: 32, color: Colors.purple),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Top Used App', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 2),
                                          Text(topApp?.key ?? 'None yet', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text(topApp != null ? _formatSeconds(topApp.value) : '0m', style: const TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Top Website Summary
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.language, size: 32, color: Colors.blue),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Top Visited Site', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 2),
                                          Text(topWeb?.key ?? 'None yet', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text(topWeb != null ? _formatSeconds(topWeb.value) : '0m', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'Usage tracking is currently turned off via the global Usage Tracker toggle. Turn it ON to view app and website analytics.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Quick Focus Action Cards
            Text(
              'Quick Focus Actions & Presets',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Activate instant focus modes to eliminate distractions during work, study, or prayer times.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildActionCard(
                  context,
                  title: '25-Min Pomodoro',
                  description: 'High-intensity 25-minute focus sprint with app lockdown.',
                  icon: Icons.timer,
                  color: Colors.orange.shade700,
                  buttonText: 'Start 25m Sprint',
                  onTap: () => _startFocusTimer('25-Min Pomodoro Sprint', const Duration(minutes: 25)),
                ),
                _buildActionCard(
                  context,
                  title: 'Deep Focus (1 Hour)',
                  description: 'Block all social networks, adult domains, and distraction apps.',
                  icon: Icons.psychology,
                  color: theme.colorScheme.primary,
                  buttonText: 'Start 1h Focus',
                  onTap: () => _startFocusTimer('Deep Focus Sprint', const Duration(hours: 1)),
                ),
                _buildActionCard(
                  context,
                  title: 'Deen Mode',
                  description: 'Enforce full web filter packs and whitelist-only app execution.',
                  icon: Icons.brightness_high,
                  color: Colors.teal.shade700,
                  buttonText: 'Activate Deen Mode',
                  onTap: () {
                    widget.onActivatePreset('Deen Mode', null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Deen Mode Activated: Full Web Filter & Strict Whitelist Enforced!')),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  title: 'Quick 15-Min Power Sprint',
                  description: 'Short 15-minute boost for completing immediate single tasks.',
                  icon: Icons.flash_on,
                  color: Colors.amber.shade800,
                  buttonText: 'Start 15m Sprint',
                  onTap: () => _startFocusTimer('15-Min Power Sprint', const Duration(minutes: 15)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 270,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 28, color: color),
                  ),
                  const SizedBox(height: 14),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(description, style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.3)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
