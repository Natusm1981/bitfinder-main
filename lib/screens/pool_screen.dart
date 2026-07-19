import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/pool_models.dart';
import '../providers/key_finder_provider.dart';
import '../services/pool_server_service.dart';

class PoolScreen extends StatelessWidget {
  final bool showAppBar;

  const PoolScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final content = DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              tabs: [
                Tab(
                  icon: const Icon(Icons.wifi_tethering),
                  text: localizations.poolHost,
                ),
                Tab(
                  icon: const Icon(Icons.devices_other),
                  text: localizations.poolClients,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                const _PoolHostTab(),
                _ComingSoonPanel(
                  icon: Icons.devices_other,
                  title: localizations.poolClients,
                  message: localizations.comingSoon,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!showAppBar) return content;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.menuPool),
        centerTitle: true,
      ),
      body: content,
    );
  }
}

class _PoolHostTab extends StatelessWidget {
  const _PoolHostTab();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final keyFinder = context.watch<KeyFinderProvider>();
    final server = context.watch<PoolServerService>();
    final canStart = keyFinder.config.targets.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        server.isRunning
                            ? Icons.wifi_tethering
                            : Icons.wifi_tethering_off,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localizations.poolServer,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed:
                            server.isStarting
                                ? null
                                : server.isRunning
                                ? () => server.stop()
                                : canStart
                                ? () => server.startFromSearchConfig(
                                  keyFinder.config,
                                )
                                : null,
                        icon: Icon(
                          server.isRunning ? Icons.stop : Icons.play_arrow,
                        ),
                        label: Text(
                          server.isRunning
                              ? localizations.poolStopHost
                              : localizations.poolStartHost,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    server.isRunning
                        ? localizations.poolHostReady
                        : localizations.poolHostStopped,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (!canStart && !server.isRunning) ...[
                    const SizedBox(height: 8),
                    Text(
                      localizations.addTargetWarning,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  if (server.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${localizations.poolServerError}: ${server.errorMessage}',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  if (server.isRunning) ...[
                    const SizedBox(height: 16),
                    _InfoRow(
                      label: localizations.poolHostAddress,
                      value:
                          '${server.hostAddress ?? '0.0.0.0'}:${server.config?.port ?? PoolServerService.defaultPort}',
                    ),
                    _InfoRow(
                      label: localizations.poolUseCurrentSearchConfig,
                      value:
                          '${keyFinder.config.targets.length} ${localizations.targets}',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    localizations.progress,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: server.completedPercent),
                  const SizedBox(height: 8),
                  Text(
                    '${(server.completedPercent * 100).toStringAsFixed(4)}%',
                    textAlign: TextAlign.end,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: localizations.poolCompletedRangesStored,
                    value: server.completedRangeCount.toString(),
                  ),
                  _InfoRow(
                    label: localizations.poolRangesActive,
                    value: server.assignedRangeCount.toString(),
                  ),
                  _InfoRow(
                    label: localizations.keysChecked,
                    value: _formatBigInt(server.completedKeys),
                  ),
                  _InfoRow(
                    label: localizations.poolLiveProgress,
                    value: '${(server.livePercent * 100).toStringAsFixed(4)}%',
                  ),
                  _InfoRow(
                    label: localizations.poolTotalSpeed,
                    value: _formatSpeed(server.totalSpeed),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    localizations.poolConnectedClients,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (server.clients.isEmpty)
                    Text(localizations.poolNoClients)
                  else
                    ...server.clients.map(
                      (client) => _ClientTile(client: client),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatBigInt(BigInt value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  static String _formatSpeed(double speed) {
    if (speed >= 1000000) {
      return '${(speed / 1000000).toStringAsFixed(2)} M key/s';
    }
    if (speed >= 1000) {
      return '${(speed / 1000).toStringAsFixed(1)} K key/s';
    }
    return '${speed.toStringAsFixed(0)} key/s';
  }
}

class _ClientTile extends StatelessWidget {
  final PoolClientInfo client;

  const _ClientTile({required this.client});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final statusLabel = switch (client.status) {
      PoolClientStatus.connected => localizations.poolClientConnected,
      PoolClientStatus.searching => localizations.poolClientSearching,
      PoolClientStatus.idle => localizations.poolClientIdle,
      PoolClientStatus.disconnected => localizations.poolClientDisconnected,
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.smartphone),
      title: Text(client.deviceName),
      subtitle: Text(
        client.currentRangeId == null
            ? '${client.address} - $statusLabel'
            : '${client.address} - $statusLabel - ${localizations.poolCurrentRange}: ${client.currentRangeId}',
      ),
      trailing: Text(_PoolHostTab._formatSpeed(client.speed)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ComingSoonPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
