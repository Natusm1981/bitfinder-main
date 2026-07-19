import 'dart:async';
import 'dart:math' as math;
import 'package:bit_finder/widgets/propagandas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../providers/key_finder_provider.dart';
import '../providers/history_provider.dart';
import '../providers/search_progress_provider.dart';
import '../providers/performance_provider.dart';
// import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/key_search_types.dart';
import '../models/wallet_challenge.dart';
import '../services/challenge_loader.dart';
import '../widgets/progress_heatmap.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'about_screen.dart';
import 'pool_screen.dart';

class KeyFinderScreen extends StatefulWidget {
  const KeyFinderScreen({super.key});

  @override
  State<KeyFinderScreen> createState() => _KeyFinderScreenState();
}

class _KeyFinderScreenState extends State<KeyFinderScreen> {
  final _addressController = TextEditingController();
  final _keyspaceController = TextEditingController();
  final _strideController = TextEditingController(text: '1');

  bool _isVibrating = false;
  late final Future<WalletChallengeCollection> _challengesFuture;
  Timer? _statusUpdateTimer;
  WalletChallenge? _selectedChallenge;
  String? _lastSyncedConfig;
  int _selectedNavigationIndex = 0;
  final BannerAdWidget _bannerAd = const BannerAdWidget();

  @override
  void initState() {
    super.initState();
    // Carregar desafios uma única vez
    _challengesFuture = ChallengeLoader.loadChallenges();

    // Listener para detectar quando chaves são encontradas
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<KeyFinderProvider>(context, listen: false);
      final historyProvider = Provider.of<HistoryProvider>(
        context,
        listen: false,
      );
      final progressProvider = Provider.of<SearchProgressProvider>(
        context,
        listen: false,
      );
      final performanceProvider = Provider.of<PerformanceProvider>(
        context,
        listen: false,
      );
      provider.setHistoryProvider(historyProvider);
      provider.setProgressProvider(progressProvider);
      provider.setPerformanceProvider(performanceProvider);
      provider.addListener(_checkForResults);
      provider.addListener(_syncConfigurationFields);
      await provider.initialized;
      if (mounted) _syncConfigurationFields();
    });
  }

  void _syncConfigurationFields() {
    if (!mounted) return;
    final provider = Provider.of<KeyFinderProvider>(context, listen: false);
    if (provider.isRunning) return;
    final config = provider.config;
    final signature =
        '${config.startKey}:${config.endKey}:${config.stride}:'
        '${config.compression.index}:${config.searchMode.index}:'
        '${config.challengeId}:${config.targets.map((target) => target.address).join(',')}';
    if (_lastSyncedConfig == signature) return;
    _lastSyncedConfig = signature;

    _keyspaceController.text =
        '${config.startKey.toRadixString(16)}:${config.endKey.toRadixString(16)}';
    _strideController.text = config.stride.toRadixString(16);
    _addressController.text =
        config.targets.isEmpty ? '' : config.targets.first.address;

    final challengeId = config.challengeId;
    if (challengeId == null) {
      if (_selectedChallenge != null) {
        setState(() => _selectedChallenge = null);
      }
    } else if (_selectedChallenge?.id != challengeId) {
      unawaited(_restoreSelectedChallenge(challengeId));
    }
  }

  Future<void> _restoreSelectedChallenge(int challengeId) async {
    final collection = await _challengesFuture;
    WalletChallenge? challenge;
    for (final candidate in collection.challenges) {
      if (candidate.id == challengeId) {
        challenge = candidate;
        break;
      }
    }
    if (!mounted) return;
    final provider = Provider.of<KeyFinderProvider>(context, listen: false);
    if (provider.config.challengeId == challengeId) {
      setState(() => _selectedChallenge = challenge);
    }
  }

  void _checkSearchRunning() {
    final provider = Provider.of<KeyFinderProvider>(context, listen: false);
    if (provider.isRunning && _statusUpdateTimer == null) {
      // Iniciar timer quando começar a busca
      _statusUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted && provider.isRunning) {
          setState(() {}); // Forçar rebuild para atualizar velocidade
        }
      });
    } else if (!provider.isRunning && _statusUpdateTimer != null) {
      // Parar timer quando parar a busca
      _statusUpdateTimer?.cancel();
      _statusUpdateTimer = null;
    }
  }

  void _checkForResults() {
    final provider = Provider.of<KeyFinderProvider>(context, listen: false);
    if (provider.results.isNotEmpty && !_isVibrating) {
      _showKeyFoundDialog(provider.results.last);
    }
  }

  @override
  void dispose() {
    final provider = Provider.of<KeyFinderProvider>(context, listen: false);
    provider.removeListener(_checkForResults);
    provider.removeListener(_syncConfigurationFields);
    provider.removeListener(_checkSearchRunning);
    _statusUpdateTimer?.cancel();
    _addressController.dispose();
    _keyspaceController.dispose();
    _strideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_navigationTitle(context)),
          centerTitle: true,

          // actions: [
          //   Consumer<LocaleProvider>(
          //     builder: (context, localeProvider, child) {
          //       return PopupMenuButton<Locale>(
          //         icon: const Icon(Icons.language),
          //         tooltip: AppLocalizations.of(context).language,
          //         onSelected: (Locale locale) {
          //           localeProvider.setLocale(locale);
          //         },
          //         itemBuilder: (BuildContext context) {
          //           return AppLocalizations.supportedLocales.map((Locale locale) {
          //             return PopupMenuItem<Locale>(
          //               value: locale,
          //               child: Row(
          //                 children: [
          //                   if (localeProvider.locale == locale)
          //                     const Icon(Icons.check, size: 20)
          //                   else
          //                     const SizedBox(width: 20),
          //                   const SizedBox(width: 8),
          //                   Text(localeProvider.getLanguageName(locale)),
          //                 ],
          //               ),
          //             );
          //           }).toList();
          //         },
          //       );
          //     },
          //   ),
          // ],
        ),
        floatingActionButton:
            _selectedNavigationIndex == 0
                ? Consumer<KeyFinderProvider>(
                  builder:
                      (context, provider, child) =>
                          _buildSearchFloatingActionButton(provider),
                )
                : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedNavigationIndex,
          onDestinationSelected:
              (index) => setState(() => _selectedNavigationIndex = index),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: const Icon(Icons.history),
              label: AppLocalizations.of(context).history,
            ),
            NavigationDestination(
              icon: const Icon(Icons.device_hub_outlined),
              selectedIcon: const Icon(Icons.device_hub),
              label: AppLocalizations.of(context).menuPool,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: AppLocalizations.of(context).settings,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildBannerAd(),
            Expanded(child: _buildCurrentScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerAd() {
    return Container(
      height: 50,
      color: Colors.grey.withAlpha(25),
      child: Center(child: _bannerAd),
    );
  }

  Widget _buildCurrentScreen() {
    return switch (_selectedNavigationIndex) {
      1 => const HistoryScreen(showAppBar: false),
      2 => const PoolScreen(showAppBar: false),
      3 => const SettingsScreen(showAppBar: false),
      _ => _buildHomeTab(),
    };
  }

  String _navigationTitle(BuildContext context) {
    return switch (_selectedNavigationIndex) {
      1 => AppLocalizations.of(context).history,
      2 => AppLocalizations.of(context).menuPool,
      3 => AppLocalizations.of(context).settings,
      _ => 'Bit Finder',
    };
  }

  Widget _buildHomeTab() {
    return Consumer<KeyFinderProvider>(
      builder: (context, provider, child) {
        // Se está rodando, mostra apenas o status
        if (provider.isRunning) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_buildStatusSection(provider)],
            ),
          );
        }

                  // Se não está rodando, mostra tudo
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Mensagem informativa sobre histórico
                        if (provider.results.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withAlpha(76),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context).keyFound,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        ).resultsSavedToHistory,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.history,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    setState(() => _selectedNavigationIndex = 1);
                                  },
                                  tooltip: 'Ver Histórico',
                                ),
                              ],
                            ),
                          ),
                        _buildChallengesSection(provider),
                        const SizedBox(height: 24),
                        _buildTargetsSection(provider),
                        const SizedBox(height: 24),
                        _buildConfigurationSection(provider),
                        const SizedBox(height: 24),
                        _buildControlsSection(provider),
                        const SizedBox(height: 24),
                        _buildResultsSection(provider),
                      ],
                    ),
                  );
      },
    );
  }

  Widget _buildSearchFloatingActionButton(KeyFinderProvider provider) {
    final isRunning = provider.isRunning;
    final canStart = provider.canStartSearch;
    return FloatingActionButton.extended(
      heroTag: 'search-action',
      onPressed:
          isRunning
              ? () => provider.stopSearch()
              : (canStart ? () => provider.startSearch() : null),
      icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
      label: Text(
        isRunning
            ? AppLocalizations.of(context).stop
            : AppLocalizations.of(context).startSearch,
      ),
      backgroundColor: isRunning ? Colors.red : null,
      foregroundColor: isRunning ? Colors.white : null,
    );
  }

  Widget _buildChallengesSection(KeyFinderProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).bitcoinPuzzleChallenges,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<WalletChallengeCollection>(
              future: _challengesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppLocalizations.of(context).errorLoadingChallenges}: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final collection = snapshot.data!;
                final solvedChallenges =
                    collection.challenges.where((c) => c.solved).toList();
                final unsolvedChallenges =
                    collection.challenges.where((c) => !c.solved).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context).selectChallenge,
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${AppLocalizations.of(context).challengesSolved} (${solvedChallenges.length}) - ${AppLocalizations.of(context).forTesting}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: solvedChallenges.length,
                        itemBuilder: (context, index) {
                          final challenge = solvedChallenges[index];
                          return _buildChallengeCard(
                            challenge,
                            provider,
                            isSolved: true,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${AppLocalizations.of(context).challengesUnsolved} (${unsolvedChallenges.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: unsolvedChallenges.length,
                        itemBuilder: (context, index) {
                          final challenge = unsolvedChallenges[index];
                          return _buildChallengeCard(
                            challenge,
                            provider,
                            isSolved: false,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(
    WalletChallenge challenge,
    KeyFinderProvider provider, {
    required bool isSolved,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(right: 12),
      color:
          isSolved ? Colors.green.withAlpha(12) : Colors.orange.withAlpha(12),
      child: InkWell(
        onTap:
            provider.isRunning
                ? null
                : () {
                  provider.loadChallenge(challenge);
                  // Atualizar o campo de texto do keyspace
                  _keyspaceController.text = challenge.keyspace;
                  _addressController.text = challenge.btcAddress;
                  setState(() {
                    _selectedChallenge = challenge;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${challenge.name} carregado! Address, Keyspace e Compression configurados.',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isSolved ? Icons.check_circle : Icons.lock,
                    color: isSolved ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      challenge.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.memory, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${challenge.bits} bits',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.vpn_key, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      challenge.keyspace,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (isSolved)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    AppLocalizations.of(context).solved.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    AppLocalizations.of(context).unsolved.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetsSection(KeyFinderProvider provider) {
    final challengeId = provider.config.challengeId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.orange),
                const SizedBox(width: 8),
                Flexible(
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.titleLarge,
                      children: [
                        TextSpan(
                          text: AppLocalizations.of(context).targetAddress,
                        ),
                        if (challengeId != null)
                          TextSpan(
                            text:
                                '  ${AppLocalizations.of(context).challenge} #$challengeId',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).bitcoinAddress,
                      hintText: '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                    enabled: !provider.isRunning,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed:
                      provider.isRunning
                          ? null
                          : () {
                            if (_addressController.text.isNotEmpty) {
                              provider.addTarget(_addressController.text);
                            }
                          },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.config.targets.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).addTargetWarning,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.config.targets.length,
                itemBuilder: (context, index) {
                  final target = provider.config.targets[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: Text(
                      target.address,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed:
                          provider.isRunning
                              ? null
                              : () => provider.removeTarget(index),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationSection(KeyFinderProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).settings,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keyspaceController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).keyspaceOptional,
                hintText: AppLocalizations.of(context).keyspaceHint,
                border: OutlineInputBorder(),
                helperText: AppLocalizations.of(context).keyspaceHelper,
              ),
              enabled: !provider.isRunning,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  provider.setKeyspace(value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _strideController,
              decoration: InputDecoration(
                labelText: '${AppLocalizations.of(context).stride} (hex)',
                hintText: '1',
                border: OutlineInputBorder(),
                helperText: AppLocalizations.of(context).strideHint,
              ),
              enabled: !provider.isRunning,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  provider.setStride(value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PointCompressionType>(
              key: ValueKey(provider.config.compression),
              initialValue: provider.config.compression,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).compression,
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: PointCompressionType.compressed,
                  child: Text(AppLocalizations.of(context).compressed),
                ),
                DropdownMenuItem(
                  value: PointCompressionType.uncompressed,
                  child: Text(AppLocalizations.of(context).uncompressed),
                ),
                DropdownMenuItem(
                  value: PointCompressionType.both,
                  child: Text(AppLocalizations.of(context).both),
                ),
              ],
              onChanged:
                  provider.isRunning
                      ? null
                      : (value) {
                        if (value != null) {
                          provider.setCompressionMode(value);
                        }
                      },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SearchMode>(
              key: ValueKey(provider.config.searchMode),
              initialValue: provider.config.searchMode,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).searchMode,
                border: OutlineInputBorder(),
                helperText: AppLocalizations.of(context).searchModeHint,
              ),
              items: [
                DropdownMenuItem(
                  value: SearchMode.sequential,
                  child: Row(
                    children: [
                      Icon(Icons.arrow_forward, size: 20),
                      SizedBox(width: 8),
                      Text(AppLocalizations.of(context).sequential),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: SearchMode.random,
                  child: Row(
                    children: [
                      Icon(Icons.shuffle, size: 20),
                      SizedBox(width: 8),
                      Text(AppLocalizations.of(context).random),
                    ],
                  ),
                ),
              ],
              onChanged:
                  provider.isRunning
                      ? null
                      : (value) {
                        if (value != null) {
                          provider.setSearchMode(value);
                        }
                      },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsSection(KeyFinderProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Thread info display
            if (!provider.isRunning)
              Consumer<PerformanceProvider>(
                builder: (context, perfProvider, child) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.speed, color: Colors.orange, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).performance,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${perfProvider.numThreads} ${AppLocalizations.of(context).threads}${perfProvider.numThreads > 1 ? "s" : ""} / ${perfProvider.maxThreads} ${AppLocalizations.of(context).available}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedNavigationIndex = 3);
                          },
                          child: Text(AppLocalizations.of(context).settings),
                        ),
                      ],
                    ),
                  );
                },
              ),
            if (!provider.isRunning) const SizedBox(height: 16),
            if (provider.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: provider.clearError,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(KeyFinderProvider provider) {
    final status = provider.currentStatus;

    if (!provider.isRunning) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status Card
        Card(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.analytics, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      _selectedChallenge != null
                          ? '${AppLocalizations.of(context).status} - ${AppLocalizations.of(context).challenge} #${_selectedChallenge!.id}'
                          : AppLocalizations.of(context).status,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (status != null) ...[
                  _buildStatusRow(
                    AppLocalizations.of(context).device,
                    status.deviceName,
                  ),
                  _buildStatusRow(
                    AppLocalizations.of(context).targets,
                    status.targets.toString(),
                  ),
                  _buildStatusRow(
                    AppLocalizations.of(context).speed,
                    status.speedFormatted,
                  ),
                  _buildStatusRow(
                    AppLocalizations.of(context).totalKeys,
                    status.totalFormatted,
                  ),
                  _buildStatusRow(
                    AppLocalizations.of(context).elapsed,
                    status.timeFormatted,
                  ),
                  _buildStatusRow(
                    AppLocalizations.of(context).temperature,
                    status.batteryTemperatureCelsius == null
                        ? AppLocalizations.of(context).unavailable
                        : '${status.batteryTemperatureCelsius!.toStringAsFixed(1)} °C',
                  ),
                  _buildStatusRow(
                    AppLocalizations.of(context).thermalState,
                    AppLocalizations.of(
                      context,
                    ).thermalStatusLabel(status.thermalStatus),
                  ),
                  const SizedBox(height: 16),
                  _buildTemperatureChart(provider.temperatureHistory),
                ],
              ],
            ),
          ),
        ),
        // Progress Heatmap - Apenas mostrar no modo Sequential
        if (provider.config.searchMode == SearchMode.sequential) ...[
          const SizedBox(height: 16),
          Center(
            child: Consumer<SearchProgressProvider>(
              builder: (context, progressProvider, child) {
                final progress = progressProvider.currentProgress;
                if (progress != null) {
                  return RepaintBoundary(
                    child: ProgressHeatmap(progress: progress),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTemperatureChart(List<TemperatureSample> samples) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(
          90,
        ),
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
                AppLocalizations.of(context).temperatureMonitor,
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
                        'Coletando leituras...',
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

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(KeyFinderProvider provider) {
    if (provider.results.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.celebration, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context).results} (${provider.results.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: provider.clearResults,
                  icon: const Icon(Icons.clear_all),
                  label: Text(AppLocalizations.of(context).clear),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.results.length,
              itemBuilder: (context, index) {
                final result = provider.results[index];
                return Card(
                  color: Colors.green.withAlpha(25),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${AppLocalizations.of(context).found}: ${result.foundAt.toLocal()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: result.toString()),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(context).copied,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const Divider(),
                        _buildResultRow(
                          AppLocalizations.of(context).address,
                          result.address,
                        ),
                        _buildResultRow(
                          '${AppLocalizations.of(context).privateKey} (Hex)',
                          result.privateKeyHex,
                        ),
                        _buildResultRow(
                          '${AppLocalizations.of(context).privateKey} (WIF)',
                          result.privateKeyWIF,
                        ),
                        _buildResultRow(
                          AppLocalizations.of(context).compressed,
                          result.compressed
                              ? AppLocalizations.of(context).yes
                              : AppLocalizations.of(context).no,
                        ),
                        _buildResultRow(
                          AppLocalizations.of(context).publicKeyX,
                          result.publicKeyX,
                        ),
                        if (!result.compressed)
                          _buildResultRow(
                            AppLocalizations.of(context).publicKeyY,
                            result.publicKeyY,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ],
      ),
    );
  }

  Future<void> _showKeyFoundDialog(KeySearchResult result) async {
    setState(() {
      _isVibrating = true;
    });

    // Iniciar vibração contínua
    _startContinuousVibration();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.celebration, color: Colors.green, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🎉 ${AppLocalizations.of(context).keyFound.toUpperCase()}!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).stopSearchKeyFound,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDialogResultRow(
                      AppLocalizations.of(context).address,
                      result.address,
                    ),
                    const SizedBox(height: 12),
                    _buildDialogResultRow(
                      '${AppLocalizations.of(context).privateKey} (Hex)',
                      result.privateKeyHex,
                    ),
                    const SizedBox(height: 12),
                    _buildDialogResultRow(
                      '${AppLocalizations.of(context).privateKey} (WIF)',
                      result.privateKeyWIF,
                    ),
                    const SizedBox(height: 12),
                    _buildDialogResultRow(
                      '${AppLocalizations.of(context).privateKey} (Dec)',
                      result.privateKey.toString(),
                    ),
                    const SizedBox(height: 12),
                    _buildDialogResultRow(
                      AppLocalizations.of(context).compressed,
                      result.compressed
                          ? AppLocalizations.of(context).yes
                          : AppLocalizations.of(context).no,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context).storeKeySafely,
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: result.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Resultado copiado para área de transferência',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar Tudo'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                ),
                FilledButton.icon(
                  onPressed: () {
                    _stopVibration();
                    setState(() {
                      _isVibrating = false;
                    });
                    // Limpar campos de texto para novo desafio
                    // Limpar resultados e configuração do provider
                    final provider = Provider.of<KeyFinderProvider>(
                      context,
                      listen: false,
                    );
                    provider.clearResults();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('OK'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ),
    );

    _stopVibration();
    setState(() {
      _isVibrating = false;
    });
  }

  Widget _buildDialogResultRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
      ],
    );
  }

  Future<void> _startContinuousVibration() async {
    // Verifica se o dispositivo suporta vibração
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Vibração contínua: 500ms ligado, 200ms desligado
      Vibration.vibrate(pattern: [0, 500, 200], repeat: 0);
    }
  }

  void _stopVibration() {
    Vibration.cancel();
  }

  // ignore: unused_element
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.search,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bit Finder',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Bitcoin Key Finder',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Histórico'),
            trailing: Consumer<HistoryProvider>(
              builder: (context, provider, child) {
                if (provider.historyCount == 0) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${provider.historyCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                );
              },
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Sobre'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'v0.1.0',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemperatureChartPainter extends CustomPainter {
  final List<TemperatureSample> samples;

  _TemperatureChartPainter(this.samples);

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
      final x =
          chartRect.left + chartRect.width * index / (samples.length - 1);
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
