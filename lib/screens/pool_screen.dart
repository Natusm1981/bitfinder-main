import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/key_search_types.dart';
import '../models/pool_models.dart';
import '../providers/key_finder_provider.dart';
import '../providers/performance_provider.dart';
import '../services/pool_client_service.dart';
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
                const _PoolClientTab(),
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

class _PoolClientTab extends StatefulWidget {
  const _PoolClientTab();

  @override
  State<_PoolClientTab> createState() => _PoolClientTabState();
}

class _PoolClientTabState extends State<_PoolClientTab> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(
    text: PoolServerService.defaultPort.toString(),
  );
  final _deviceNameController = TextEditingController();
  int? _numThreads;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLastEndpoint();
      final performance = context.read<PerformanceProvider>();
      if (mounted) {
        setState(() => _numThreads = performance.numThreads);
      }
    });
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = context.watch<PoolClientService>();
    final performance = context.watch<PerformanceProvider>();
    final connected = client.isConnected;
    final numThreads = (_numThreads ?? performance.numThreads).clamp(
      1,
      performance.maxThreads,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          connected
              ? _ConnectedClientSummary(
                client: client,
                numThreads: numThreads,
                statusLabel: _workerStatusLabel(context, client.status),
              )
              : _ClientConnectionForm(
                hostController: _hostController,
                portController: _portController,
                deviceNameController: _deviceNameController,
                numThreads: numThreads,
                maxThreads: performance.maxThreads,
                isConnecting: client.status == PoolWorkerStatus.connecting,
                errorMessage: client.errorMessage,
                onThreadsChanged: (value) => setState(() => _numThreads = value),
                onConnect: () => _connect(client),
              ),
          const SizedBox(height: 12),
          if (connected)
            TemperatureMonitorCard(samples: client.temperatureHistory),
        ],
      ),
    );
  }

  void _connect(PoolClientService client) {
    final port =
        int.tryParse(_portController.text.trim()) ??
        PoolServerService.defaultPort;
    final performance = context.read<PerformanceProvider>();
    final numThreads = (_numThreads ?? performance.numThreads).clamp(
      1,
      performance.maxThreads,
    );
    client.connect(
      host: _hostController.text,
      port: port,
      numThreads: numThreads,
      deviceName: _deviceNameController.text,
    );
  }

  Future<void> _loadLastEndpoint() async {
    final endpoint = await context.read<PoolClientService>().loadLastEndpoint();
    if (!mounted) return;
    final host = endpoint.host;
    final port = endpoint.port;
    if (host != null && host.isNotEmpty) {
      _hostController.text = host;
    }
    if (port != null) {
      _portController.text = port.toString();
    }
  }

  String _workerStatusLabel(BuildContext context, PoolWorkerStatus status) {
    final localizations = AppLocalizations.of(context);
    return switch (status) {
      PoolWorkerStatus.disconnected => localizations.poolClientDisconnected,
      PoolWorkerStatus.connecting => localizations.poolClientConnecting,
      PoolWorkerStatus.connected => localizations.poolClientConnected,
      PoolWorkerStatus.searching => localizations.poolClientSearching,
      PoolWorkerStatus.idle => localizations.poolClientIdle,
      PoolWorkerStatus.completed => localizations.poolClientCompleted,
    };
  }
}

class _PoolHostTab extends StatefulWidget {
  const _PoolHostTab();

  @override
  State<_PoolHostTab> createState() => _PoolHostTabState();
}

class _PoolHostTabState extends State<_PoolHostTab> {
  static const String _firstHostInfoSeenKey = 'pool_first_host_info_seen';

  PoolDistributionMode _distributionMode = PoolDistributionMode.sequential;

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
                                 ? () => _startHost(
                                   context,
                                   server,
                                   keyFinder,
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
                  SegmentedButton<PoolDistributionMode>(
                    segments: [
                      ButtonSegment(
                        value: PoolDistributionMode.sequential,
                        icon: const Icon(Icons.format_list_numbered),
                        label: Text(localizations.sequential),
                      ),
                      ButtonSegment(
                        value: PoolDistributionMode.random,
                        icon: const Icon(Icons.shuffle),
                        label: Text(localizations.random),
                      ),
                    ],
                    selected: {_distributionMode},
                    onSelectionChanged:
                        server.isRunning
                            ? null
                            : (selection) {
                              setState(
                                () => _distributionMode = selection.first,
                              );
                            },
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

  Future<void> _startHost(
    BuildContext context,
    PoolServerService server,
    KeyFinderProvider keyFinder,
  ) async {
    await server.startFromSearchConfig(
      keyFinder.config,
      distributionMode: _distributionMode,
    );
    if (!context.mounted || !server.isRunning) return;
    await _showFirstHostInfoIfNeeded(context, server);
  }

  Future<void> _showFirstHostInfoIfNeeded(
    BuildContext context,
    PoolServerService server,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySeen = prefs.getBool(_firstHostInfoSeenKey) ?? false;
    if (alreadySeen || !context.mounted) return;

    await prefs.setBool(_firstHostInfoSeenKey, true);
    if (!context.mounted) return;

    final localizations = AppLocalizations.of(context);
    final modeLabel = _distributionMode == PoolDistributionMode.random
        ? localizations.random
        : localizations.sequential;
    final endpoint =
        '${server.hostAddress ?? '0.0.0.0'}:${server.config?.port ?? PoolServerService.defaultPort}';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(localizations.poolHostFirstRunTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogInfoLine(
                icon: Icons.wifi,
                text: localizations.poolHostFirstRunConnection(endpoint),
              ),
              const SizedBox(height: 12),
              _DialogInfoLine(
                icon: Icons.verified_user_outlined,
                text: localizations.poolHostFirstRunCompatibility,
              ),
              const SizedBox(height: 12),
              _DialogInfoLine(
                icon: Icons.call_split,
                text: localizations.poolHostFirstRunRangeMode(modeLabel),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(localizations.ok),
            ),
          ],
        );
      },
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

class _ClientConnectionForm extends StatelessWidget {
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController deviceNameController;
  final int numThreads;
  final int maxThreads;
  final bool isConnecting;
  final String? errorMessage;
  final ValueChanged<int> onThreadsChanged;
  final VoidCallback onConnect;

  const _ClientConnectionForm({
    required this.hostController,
    required this.portController,
    required this.deviceNameController,
    required this.numThreads,
    required this.maxThreads,
    required this.isConnecting,
    required this.onThreadsChanged,
    required this.onConnect,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.link_off, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizations.poolClientWorker,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: hostController,
              decoration: InputDecoration(
                labelText: localizations.poolHostIp,
                prefixIcon: const Icon(Icons.router),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: portController,
                    decoration: InputDecoration(
                      labelText: localizations.poolPort,
                      prefixIcon: const Icon(Icons.numbers),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: deviceNameController,
                    decoration: InputDecoration(
                      labelText: localizations.poolDeviceName,
                      prefixIcon: const Icon(Icons.smartphone),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${localizations.cpuThreads}: $numThreads',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  onPressed:
                      numThreads <= 1
                          ? null
                          : () => onThreadsChanged(numThreads - 1),
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed:
                      numThreads >= maxThreads
                          ? null
                          : () => onThreadsChanged(numThreads + 1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            Slider(
              value: numThreads.toDouble(),
              min: 1,
              max: maxThreads.toDouble(),
              divisions: maxThreads > 1 ? maxThreads - 1 : null,
              label: numThreads.toString(),
              onChanged: (value) => onThreadsChanged(value.round()),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isConnecting ? null : onConnect,
              icon: const Icon(Icons.play_arrow),
              label: Text(localizations.poolConnect),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                '${localizations.poolConnectionError}: $errorMessage',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DialogInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DialogInfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _ConnectedClientSummary extends StatelessWidget {
  final PoolClientService client;
  final int numThreads;
  final String statusLabel;

  const _ConnectedClientSummary({
    required this.client,
    required this.numThreads,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final temperature = client.batteryTemperatureCelsius;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.link, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    client.host == null ? statusLabel : '${client.host}:${client.port}',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () => client.disconnect(),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(localizations.poolDisconnect),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _CompactMetricRow(
                        label: localizations.status,
                        value: statusLabel,
                      ),
                      _CompactMetricRow(
                        label: localizations.keysChecked,
                        value: _PoolHostTabState._formatBigInt(
                          client.totalKeysChecked,
                        ),
                      ),
                      _CompactMetricRow(
                        label: localizations.temperature,
                        value:
                            temperature == null
                                ? localizations.unavailable
                                : '${temperature.toStringAsFixed(1)} °C',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      _CompactMetricRow(
                        label: localizations.speed,
                        value: _PoolHostTabState._formatSpeed(client.speed),
                      ),
                      _CompactMetricRow(
                        label: localizations.cpuThreads,
                        value: numThreads.toString(),
                      ),
                      _CompactMetricRow(
                        label: localizations.poolCurrentRange,
                        value: client.currentRangeId ?? '-',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _CompactMetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TemperatureMonitorCard extends StatelessWidget {
  final List<TemperatureSample> samples;

  const TemperatureMonitorCard({super.key, required this.samples});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.thermostat, size: 18, color: Colors.deepOrange),
              const SizedBox(width: 6),
              Text(
                localizations.temperatureMonitor,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (samples.isNotEmpty)
                Text(
                  '${samples.last.celsius.toStringAsFixed(1)} °C',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                samples.length < 2
                    ? Center(
                      child: Text(
                        localizations.poolCollectingTemperature,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    )
                    : RepaintBoundary(
                      child: CustomPaint(
                        painter: _TemperatureChartPainter(samples),
                        child: const SizedBox.expand(),
                      ),
                    ),
          ),
        ],
      ),
    );
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
      trailing: Text(_PoolHostTabState._formatSpeed(client.speed)),
    );
  }
}

class _TemperatureChartPainter extends CustomPainter {
  final List<TemperatureSample> samples;

  const _TemperatureChartPainter(this.samples);

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2 || size.width <= 0 || size.height <= 0) return;

    final values = samples.map((sample) => sample.celsius).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final lowerBound = math.max(0.0, minValue - 2.0);
    final upperBound = maxValue + 2.0;
    final range = math.max(1.0, upperBound - lowerBound);

    final gridPaint =
        Paint()
          ..color = Colors.grey.withAlpha(70)
          ..strokeWidth = 1;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    const labelWidth = 42.0;
    final chartRect = Rect.fromLTWH(
      labelWidth,
      0,
      size.width - labelWidth,
      size.height - 14,
    );

    for (var i = 0; i <= 2; i++) {
      final y = chartRect.top + chartRect.height * i / 2;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
      final label = upperBound - range * i / 2;
      textPainter.text = TextSpan(
        text: label.toStringAsFixed(0),
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      textPainter.layout(minWidth: 0, maxWidth: labelWidth - 6);
      textPainter.paint(
        canvas,
        Offset(labelWidth - textPainter.width - 6, y - 6),
      );
    }

    final linePaint =
        Paint()
          ..color = Colors.deepOrange
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepOrange.withAlpha(80),
              Colors.deepOrange.withAlpha(0),
            ],
          ).createShader(chartRect);

    Offset pointFor(int index, double value) {
      final x = chartRect.left + chartRect.width * index / (samples.length - 1);
      final normalized = (value - lowerBound) / range;
      final y = chartRect.bottom - chartRect.height * normalized;
      return Offset(x, y.clamp(chartRect.top, chartRect.bottom));
    }

    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < samples.length; i++) {
      final point = pointFor(i, samples[i].celsius);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
        fillPath.moveTo(point.dx, chartRect.bottom);
        fillPath.lineTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
        fillPath.lineTo(point.dx, point.dy);
      }
    }
    fillPath.lineTo(chartRect.right, chartRect.bottom);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TemperatureChartPainter oldDelegate) =>
      oldDelegate.samples != samples;
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
