import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';
import '../l10n/app_localizations.dart';

class HistoryScreen extends StatelessWidget {
  final bool showAppBar;

  const HistoryScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar:
            showAppBar
                ? AppBar(
                  title: Text(AppLocalizations.of(context).history),
                  actions: _buildAppBarActions(context),
                )
                : null,
        body: _buildBody(context),
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      Consumer<HistoryProvider>(
        builder: (context, provider, child) {
          if (provider.historyCount == 0) return const SizedBox();
          return PopupMenuButton(
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_sweep, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context).clearHistory),
                      ],
                    ),
                  ),
                ],
            onSelected: (value) {
              if (value == 'clear') {
                _showClearDialog(context, provider);
              }
            },
          );
        },
      ),
    ];
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, provider, child) {
        if (provider.historyCount == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).noKeysFound,
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.historyCount,
          itemBuilder: (context, index) {
            final result = provider.history[index];
            final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: const Icon(Icons.key, color: Colors.green),
                title: Text(
                  result.address,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
                subtitle: Text(
                  result.challengeId != null
                      ? '${AppLocalizations.of(context).challenge} #${result.challengeId} - ${dateFormat.format(result.foundAt)}'
                      : dateFormat.format(result.foundAt),
                  style: const TextStyle(fontSize: 10),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red[300],
                  tooltip: AppLocalizations.of(context).deleteRecord,
                  onPressed: () => _showDeleteDialog(context, provider, index),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withAlpha(77),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context).bitcoinAddress,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: result.address),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(
                                              context,
                                            ).copied,
                                          ),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                result.address,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).privateKeys,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildRow('Hex', result.privateKeyHex, context),
                        const SizedBox(height: 8),
                        _buildRow('WIF', result.privateKeyWIF, context),
                        const SizedBox(height: 8),
                        _buildRow('Dec', result.privateKey.toString(), context),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  final keyAndAddress =
                                      '${AppLocalizations.of(context).address}: ${result.address}\n'
                                      '${AppLocalizations.of(context).privateKey} (WIF): ${result.privateKeyWIF}';
                                  Clipboard.setData(
                                    ClipboardData(text: keyAndAddress),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).copyKeyAddress,
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_all, size: 16),
                                label: Text(
                                  '${AppLocalizations.of(context).key} + ${AppLocalizations.of(context).address}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
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
                                icon: const Icon(Icons.content_copy, size: 16),
                                label: Text(
                                  AppLocalizations.of(context).copyAll,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRow(String label, String value, BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label ${AppLocalizations.of(context).copied}'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    HistoryProvider provider,
    int index,
  ) {
    final result = provider.history[index];
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).deleteRecord),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).deleteConfirm),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(51),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    result.address,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () {
                  provider.removeFromHistory(index);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context).deleteConfirmMessage,
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: Text(AppLocalizations.of(context).delete),
              ),
            ],
          ),
    );
  }

  void _showClearDialog(BuildContext context, HistoryProvider provider) {
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
                  provider.clearHistory();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context).clearHistoryConfirm,
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 2),
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
