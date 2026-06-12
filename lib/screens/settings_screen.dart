import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/theme_provider.dart';
import '../providers/history_provider.dart';
import '../providers/performance_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
// import '../utils/fast_crypto.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = packageInfo.version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).settings)),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader('Performance'),
          Consumer<PerformanceProvider>(
            builder: (context, perfProvider, child) {
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.speed),
                    title: Text(
                      AppLocalizations.of(context).performanceSettings,
                    ),
                    subtitle: Text(
                      'CPU: ${perfProvider.maxThreads} ${AppLocalizations.of(context).coresAvailable}\n'
                      '${perfProvider.numThreads} thread${perfProvider.numThreads > 1 ? "s" : ""}',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Text('1'),
                        Expanded(
                          child: Slider(
                            value: perfProvider.numThreads.toDouble(),
                            min: 1,
                            max: perfProvider.maxThreads.toDouble(),
                            divisions: perfProvider.maxThreads - 1,
                            label: perfProvider.numThreads.toString(),
                            onChanged: (value) {
                              final newValue = value.toInt();

                              // Mostrar aviso se selecionar todas as threads
                              if (newValue == perfProvider.maxThreads &&
                                  perfProvider.maxThreads > 1) {
                                _showMaxThreadsWarning(
                                  context,
                                  perfProvider,
                                  newValue,
                                );
                              } else {
                                perfProvider.setNumThreads(newValue);
                              }
                            },
                          ),
                        ),
                        Text('${perfProvider.maxThreads}'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(
                          perfProvider.isUsingMaxThreads
                              ? Icons.warning_amber
                              : Icons.info_outline,
                          size: 16,
                          color:
                              perfProvider.isUsingMaxThreads
                                  ? Colors.orange
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            perfProvider.isUsingMaxThreads
                                ? '${AppLocalizations.of(context).threadsUsingMaxWarning} ${perfProvider.recommendedThreads} ${AppLocalizations.of(context).threads}'
                                : '${AppLocalizations.of(context).threadsSuggested} ${perfProvider.recommendedThreads} ${AppLocalizations.of(context).threads}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  perfProvider.isUsingMaxThreads
                                      ? Colors.orange
                                      : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(AppLocalizations.of(context).appearance),
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              return ListTile(
                leading: const Icon(Icons.language),
                title: Text(AppLocalizations.of(context).language),
                subtitle: Text(
                  localeProvider.getLanguageName(localeProvider.locale),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showLanguageDialog(context),
              );
            },
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return SwitchListTile(
                title: Text(AppLocalizations.of(context).darkMode),
                subtitle: Text(
                  themeProvider.isDarkMode
                      ? AppLocalizations.of(context).darkModeEnabled
                      : AppLocalizations.of(context).lightModeEnabled,
                ),
                secondary: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(AppLocalizations.of(context).history),
          Consumer<HistoryProvider>(
            builder: (context, historyProvider, child) {
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(AppLocalizations.of(context).history),
                subtitle: Text(
                  '${historyProvider.historyCount} ${historyProvider.historyCount == 1 ? "item" : "itens"} ${AppLocalizations.of(context).stored} ${historyProvider.historyCount == 1 ? "" : "s"}',
                ),
                trailing:
                    historyProvider.historyCount > 0
                        ? TextButton(
                          onPressed:
                              () => _showClearHistoryDialog(
                                context,
                                historyProvider,
                              ),
                          child: Text(AppLocalizations.of(context).clear),
                        )
                        : null,
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(AppLocalizations.of(context).about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppLocalizations.of(context).version),
            subtitle: Text(_version),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Bit Finder'),
            subtitle: Text(AppLocalizations.of(context).replica),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.orange.withAlpha(25),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange[700],
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context).legalNotice,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).legalNoticeContent,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.orange[700],
        ),
      ),
    );
  }

  void _showMaxThreadsWarning(
    BuildContext context,
    PerformanceProvider perfProvider,
    int selectedThreads,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            icon: const Icon(
              Icons.warning_amber,
              color: Colors.orange,
              size: 48,
            ),
            title: Text(AppLocalizations.of(context).performanceWarningTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).performanceWarningMessage,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${AppLocalizations.of(context).recommended} ${perfProvider.recommendedThreads} threads',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  perfProvider.setNumThreads(perfProvider.recommendedThreads);
                },
                child: Text(
                  '${AppLocalizations.of(context).use} ${perfProvider.recommendedThreads} (${AppLocalizations.of(context).recommended})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  perfProvider.setNumThreads(selectedThreads);
                },
                child: Text(
                  '${AppLocalizations.of(context).use} ${perfProvider.maxThreads} (${AppLocalizations.of(context).takeRisk})',
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.language),
          content: RadioGroup<Locale>(
            groupValue: localeProvider.locale,
            onChanged: (Locale? value) {
              if (value != null) {
                localeProvider.setLocale(value);
                Navigator.pop(dialogContext);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  AppLocalizations.supportedLocales.map((locale) {
                    final isSelected = localeProvider.locale == locale;
                    return RadioListTile<Locale>(
                      title: Text(localeProvider.getLanguageName(locale)),
                      value: locale,
                      selected: isSelected,
                    );
                  }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  void _showClearHistoryDialog(
    BuildContext context,
    HistoryProvider historyProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).clearHistory),
            content: Text(AppLocalizations.of(context).clearHistoryConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () {
                  historyProvider.clearHistory();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context).historyClearedSuccessfully,
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: Text(AppLocalizations.of(context).clearHistory),
              ),
            ],
          ),
    );
  }
}
