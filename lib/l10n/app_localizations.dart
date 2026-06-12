import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('pt', 'BR'), // Português (Brasil)
    Locale('en', 'US'), // English (US)
    Locale('es', 'ES'), // Español (España)
  ];

  // General
  String get appName => _localizedValues[locale.languageCode]!['app_name']!;
  String get appDescription =>
      _localizedValues[locale.languageCode]!['app_description']!;
  String get ok => _localizedValues[locale.languageCode]!['ok']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get confirm => _localizedValues[locale.languageCode]!['confirm']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get copy => _localizedValues[locale.languageCode]!['copy']!;
  String get copied => _localizedValues[locale.languageCode]!['copied']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;

  // Menu
  String get menuHome => _localizedValues[locale.languageCode]!['menu_home']!;
  String get menuHistory =>
      _localizedValues[locale.languageCode]!['menu_history']!;
  String get menuPerformance =>
      _localizedValues[locale.languageCode]!['menu_performance']!;
  String get menuAbout => _localizedValues[locale.languageCode]!['menu_about']!;

  // Key Finder Screen
  String get targetAddress =>
      _localizedValues[locale.languageCode]!['target_address']!;
  String get addTargetHint =>
      _localizedValues[locale.languageCode]!['add_target_hint']!;
  String get addTargetWarning =>
      _localizedValues[locale.languageCode]!['add_target_warning']!;
  String get keyspace => _localizedValues[locale.languageCode]!['keyspace']!;
  String get keyspaceHint =>
      _localizedValues[locale.languageCode]!['keyspace_hint']!;
  String get stride => _localizedValues[locale.languageCode]!['stride']!;
  String get strideHint =>
      _localizedValues[locale.languageCode]!['stride_hint']!;
  String get compression =>
      _localizedValues[locale.languageCode]!['compression']!;
  String get compressed =>
      _localizedValues[locale.languageCode]!['compressed']!;
  String get uncompressed =>
      _localizedValues[locale.languageCode]!['uncompressed']!;
  String get both => _localizedValues[locale.languageCode]!['both']!;
  String get startSearch =>
      _localizedValues[locale.languageCode]!['start_search']!;
  String get stop => _localizedValues[locale.languageCode]!['stop']!;
  String get challenges =>
      _localizedValues[locale.languageCode]!['challenges']!;
  String get status => _localizedValues[locale.languageCode]!['status']!;
  String statusChallenge(int id) =>
      _localizedValues[locale.languageCode]!['status_challenge']!.replaceAll(
        '{id}',
        id.toString(),
      );
  String get challengesSolved =>
      _localizedValues[locale.languageCode]!['challenges_solved']!;
  String get forTesting =>
      _localizedValues[locale.languageCode]!['for_testing']!;

  // Status fields
  String get speed => _localizedValues[locale.languageCode]!['speed']!;
  String get keysChecked =>
      _localizedValues[locale.languageCode]!['keys_checked']!;
  String get progress => _localizedValues[locale.languageCode]!['progress']!;
  String get timeElapsed =>
      _localizedValues[locale.languageCode]!['time_elapsed']!;
  String get currentKey =>
      _localizedValues[locale.languageCode]!['current_key']!;
  String get searchMode =>
      _localizedValues[locale.languageCode]!['search_mode']!;
  String get searchModeHint =>
      _localizedValues[locale.languageCode]!['search_mode_hint']!;
  String get sequential =>
      _localizedValues[locale.languageCode]!['sequential']!;
  String get random => _localizedValues[locale.languageCode]!['random']!;

  // Challenges
  String get selectChallenge =>
      _localizedValues[locale.languageCode]!['select_challenge']!;
  String get solved => _localizedValues[locale.languageCode]!['solved']!;
  String get unsolved => _localizedValues[locale.languageCode]!['unsolved']!;
  String get challengesUnsolved =>
      _localizedValues[locale.languageCode]!['challenges_unsolved']!;
  String get bitcoinValue =>
      _localizedValues[locale.languageCode]!['bitcoin_value']!;
  String get challengesDescription =>
      _localizedValues[locale.languageCode]!['challenge_description']!;
  String challengeLoaded(String name) =>
      _localizedValues[locale.languageCode]!['challenge_loaded']!.replaceAll(
        '{name}',
        name,
      );
  String get errorLoadingChallenges =>
      _localizedValues[locale.languageCode]!['error_loading_challenges']!;
  String get loadedAndConfigured =>
      _localizedValues[locale.languageCode]!['loaded_and_configured']!;
  String get device => _localizedValues[locale.languageCode]!['device']!;
  String get targets => _localizedValues[locale.languageCode]!['targets']!;
  String get totalKeys => _localizedValues[locale.languageCode]!['total_keys']!;
  String get elapsed => _localizedValues[locale.languageCode]!['elapsed']!;
  String get found => _localizedValues[locale.languageCode]!['found']!;
  String get yes => _localizedValues[locale.languageCode]!['yes']!;
  String get no => _localizedValues[locale.languageCode]!['no']!;
  String get publicKeyX =>
      _localizedValues[locale.languageCode]!['public_key_x']!;
  String get publicKeyY =>
      _localizedValues[locale.languageCode]!['public_key_y']!;

  // Key Found
  String get keyFound => _localizedValues[locale.languageCode]!['key_found']!;
  String get congratulations =>
      _localizedValues[locale.languageCode]!['congratulations']!;
  String get foundKeyMessage =>
      _localizedValues[locale.languageCode]!['found_key_message']!;
  String get privateKey =>
      _localizedValues[locale.languageCode]!['private_key']!;
  String get key => _localizedValues[locale.languageCode]!['key']!;
  String get address => _localizedValues[locale.languageCode]!['address']!;
  String get copyKeyAddress =>
      _localizedValues[locale.languageCode]!['copy_key_address']!;
  String get copyAll => _localizedValues[locale.languageCode]!['copy_all']!;
  String get keyspaceOptional =>
      _localizedValues[locale.languageCode]!['keyspace_optional']!;

  // History
  String get history => _localizedValues[locale.languageCode]!['history']!;
  String get noKeysFound =>
      _localizedValues[locale.languageCode]!['no_keys_found']!;
  String get deleteRecord =>
      _localizedValues[locale.languageCode]!['delete_record']!;
  String get deleteConfirm =>
      _localizedValues[locale.languageCode]!['delete_confirm']!;
  String get deleteConfirmMessage =>
      _localizedValues[locale.languageCode]!['delete_confirm_message']!;
  String get clearHistory =>
      _localizedValues[locale.languageCode]!['clear_history']!;
  String get clearHistoryConfirm =>
      _localizedValues[locale.languageCode]!['clear_history_confirm']!;
  String get bitcoinAddress =>
      _localizedValues[locale.languageCode]!['bitcoin_address']!;
  String get privateKeys =>
      _localizedValues[locale.languageCode]!['private_keys']!;
  String get challenge => _localizedValues[locale.languageCode]!['challenge']!;
  String get resultsSavedToHistory =>
      _localizedValues[locale.languageCode]!['results_saved_to_history']!;
  String get keyspaceHelper =>
      _localizedValues[locale.languageCode]!['keyspace_helper']!;

  // Performance
  String get performance =>
      _localizedValues[locale.languageCode]!['performance']!;
  String get cpuThreads =>
      _localizedValues[locale.languageCode]!['cpu_threads']!;
  String get threadsDescription =>
      _localizedValues[locale.languageCode]!['threads_description']!;
  String get cryptoEngine =>
      _localizedValues[locale.languageCode]!['crypto_engine']!;
  String get nativeEngine =>
      _localizedValues[locale.languageCode]!['native_engine']!;
  String get dartEngine =>
      _localizedValues[locale.languageCode]!['dart_engine']!;
  String get threads => _localizedValues[locale.languageCode]!['threads']!;
  String get available => _localizedValues[locale.languageCode]!['available']!;
  String get results => _localizedValues[locale.languageCode]!['results']!;
  String get clear => _localizedValues[locale.languageCode]!['clear']!;

  // Features
  String get features => _localizedValues[locale.languageCode]!['features']!;
  String get featuresCpu =>
      _localizedValues[locale.languageCode]!['features_cpu']!;
  String get featuresNativeCrypto =>
      _localizedValues[locale.languageCode]!['features_native_crypto']!;
  String get featuresSequentialRandom =>
      _localizedValues[locale.languageCode]!['features_sequential_random']!;
  String get featuresHeatmap =>
      _localizedValues[locale.languageCode]!['features_heatmap']!;
  String get featuresAutoStop =>
      _localizedValues[locale.languageCode]!['features_auto_stop']!;
  String get featuresPersistentHistory =>
      _localizedValues[locale.languageCode]!['features_persistent_history']!;
  String get featuresWakelock =>
      _localizedValues[locale.languageCode]!['features_wakelock']!;
  // Legal Notice
  String get legalNotice =>
      _localizedValues[locale.languageCode]!['legal_notice']!;
  String get legalNoticeImportant =>
      _localizedValues[locale.languageCode]!['legal_notice_important']!;
  String get legalNoticeContent =>
      _localizedValues[locale.languageCode]!['legal_notice_content']!;
  String get securityAndPrivacy =>
      _localizedValues[locale.languageCode]!['security_and_privacy']!;
  String get securityAndPrivacyContent1 =>
      _localizedValues[locale.languageCode]!['security_and_privacy_content_1']!;
  String get securityAndPrivacyContent2 =>
      _localizedValues[locale.languageCode]!['security_and_privacy_content_2']!;
  String get securityAndPrivacyContent3 =>
      _localizedValues[locale.languageCode]!['security_and_privacy_content_3']!;
  String get securityAndPrivacyContent4 =>
      _localizedValues[locale.languageCode]!['security_and_privacy_content_4']!;

  // About
  String get about => _localizedValues[locale.languageCode]!['about']!;
  String get aboutApp => _localizedValues[locale.languageCode]!['about_app']!;
  String get version => _localizedValues[locale.languageCode]!['version']!;
  String get bitcoinPuzzleChallenges =>
      _localizedValues[locale.languageCode]!['bitcoin_puzzle_challenges']!;
  String get aboutContent =>
      _localizedValues[locale.languageCode]!['about_content']!;
  String get continueButton =>
      _localizedValues[locale.languageCode]!['continue_button']!;
  String get privacyPolicy =>
      _localizedValues[locale.languageCode]!['privacy_policy']!;
  String get credits => _localizedValues[locale.languageCode]!['credits']!;
  String get inspired => _localizedValues[locale.languageCode]!['inspired']!;
  String get educationalPurpose =>
      _localizedValues[locale.languageCode]!['educational_purpose']!;
  String get stopSearchKeyFound =>
      _localizedValues[locale.languageCode]!['stop_search_key_found']!;
  String get storeKeySafely =>
      _localizedValues[locale.languageCode]!['store_key_safely']!;
  String get performanceSettings =>
      _localizedValues[locale.languageCode]!['threads_description']!;
  String get coresAvailable =>
      _localizedValues[locale.languageCode]!['cores_available']!;
  String get threadsUsingMaxWarning =>
      _localizedValues[locale.languageCode]!['threads_using_max_warning']!;
  String get threadsSuggested =>
      _localizedValues[locale.languageCode]!['threads_suggested']!;
  String get appearance =>
      _localizedValues[locale.languageCode]!['appearance']!;
  String get darkMode => _localizedValues[locale.languageCode]!['dark_mode']!;
  String get darkModeEnabled =>
      _localizedValues[locale.languageCode]!['dark_mode_enabled']!;
  String get lightModeEnabled =>
      _localizedValues[locale.languageCode]!['light_mode_enabled']!;
  String get stored => _localizedValues[locale.languageCode]!['stored']!;
  String get replica => _localizedValues[locale.languageCode]!['replica']!;
  String get performanceWarningTitle =>
      _localizedValues[locale.languageCode]!['performance_warning_title']!;
  String get performanceWarningMessage =>
      _localizedValues[locale.languageCode]!['performance_warning_message']!;
  String get recommended =>
      _localizedValues[locale.languageCode]!['recommended']!;
  String get use => _localizedValues[locale.languageCode]!['use']!;
  String get takeRisk => _localizedValues[locale.languageCode]!['take_risk']!;
  String get historyClearedSuccessfully =>
      _localizedValues[locale.languageCode]!['history_cleared_successfully']!;
  // String get legalWarningTitle =>
  //     _localizedValues[locale.languageCode]!['legal_notice']!;
  // String get legalWarningMessage =>
  //     _localizedValues[locale.languageCode]!['legal_notice_content']!;

  static const Map<String, Map<String, String>> _localizedValues = {
    'pt': {
      'history_cleared_successfully': 'Histórico limpo com sucesso',
      'take_risk': 'Arriscar',
      'recommended': 'Recomendado',
      'use': 'Usar',
      'performance_warning_title': 'Aviso de Performance',
      'performance_warning_message':
          'Usar todas as threads pode travar ou deixar o aparelho lento durante a busca.',
      // 'legal_notice': 'Aviso Legal',
      // 'legal_notice_content':
      //     '• Este aplicativo é SOMENTE para fins educacionais e de pesquisa.\n\n'
      //     '• NÃO tente encontrar chaves privadas de endereços que você não possui. '
      //     'Isso pode ser ILEGAL em sua jurisdição.\n\n'
      //     '• A probabilidade de encontrar uma chave privada válida de um endereço '
      //     'com saldo é astronomicamente baixa (1 em 2^256).\n\n'
      //     '• O uso deste aplicativo para acessar fundos de terceiros sem autorização '
      //     'constitui CRIME em praticamente todas as jurisdições.\n\n'
      //     '• Os desenvolvedores NÃO se responsabilizam por qualquer uso indevido '
      //     'desta ferramenta.\n\n'
      //     '• Use apenas os desafios resolvidos fornecidos para testes.',
      'replica': 'Réplica do BitCrack KeyFinder',
      'stored': 'armazenado',
      'dark_mode': 'Modo Escuro',
      'dark_mode_enabled': 'Tema escuro ativado',
      'light_mode_enabled': 'Tema claro ativado',
      'appearance': 'Aparência',
      'threads_using_max_warning':
          'Usando todas as threads pode travar o aparelho. Recomendado:',
      'threads_suggested':
          'Mais threads = busca mais rápida, mas maior consumo de bateria. Recomendado:',
      'cores_available': 'núcleos disponíveis',
      // 'threads_description': 'Número de threads paralelos para busca',
      'store_key_safely': 'Guarde esta chave em local seguro!',
      'stop_search_key_found':
          'A busca foi interrompida porque uma chave correspondente foi encontrada!',
      'yes': 'Sim',
      'no': 'Não',
      'public_key_x': 'Chave Pública X',
      'public_key_y': 'Chave Pública Y',
      'app_name': 'Bit Finder',
      'ok': 'OK',
      'cancel': 'Cancelar',
      'confirm': 'Confirmar',
      'delete': 'Excluir',
      'copy': 'Copiar',
      'copied': 'Copiado!',
      'settings': 'Configurações',
      'language': 'Idioma',
      'app_description': 'Buscador de chaves Bitcoin',
      'credits': 'Créditos',
      'inspired': 'Inspirado no BitCrack por brichard19.',
      'educational_purpose': 'Somente para fins educacionais',
      'challenge': 'Desafio',
      'challenges_solved': 'Desafios Resolvidos',
      'for_testing': 'Para Teste',
      'challenges_unsolved': 'Desafios Não Resolvidos',
      'loaded_and_configured':
          'carregado! Address, Keyspace e Compression configurados.',
      'keyspace_optional': 'Keyspace (opcional)',
      'keyspace_helper': 'Deixe vazio para o range completo',
      'keyspace_hint': 'INICIO:FIM ou INICIO:+CONTA (em hex)',
      'search_mode_hint': 'Sequencial: em ordem, Aleatório: chaves aleatórias',
      'available': 'disponíveis',
      'device': 'Dispositivo',
      'targets': 'Alvos',
      'total_keys': 'Total de Chaves',
      'elapsed': 'Tempo Decorrido',
      'results': 'Resultados',
      'clear': 'Limpar',
      'found': 'Encontrado',

      'menu_home': 'Início',
      'menu_history': 'Histórico',
      'menu_performance': 'Performance',
      'menu_about': 'Sobre',
      'about_app': 'Sobre o Aplicativo',
      'key': 'Chave',
      'about_content':
          'Bit Finder é uma réplica do software BitCrack KeyFinder, '
          'desenvolvido para fins educacionais. O aplicativo permite buscar '
          'chaves privadas de Bitcoin através de diferentes métodos de varredura, '
          'incluindo busca sequencial e aleatória.',
      'bitcoin_puzzle_challenges': 'Desafios Bitcoin',
      'error_loading_challenges': 'Erro ao carregar desafios',
      'challenge_description':
          'O aplicativo inclui 76 desafios do famoso "Bitcoin Puzzle Transaction" '
          'criado em 2015. Estes puzzles contêm endereços Bitcoin com valores reais, '
          'mas com chaves privadas em ranges específicos. Os desafios resolvidos são '
          'fornecidos apenas para testes e validação do aplicativo. '
          'Ao todo são 160 desafios criados com o intuito de provar a segurança'
          'do Bitcoin. A cada desafio encontrado, a dificuldade do próximo é dobrada. '
          'Aquele que encontrar a chave privada correspondente, poderá resgatar o valor'
          ' associado. Mais informações em privatekeys.pw',

      'target_address': 'Endereço Alvo',
      'add_target_hint': '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
      'add_target_warning':
          'Adicione pelo menos um endereço alvo para começar a busca',
      'keyspace': 'Keyspace',
      'stride': 'Stride',
      'stride_hint': '1',
      'compression': 'Compressão',
      'compressed': 'Comprimida',
      'uncompressed': 'Descomprimida',
      'both': 'Ambas',
      'start_search': 'Start Search',
      'stop': 'Stop',
      'challenges': 'Desafios',
      'status': 'Status',
      'status_challenge': 'Status - Desafio #{id}',
      // Status fields
      'results_saved_to_history': 'Os resultados foram salvos no histórico',

      'features': 'Funcionalidades',
      'features_cpu':
          'Multi-threading: busca paralela em múltiplos núcleos da CPU',
      'features_native_crypto':
          'Crypto nativa C++: até 50x mais rápido que Dart puro',
      'features_sequential_random': 'Busca sequencial e aleatória no keyspace',
      'features_heatmap': 'Mapa de progresso visual (heatmap 200x200)',
      'features_auto_stop': 'Auto-stop quando encontrar chave',
      'features_persistent_history':
          'Histórico persistente de chaves encontradas',
      'features_wakelock': 'Wakelock: mantém tela ativa durante busca',
      'legal_notice': 'Aviso Legal',
      'legal_notice_important': 'IMPORTANTE',
      'legal_notice_content':
          '• Este aplicativo é SOMENTE para fins educacionais e de pesquisa.\n\n'
          '• NÃO tente encontrar chaves privadas de endereços que você não possui. '
          'Isso pode ser ILEGAL em sua jurisdição.\n\n'
          '• A probabilidade de encontrar uma chave privada válida de um endereço '
          'com saldo é astronomicamente baixa (1 em 2^256).\n\n'
          '• O uso deste aplicativo para acessar fundos de terceiros sem autorização '
          'constitui CRIME em praticamente todas as jurisdições.\n\n'
          '• Os desenvolvedores NÃO se responsabilizam por qualquer uso indevido '
          'desta ferramenta.\n\n'
          '• Use apenas os desafios resolvidos fornecidos para testes.',
      'security_and_privacy': 'Segurança e Privacidade',

      'security_and_privacy_content_1':
          'Todas as operações são realizadas localmente no dispositivo',

      'security_and_privacy_content_2':
          'Nenhum dado é enviado para servidores externos',
      'security_and_privacy_content_3':
          'Histórico armazenado apenas localmente',
      'security_and_privacy_content_4': 'Código aberto e auditável',

      'speed': 'Velocidade',
      'keys_checked': 'Chaves verificadas',
      'progress': 'Progresso',
      'time_elapsed': 'Tempo decorrido',
      'current_key': 'Chave atual',
      'search_mode': 'Modo de busca',
      'sequential': 'Sequencial',
      'random': 'Aleatório',

      'select_challenge': 'Selecione um desafio',
      'solved': 'Resolvido',
      'unsolved': 'Não resolvido',
      'bitcoin_value': 'Bitcoin',
      'challenge_loaded':
          '{name} carregado! Address, Keyspace e Compression configurados.',

      'key_found': 'Chave Encontrada!',
      'congratulations': 'Parabéns!',
      'found_key_message': 'Você encontrou uma chave privada correspondente!',
      'private_key': 'Chave Privada',
      'address': 'Endereço',
      'copy_key_address': 'Copiar Chave+Endereço',
      'copy_all': 'Copiar Tudo',

      'history': 'Histórico',
      'no_keys_found': 'Nenhuma chave encontrada ainda',
      'delete_record': 'Excluir registro',
      'delete_confirm': 'Excluir',
      'delete_confirm_message': 'Deseja realmente excluir este registro?',
      'clear_history': 'Limpar Histórico',
      'clear_history_confirm': 'Deseja realmente limpar todo o histórico?',
      'bitcoin_address': 'Endereço Bitcoin',
      'private_keys': 'Chaves Privadas',

      'performance': 'Performance',
      'cpu_threads': 'Threads de CPU',
      'threads_description': 'Número de threads paralelos para busca',
      'threads': 'thread',
      'crypto_engine': 'Motor Criptográfico',
      'native_engine': 'Nativo (C++)',
      'dart_engine': 'Dart (Fallback)',

      'about': 'Sobre',
      'version': 'Versão',
      'continue_button': 'Continuar',
      'privacy_policy': 'Política de Privacidade',
    },
    'en': {
      'history_cleared_successfully': 'History cleared successfully',
      'take_risk': 'Take Risk',
      'recommended': 'Recommended',
      'use': 'Use',
      'performance_warning_title': 'Performance Warning',
      'performance_warning_message':
          'Using all threads may crash or slow down the device during the search.',
      // 'legal_notice': 'Legal Notice',
      // 'legal_notice_content':
      //     '• This app is for EDUCATIONAL and RESEARCH purposes ONLY.\n\n'
      //     '• DO NOT attempt to find private keys of addresses you do not own. '
      //     'This may be ILLEGAL in your jurisdiction.\n\n'
      //     '• The probability of finding a valid private key for an address '
      //     'with a balance is astronomically low (1 in 2^256).\n\n'
      //     '• Using this app to access third-party funds without authorization '
      //     'constitutes a CRIME in virtually all jurisdictions.\n\n'
      //     '• The developers are NOT responsible for any misuse of this tool.\n\n'
      //     '• Use only the provided solved challenges for testing purposes.',
      'replica': 'Replica of BitCrack KeyFinder',
      'stored': 'stored',
      'dark_mode': 'Dark Mode',
      'dark_mode_enabled': 'Dark mode enabled',
      'light_mode_enabled': 'Light mode enabled',
      'appearance': 'Appearance',
      'threads_using_max_warning':
          'Using all threads may crash the device. Recommended:',
      'threads_suggested':
          'More threads = faster search, but higher battery consumption. Recommended:',
      'cores_available': 'cores available',
      // 'threads_description': 'Number of parallel threads for search',
      'stop_search_key_found':
          'The search was stopped because a matching key was found!',
      'yes': 'Yes',
      'no': 'No',
      'public_key_x': 'Public Key X',
      'public_key_y': 'Public Key Y',
      'app_name': 'Bit Finder',
      'ok': 'OK',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'delete': 'Delete',
      'copy': 'Copy',
      'copied': 'Copied!',
      'settings': 'Settings',
      'language': 'Language',
      'key': 'Key',
      'credits': 'Credits',
      'inspired': 'Inspired by BitCrack by brichard19.',
      'educational_purpose': 'For educational purposes only',
      'app_description': 'Bitcoin Key Finder',
      'challenge': 'Challenge',
      'results_saved_to_history': 'Results saved to history',
      'error_loading_challenges': 'Error loading challenges',
      'challenges_solved': 'Challenges Solved',
      'for_testing': 'For Testing',
      'challenges_unsolved': 'Challenges Unsolved',
      'loaded_and_configured':
          'loaded! Address, Keyspace and Compression configured.',
      'keyspace_optional': 'Keyspace (optional)',
      'keyspace_hint': 'START:END or START:+COUNT (in hex)',
      'keyspace_helper': 'Leave empty for full range',
      'search_mode_hint': 'Sequential: in order, Random: random keys',
      'available': 'available',
      'device': 'Device',
      'targets': 'Targets',
      'total_keys': 'Total Keys',
      'elapsed': 'Elapsed',
      'results': 'Results',
      'clear': 'Clear',
      'found': 'Found',

      'menu_home': 'Home',
      'menu_history': 'History',
      'menu_performance': 'Performance',
      'menu_about': 'About',
      'about_app': 'About the App',
      'about_content':
          'Bit Finder is a replica of the BitCrack KeyFinder software, '
          'developed for educational purposes. The app allows searching '
          'for Bitcoin private keys through different scanning methods, '
          'including sequential and random search.',
      'bitcoin_puzzle_challenges': 'Bitcoin Puzzle Challenges',
      'challenge_description':
          'The app includes 76 challenges from the famous "Bitcoin Puzzle Transaction"'
          'created in 2015. These puzzles contain Bitcoin addresses with real values,'
          'but with private keys in specific ranges. The solved challenges are'
          'provided only for testing and validation of the app.'
          'In total, there are 160 challenges created with the intention of proving the security'
          'of Bitcoin. With each challenge solved, the difficulty of the next is doubled.'
          'Whoever finds the corresponding private key can redeem the associated value.'
          'More information at privatekeys.pw',
      'legal_notice': 'Legal Notice',
      'legal_notice_important': 'IMPORTANT',
      'legal_notice_content':
          '• This app is for EDUCATIONAL and RESEARCH purposes ONLY.\n\n'
          '• DO NOT attempt to find private keys of addresses you do not own. '
          'This may be ILLEGAL in your jurisdiction.\n\n'
          '• The probability of finding a valid private key for an address '
          'with a balance is astronomically low (1 in 2^256).\n\n'
          '• Using this app to access third-party funds without authorization '
          'constitutes a CRIME in virtually all jurisdictions.\n\n'
          '• The developers are NOT responsible for any misuse ',
      'security_and_privacy': 'Security and Privacy',
      'security_and_privacy_content_1':
          'All operations are performed locally on the device',
      'security_and_privacy_content_2': 'No data is sent to external servers',
      'security_and_privacy_content_3': 'History is stored locally only',
      'security_and_privacy_content_4': 'Open source and auditable',

      'target_address': 'Target Address',
      'add_target_hint': '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
      'add_target_warning':
          'Add at least one target address to start searching',
      'keyspace': 'Keyspace',
      'stride': 'Stride',
      'stride_hint': '1',
      'compression': 'Compression',
      'compressed': 'Compressed',
      'uncompressed': 'Uncompressed',
      'both': 'Both',
      'start_search': 'Start Search',
      'stop': 'Stop',
      'challenges': 'Challenges',
      'status': 'Status',
      'status_challenge': 'Status - Challenge #{id}',

      'features': 'Features',
      'features_cpu': 'Multi-threading: parallel search on multiple CPU cores',
      'features_native_crypto':
          'Native C++ crypto: up to 50x faster than pure Dart',
      'features_sequential_random': 'Sequential and random search in keyspace',
      'features_heatmap': 'Visual progress map (heatmap 200x200)',
      'features_auto_stop': 'Auto-stop when key is found',
      'features_persistent_history': 'Persistent history of found keys',
      'features_wakelock': 'Wakelock: keeps screen on during search',

      'speed': 'Speed',
      'keys_checked': 'Keys checked',
      'progress': 'Progress',
      'time_elapsed': 'Time elapsed',
      'current_key': 'Current key',
      'search_mode': 'Search mode',
      'sequential': 'Sequential',
      'random': 'Random',

      'select_challenge': 'Select a challenge',
      'solved': 'Solved',
      'unsolved': 'Unsolved',
      'bitcoin_value': 'Bitcoin',
      'challenge_loaded':
          '{name} loaded! Address, Keyspace and Compression configured.',

      'key_found': 'Key Found!',
      'congratulations': 'Congratulations!',
      'found_key_message': 'You found a matching private key!',
      'private_key': 'Private Key',
      'address': 'Address',
      'copy_key_address': 'Copy Key+Address',
      'copy_all': 'Copy All',

      'history': 'History',
      'no_keys_found': 'No keys found yet',
      'delete_record': 'Delete record',
      'delete_confirm': 'Delete',
      'delete_confirm_message': 'Do you really want to delete this record?',
      'clear_history': 'Clear History',
      'clear_history_confirm': 'Do you really want to clear all history?',
      'bitcoin_address': 'Bitcoin Address',
      'private_keys': 'Private Keys',

      'performance': 'Performance',
      'cpu_threads': 'CPU Threads',
      'threads_description': 'Number of parallel threads for search',
      'threads': 'thread',
      'crypto_engine': 'Cryptographic Engine',
      'native_engine': 'Native (C++)',
      'dart_engine': 'Dart (Fallback)',

      'about': 'About',
      'version': 'Version',
      'continue_button': 'Continue',
      'privacy_policy': 'Privacy Policy',
    },
    'es': {
      'history_cleared_successfully': 'Historial borrado con éxito',
      'take_risk': 'Tomar Riesgo',
      'recommended': 'Recomendado',
      'use': 'Usar',
      'performance_warning_title': 'Advertencia de Rendimiento',
      'performance_warning_message':
          'Usar todos los hilos puede bloquear o ralentizar el dispositivo durante la búsqueda.',
      'replica': 'Réplica de BitCrack KeyFinder',
      'stored': 'almacenado',
      'dark_mode': 'Modo Oscuro',
      'dark_mode_enabled': 'Modo oscuro activado',
      'light_mode_enabled': 'Modo claro activado',
      'appearance': 'Apariencia',
      'threads_using_max_warning':
          'Usar todos los hilos puede bloquear el dispositivo. Recomendado:',
      'threads_suggested':
          'Más hilos = búsqueda más rápida, pero mayor consumo de batería. Recomendado:',
      'cores_available': 'núcleos disponibles',
      // 'threads_description': 'Número de hilos paralelos para la búsqueda',
      'stop_search_key_found':
          '¡La búsqueda se detuvo porque se encontró una clave coincidente!',
      'yes': 'Sí',
      'no': 'No',
      'public_key_x': 'Clave Pública X',
      'public_key_y': 'Clave Pública Y',
      'app_name': 'Bit Finder',
      'ok': 'OK',
      'cancel': 'Cancelar',
      'confirm': 'Confirmar',
      'delete': 'Eliminar',
      'copy': 'Copiar',
      'copied': '¡Copiado!',
      'settings': 'Configuración',
      'credits': 'Créditos',
      'inspired': 'Inspirado en BitCrack por brichard19.',
      'educational_purpose': 'Solo para fines educativos',
      'language': 'Idioma',
      'key': 'Clave',
      'app_description': 'Buscador de claves Bitcoin',
      'results_saved_to_history': 'Resultados guardados en el historial',
      'error_loading_challenges': 'Error al cargar desafíos',
      'challenges_solved': 'Desafíos Resueltos',
      'for_testing': 'Para Pruebas',
      'challenges_unsolved': 'Desafíos No Resueltos',
      'loaded_and_configured':
          '¡cargado! Dirección, Espacio de claves y Compresión configurados.',
      'keyspace_optional': 'Espacio de claves (opcional)',
      'keyspace_helper': 'Dejar vacío para rango completo',
      'keyspace_hint': 'INICIO:FIN o INICIO:+CUENTA (en hex)',
      'search_mode_hint': 'Secuencial: en orden, Aleatorio: claves aleatorias',
      'available': 'disponibles',
      'device': 'Dispositivo',
      'targets': 'Objetivos',
      'total_keys': 'Total de Claves',
      'elapsed': 'Tiempo Transcurrido',
      'results': 'Resultados',
      'clear': 'Limpiar',
      'found': 'Encontrado',

      'about_content':
          'Bit Finder es una réplica del software BitCrack KeyFinder, '
          'desarrollado con fines educativos. La aplicación permite buscar '
          'claves privadas de Bitcoin mediante diferentes métodos de escaneo, '
          'incluyendo búsqueda secuencial y aleatoria.',
      'bitcoin_puzzle_challenges': 'Desafíos Bitcoin',
      'challenge_description':
          'La aplicación incluye 76 desafíos del famoso "Bitcoin Puzzle Transaction" '
          'creado en 2015. Estos puzzles contienen direcciones Bitcoin con valores reales, '
          'pero con claves privadas en rangos específicos. Los desafíos resueltos se '
          'proporcionan solo para pruebas y validación de la aplicación.'
          'En total, hay 160 desafíos creados con la intención de demostrar la seguridad'
          'de Bitcoin. Con cada desafío resuelto, la dificultad del siguiente se duplica. '
          'Quien encuentre la clave privada correspondiente podrá canjear el valor asociado.'
          'Más información en privatekeys.pw',
      'legal_notice': 'Aviso Legal',
      'legal_notice_important': 'IMPORTANTE',
      'legal_notice_content':
          '• Esta aplicación es SOLO para fines EDUCATIVOS y de INVESTIGACIÓN.\n\n'
          '• NO intente encontrar claves privadas de direcciones que no le pertenezcan. '
          'Esto puede ser ILEGAL en su jurisdicción.\n\n'
          '• La probabilidad de encontrar una clave privada válida para una dirección '
          'con saldo es astronómicamente baja (1 en 2^256).\n\n'
          '• Usar esta aplicación para acceder a fondos de terceros sin autorización '
          'constituye un DELITO en prácticamente todas las jurisdicciones.\n\n'
          '• Los desarrolladores NO son responsables por ningún uso indebido de la aplicación.',
      'security_and_privacy': 'Seguridad y Privacidad',
      'security_and_privacy_content_1':
          'Todas las operaciones se realizan localmente en el dispositivo',
      'security_and_privacy_content_2':
          'No se envían datos a servidores externos',
      'security_and_privacy_content_3':
          'El historial se almacena solo localmente',
      'security_and_privacy_content_4': 'Código abierto y auditable',

      'menu_home': 'Inicio',
      'menu_history': 'Historial',
      'menu_performance': 'Rendimiento',
      'menu_about': 'Acerca de',
      'about_app': 'Acerca del Aplicativo',

      'target_address': 'Dirección Objetivo',
      'add_target_hint': '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
      'add_target_warning':
          'Agregue al menos una dirección objetivo para comenzar la búsqueda',
      'keyspace': 'Espacio de claves',
      'stride': 'Stride',
      'stride_hint': '1',
      'compression': 'Compresión',
      'compressed': 'Comprimida',
      'uncompressed': 'Sin comprimir',
      'both': 'Ambas',
      'start_search': 'Iniciar Búsqueda',
      'stop': 'Detener',
      'challenges': 'Desafíos',
      'status': 'Estado',
      'status_challenge': 'Estado - Desafío #{id}',

      'features': 'Funcionalidades',
      'features_cpu':
          'Multihilo: búsqueda paralela en múltiples núcleos de CPU',
      'features_native_crypto':
          'Cripto nativa C++: hasta 50x más rápido que Dart puro',
      'features_sequential_random':
          'Búsqueda secuencial y aleatoria en el espacio de claves',
      'features_heatmap': 'Mapa de progreso visual (heatmap 200x200)',
      'features_auto_stop': 'Auto-detención cuando se encuentra una clave',
      'features_persistent_history':
          'Historial persistente de claves encontradas',
      'features_wakelock':
          'Wakelock: mantiene la pantalla activa durante la búsqueda',

      'speed': 'Velocidad',
      'keys_checked': 'Claves verificadas',
      'progress': 'Progreso',
      'time_elapsed': 'Tiempo transcurrido',
      'current_key': 'Clave actual',
      'search_mode': 'Modo de búsqueda',
      'sequential': 'Secuencial',
      'random': 'Aleatorio',

      'select_challenge': 'Seleccione un desafío',
      'solved': 'Resuelto',
      'unsolved': 'No resuelto',
      'bitcoin_value': 'Bitcoin',
      'challenge_loaded':
          '¡{name} cargado! Dirección, Espacio de claves y Compresión configurados.',

      'key_found': '¡Clave Encontrada!',
      'congratulations': '¡Felicitaciones!',
      'found_key_message': '¡Encontraste una clave privada coincidente!',
      'private_key': 'Clave Privada',
      'address': 'Dirección',
      'copy_key_address': 'Copiar Clave+Dirección',
      'copy_all': 'Copiar Todo',

      'history': 'Historial',
      'no_keys_found': 'Aún no se han encontrado claves',
      'delete_record': 'Eliminar registro',
      'delete_confirm': 'Eliminar',
      'delete_confirm_message': '¿Realmente desea eliminar este registro?',
      'clear_history': 'Limpiar Historial',
      'clear_history_confirm': '¿Realmente desea limpiar todo el historial?',
      'bitcoin_address': 'Dirección Bitcoin',
      'private_keys': 'Claves Privadas',
      'challenge': 'Desafío',

      'performance': 'Rendimiento',
      'cpu_threads': 'Hilos de CPU',
      'threads_description': 'Número de hilos paralelos para búsqueda',
      'threads': 'hilo',
      'crypto_engine': 'Motor Criptográfico',
      'native_engine': 'Nativo (C++)',
      'dart_engine': 'Dart (Fallback)',

      'about': 'Acerca de',
      'version': 'Versión',
      'continue_button': 'Continuar',
      'privacy_policy': 'Política de Privacidad',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['pt', 'en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
