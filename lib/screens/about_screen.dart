import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';

class AboutScreen extends StatefulWidget {
  final bool showAppBar;

  const AboutScreen({super.key, this.showAppBar = true});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
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
    return SafeArea(
      child: Scaffold(
        appBar:
            widget.showAppBar
                ? AppBar(
                  title: Text(AppLocalizations.of(context).about),
                  centerTitle: true,
                  actions: [
                    // Consumer<LocaleProvider>(
                    //   builder: (context, localeProvider, child) {
                    //     return PopupMenuButton<Locale>(
                    //       icon: const Icon(Icons.language),
                    //       tooltip: AppLocalizations.of(context).language,
                    //       onSelected: (Locale locale) {
                    //         localeProvider.setLocale(locale);
                    //       },
                    //       itemBuilder: (BuildContext context) {
                    //         return AppLocalizations.supportedLocales.map((
                    //           Locale locale,
                    //         ) {
                    //           return PopupMenuItem<Locale>(
                    //             value: locale,
                    //             child: Row(
                    //               children: [
                    //                 if (localeProvider.locale == locale)
                    //                   const Icon(Icons.check, size: 20)
                    //                 else
                    //                   const SizedBox(width: 20),
                    //                 const SizedBox(width: 8),
                    //                 Text(localeProvider.getLanguageName(locale)),
                    //               ],
                    //             ),
                    //           );
                    //         }).toList();
                    //       },
                    //     );
                    //   },
                    // ),
                  ],
                )
                : null,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo e Nome
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.search,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bit Finder',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context).appDescription,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${AppLocalizations.of(context).version} $_version',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Sobre o Aplicativo
              _buildSection(
                context,
                icon: Icons.info_outline,
                title: AppLocalizations.of(context).aboutApp,
                content: AppLocalizations.of(context).aboutContent,
              ),

              const SizedBox(height: 24),

              // Bitcoin Puzzle Challenges
              _buildSection(
                context,
                icon: Icons.emoji_events,
                iconColor: Colors.amber,
                title: AppLocalizations.of(context).bitcoinPuzzleChallenges,
                content: AppLocalizations.of(context).challengesDescription,
              ),

              const SizedBox(height: 24),

              // Funcionalidades
              _buildSection(
                context,
                icon: Icons.speed,
                iconColor: Colors.green,
                title: AppLocalizations.of(context).features,
                content: '',
                children: [
                  _buildFeatureItem(AppLocalizations.of(context).featuresCpu),
                  _buildFeatureItem(
                    AppLocalizations.of(context).featuresNativeCrypto,
                  ),
                  _buildFeatureItem(
                    AppLocalizations.of(context).featuresSequentialRandom,
                  ),
                  _buildFeatureItem(
                    AppLocalizations.of(context).featuresHeatmap,
                  ),
                  _buildFeatureItem(
                    AppLocalizations.of(context).featuresAutoStop,
                  ),
                  _buildFeatureItem(
                    AppLocalizations.of(context).featuresPersistentHistory,
                  ),
                  _buildFeatureItem(
                    AppLocalizations.of(context).featuresWakelock,
                  ),
                  // _buildFeatureItem('Tema claro/escuro'),
                ],
              ),

              const SizedBox(height: 24),

              // Aviso Legal
              _buildSection(
                context,
                icon: Icons.warning,
                iconColor: Colors.red,
                title: AppLocalizations.of(context).legalNotice,
                content: '',
                children: [
                  Text(
                    '⚠️ ${AppLocalizations.of(context).legalNoticeImportant}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).legalNoticeContent,
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Segurança e Privacidade
              _buildSection(
                context,
                icon: Icons.security,
                iconColor: Colors.blue,
                title: AppLocalizations.of(context).securityAndPrivacy,
                content: '',
                children: [
                  _buildFeatureItem(
                    AppLocalizations.of(context).securityAndPrivacyContent1,
                  ),
                  _buildFeatureItem(
                    AppLocalizations.of(context).securityAndPrivacyContent2,
                  ),
                  _buildFeatureItem(
                    AppLocalizations.of(context).securityAndPrivacyContent3,
                  ),
                  _buildFeatureItem(
                    AppLocalizations.of(context).securityAndPrivacyContent4,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Créditos
              _buildSection(
                context,
                icon: Icons.code,
                title: AppLocalizations.of(context).credits,
                content: AppLocalizations.of(context).inspired,
              ),

              const SizedBox(height: 16),

              // Licença
              Center(
                child: Text(
                  '© 2025 Bit Finder\n${AppLocalizations.of(context).educationalPurpose}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Política de Privacidade
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(
                      'https://mantovani.net.br/pages/privacidade.html',
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  icon: const Icon(Icons.privacy_tip, size: 16),
                  label: Text(
                    AppLocalizations.of(context).privacyPolicy,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    Color? iconColor,
    required String title,
    required String content,
    List<Widget>? children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (content.isNotEmpty)
          Text(content, style: const TextStyle(height: 1.6)),
        if (children != null) ...children,
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}
