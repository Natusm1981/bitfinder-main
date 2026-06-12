# Development Guide - BitFinder

## 🛠️ Setup de Desenvolvimento

### Pré-requisitos

- Flutter SDK 3.7.2+
- Dart SDK 3.0+
- IDE: VS Code ou Android Studio
- Git

### Instalação

```bash
# Clone o repositório
git clone <repository-url>
cd bitfinder

# Instale dependências
flutter pub get

# Verifique se está tudo OK
flutter doctor

# Execute em modo debug
flutter run
```

## 📁 Estrutura do Projeto

```
bitfinder/
├── lib/
│   ├── main.dart                           # Entry point
│   ├── models/
│   │   └── key_search_types.dart           # Data models
│   ├── utils/
│   │   └── address_util.dart               # Bitcoin utilities
│   ├── services/
│   │   └── key_finder.dart                 # Search engine
│   ├── providers/
│   │   └── key_finder_provider.dart        # State management
│   └── screens/
│       └── key_finder_screen.dart          # Main UI
├── test/                                   # Unit tests (TODO)
├── pubspec.yaml                            # Dependencies
├── README.md                               # Main readme
├── DOCUMENTATION.md                        # Full documentation
├── ANALYSIS.md                             # Technical analysis
└── QUICKSTART.md                           # Quick start guide
```

## 🔧 Componentes Principais

### 1. Models (`key_search_types.dart`)

Define todos os tipos de dados:

```dart
// Enum para modo de compressão
enum PointCompressionType { compressed, uncompressed, both }

// Target de busca
class KeySearchTarget {
  final String address;
  final List<int> hash160;
}

// Status da busca
class KeySearchStatus {
  final double speed;
  final BigInt total;
  final int totalTime;
  // ...
}

// Resultado encontrado
class KeySearchResult {
  final String address;
  final BigInt privateKey;
  // ...
}

// Configuração
class KeySearchConfig {
  BigInt startKey;
  BigInt endKey;
  // ...
}
```

### 2. Utils (`address_util.dart`)

Operações criptográficas:

```dart
class AddressUtil {
  // Verificar se endereço é válido
  static bool verifyAddress(String address);
  
  // Converter endereço para hash160
  static Uint8List addressToHash160(String address);
  
  // Gerar chave pública da privada
  static ECPoint publicKeyFromPrivate(BigInt privateKey);
  
  // Converter chave pública para hash160
  static Uint8List publicKeyToHash160(Uint8List publicKey);
  
  // Gerar endereço da chave privada
  static String privateKeyToAddress(BigInt privateKey, {bool compressed});
}

class KeyspaceUtil {
  // Parse string de keyspace
  static ({BigInt start, BigInt end}) parseKeyspace(String keyspace);
  
  // Formatação
  static String formatThousands(BigInt number);
  static String formatSeconds(int totalSeconds);
}
```

### 3. Service (`key_finder.dart`)

Engine de busca:

```dart
class KeyFinder {
  // Configuração
  final KeySearchConfig config;
  
  // Callbacks
  void Function(KeySearchResult)? onResult;
  void Function(KeySearchStatus)? onStatus;
  void Function(String)? onError;
  
  // Controle
  Future<void> start();
  void stop();
  
  // Worker (roda em isolate)
  static void _searchWorker(_SearchParams params) {
    // Loop de busca
    while (currentKey < endKey) {
      // Gera address
      // Compara com targets
      // Reporta se encontrou
      currentKey += stride;
    }
  }
}
```

### 4. Provider (`key_finder_provider.dart`)

State management:

```dart
class KeyFinderProvider extends ChangeNotifier {
  KeySearchConfig _config;
  KeyFinder? _keyFinder;
  KeySearchStatus? _currentStatus;
  List<KeySearchResult> _results;
  
  // Actions
  Future<void> startSearch();
  void stopSearch();
  void addTarget(String address);
  void removeTarget(int index);
  void setKeyspace(String keyspaceStr);
  void setCompressionMode(PointCompressionType mode);
  
  // Getters
  bool get isRunning;
  KeySearchStatus? get currentStatus;
  List<KeySearchResult> get results;
}
```

### 5. UI (`key_finder_screen.dart`)

Interface do usuário:

```dart
class KeyFinderScreen extends StatefulWidget {
  // Seções da UI
  Widget _buildTargetsSection(KeyFinderProvider provider);
  Widget _buildConfigurationSection(KeyFinderProvider provider);
  Widget _buildControlsSection(KeyFinderProvider provider);
  Widget _buildStatusSection(KeyFinderProvider provider);
  Widget _buildResultsSection(KeyFinderProvider provider);
}
```

## 🔄 Fluxo de Dados

```
┌─────────────────────────────────────────────────────────┐
│                     User Interface                       │
│  (KeyFinderScreen - screens/key_finder_screen.dart)     │
└─────────────────────┬───────────────────────────────────┘
                      │ User Actions
                      ↓
┌─────────────────────────────────────────────────────────┐
│                   State Management                       │
│ (KeyFinderProvider - providers/key_finder_provider.dart)│
└─────────────────────┬───────────────────────────────────┘
                      │ Commands
                      ↓
┌─────────────────────────────────────────────────────────┐
│                   Business Logic                         │
│      (KeyFinder - services/key_finder.dart)             │
└─────────────────────┬───────────────────────────────────┘
                      │ Spawn Isolate
                      ↓
┌─────────────────────────────────────────────────────────┐
│                 Background Worker                        │
│         (_searchWorker - runs in Isolate)               │
└─────────────────────┬───────────────────────────────────┘
                      │ Crypto Operations
                      ↓
┌─────────────────────────────────────────────────────────┐
│                 Crypto Utilities                         │
│       (AddressUtil - utils/address_util.dart)           │
└─────────────────────┬───────────────────────────────────┘
                      │ Results/Status
                      ↓
              Back to Provider → UI Update
```

## 🧪 Testing (TODO)

### Unit Tests

```dart
// test/utils/address_util_test.dart
void main() {
  group('AddressUtil', () {
    test('verifyAddress validates correct addresses', () {
      expect(AddressUtil.verifyAddress('1A1zP1...'), isTrue);
    });
    
    test('privateKeyToAddress generates correct address', () {
      final key = BigInt.from(1);
      final address = AddressUtil.privateKeyToAddress(key);
      expect(address, equals('expected_address'));
    });
  });
}

// test/services/key_finder_test.dart
void main() {
  group('KeyFinder', () {
    test('finds known key in range', () async {
      // Test search logic
    });
  });
}
```

### Widget Tests

```dart
// test/screens/key_finder_screen_test.dart
void main() {
  testWidgets('KeyFinderScreen displays correctly', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => KeyFinderProvider(),
        child: MaterialApp(home: KeyFinderScreen()),
      ),
    );
    
    expect(find.text('Target Addresses'), findsOneWidget);
  });
}
```

## 🐛 Debug

### VS Code Launch Configuration

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart"
    },
    {
      "name": "Flutter (Profile)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "flutterMode": "profile"
    }
  ]
}
```

### Debug Tips

```dart
// Adicionar prints de debug
debugPrint('Current key: ${currentKey.toRadixString(16)}');

// Usar breakpoints no VS Code
// Inspecionar variáveis
// Step through code

// Performance profiling
import 'dart:developer';
Timeline.startSync('keySearch');
// código
Timeline.finishSync();
```

## 🚀 Build para Produção

### Desktop (Windows)

```bash
flutter build windows --release
```

### Desktop (Linux)

```bash
flutter build linux --release
```

### Desktop (macOS)

```bash
flutter build macos --release
```

### Mobile (Android)

```bash
flutter build apk --release
flutter build appbundle --release
```

### Mobile (iOS)

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

## 📊 Performance Optimization

### Atual

```dart
// Sequencial em isolate
while (currentKey < endKey) {
  checkKey(currentKey);
  currentKey += stride;
}
```

### Possível: Batch Processing

```dart
// Processar múltiplas keys por vez
const batchSize = 1000;
for (int batch = 0; batch < batchSize; batch++) {
  final key = currentKey + batch;
  checkKey(key);
}
currentKey += batchSize;
```

### Possível: Multiple Isolates

```dart
// Dividir trabalho entre cores
final numCores = Platform.numberOfProcessors;
for (int i = 0; i < numCores; i++) {
  final share = divideKeyspace(config, i, numCores);
  Isolate.spawn(_searchWorker, share);
}
```

### Possível: FFI Native Code

```dart
// Usar código C++ via FFI
import 'dart:ffi';

typedef SearchFunction = Void Function(Pointer<Uint64>);
typedef SearchFunctionDart = void Function(Pointer<Uint64>);

final dylib = DynamicLibrary.open('libbitcrack.so');
final search = dylib.lookupFunction<SearchFunction, SearchFunctionDart>('search');
```

## 🔐 Security Considerations

1. **Nunca** armazene chaves privadas encontradas em plain text
2. **Sempre** use HTTPS para qualquer comunicação
3. **Nunca** envie chaves privadas pela rede
4. **Sempre** limpe memória após uso (difícil em Dart)
5. **Considere** usar encrypted storage se salvar resultados

## 📝 Contributing Guidelines

1. Fork o projeto
2. Crie feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add AmazingFeature'`)
4. Push para branch (`git push origin feature/AmazingFeature`)
5. Abra Pull Request

### Code Style

```dart
// Use dartfmt
flutter format .

// Use análise estática
flutter analyze

// Siga convenções Dart
// - camelCase para variáveis/funções
// - PascalCase para classes
// - SCREAMING_CAPS para constantes
// - Docstrings para APIs públicas
```

## 🎯 Future Enhancements

### High Priority
- [ ] Testes unitários e de widget
- [ ] Sistema de checkpoint
- [ ] Importar/exportar targets

### Medium Priority
- [ ] Modo share (M/N)
- [ ] Estatísticas avançadas
- [ ] Time estimation
- [ ] Multiple isolates

### Low Priority
- [ ] Suporte Bech32
- [ ] FFI native code
- [ ] GPU support (FFI)
- [ ] Dark/Light theme toggle

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [PointyCastle Library](https://pub.dev/packages/pointycastle)
- [Bitcoin Developer Guide](https://bitcoin.org/en/developer-guide)
- [secp256k1 Curve](https://en.bitcoin.it/wiki/Secp256k1)

## 💬 Support

Para dúvidas técnicas:
1. Leia a documentação
2. Verifique issues existentes
3. Abra nova issue com detalhes

---

**Happy Coding! 🚀**
