# BitFinder - Bitcoin Key Finder (Flutter)

Uma réplica Flutter do **BitCrack KeyFinder**, uma ferramenta para busca de chaves privadas Bitcoin através de força bruta.

## 📋 Visão Geral

BitFinder é uma implementação completa em Flutter/Dart do algoritmo de busca de chaves privadas Bitcoin, baseado no projeto original BitCrack (C++/CUDA/OpenCL). Esta versão oferece:

- ✅ Interface gráfica moderna e intuitiva
- ✅ Busca em múltiplos endereços simultaneamente
- ✅ Suporte para chaves comprimidas e não-comprimidas
- ✅ Configuração de keyspace personalizado
- ✅ Sistema de stride configurável
- ✅ Execução em isolate para melhor performance
- ✅ Monitoramento em tempo real
- ✅ Cross-platform (Windows, Linux, macOS, Android, iOS, Web)

## 🏗️ Arquitetura

### Estrutura do Projeto

```
lib/
├── models/
│   └── key_search_types.dart       # Modelos de dados (Config, Status, Result)
├── utils/
│   └── address_util.dart           # Utilitários cripto (secp256k1, Base58)
├── services/
│   └── key_finder.dart             # Engine de busca (Isolate worker)
├── providers/
│   └── key_finder_provider.dart    # Gerenciamento de estado
├── screens/
│   └── key_finder_screen.dart      # Interface principal
└── main.dart                       # Entry point
```

### Componentes Principais

#### 1. **Models** (`key_search_types.dart`)
Espelha as estruturas C++ originais:
- `PointCompressionType`: Enum para modos de compressão
- `KeySearchTarget`: Representa endereços alvos (address + hash160)
- `KeySearchStatus`: Status em tempo real (speed, total, time)
- `KeySearchResult`: Resultado quando chave é encontrada
- `KeySearchConfig`: Configuração completa da busca

#### 2. **Address Utilities** (`address_util.dart`)
Implementa operações criptográficas essenciais:
- Geração de chaves públicas a partir de privadas (secp256k1)
- Conversão de chaves públicas em hash160 (SHA-256 + RIPEMD-160)
- Codificação/decodificação Base58 com checksum
- Geração de endereços Bitcoin
- Validação de endereços
- Parsing de keyspace (START:END, START:+COUNT, etc.)

#### 3. **Key Finder Service** (`key_finder.dart`)
Engine central de busca:
- Execução em **Dart Isolate** para não bloquear UI
- Iteração através do keyspace configurado
- Comparação eficiente de hash160
- Relatórios periódicos de status
- Callbacks para resultados e erros

#### 4. **Provider** (`key_finder_provider.dart`)
Gerenciamento de estado com ChangeNotifier:
- Controle de início/parada da busca
- Gerenciamento de alvos
- Configuração de parâmetros
- Notificação de resultados e status
- Tratamento de erros

#### 5. **UI** (`key_finder_screen.dart`)
Interface completa com:
- Gerenciamento de endereços alvos
- Configuração de keyspace e stride
- Seleção de modo de compressão
- Controles de start/stop
- Display de status em tempo real
- Visualização de resultados

## 🚀 Como Usar

### Instalação

```bash
# Clone o repositório
cd bitfinder

# Instale as dependências
flutter pub get

# Execute o app
flutter run
```

### Uso Básico

1. **Adicionar Endereço Alvo**
   - Digite um endereço Bitcoin válido
   - Clique no botão "+" para adicionar
   - Pode adicionar múltiplos endereços

2. **Configurar Busca (Opcional)**
   - **Keyspace**: Define o intervalo de busca
     - `START:END` - do START até END
     - `START:+COUNT` - do START por COUNT chaves
     - `:END` - de 1 até END
     - `:+COUNT` - de 1 por COUNT chaves
     - Deixe vazio para buscar todo o range
   
   - **Stride**: Incremento entre chaves (padrão: 1)
   
   - **Compression Mode**:
     - Compressed: Apenas chaves comprimidas
     - Uncompressed: Apenas chaves não-comprimidas
     - Both: Ambos os formatos

3. **Iniciar Busca**
   - Clique em "Start Search"
   - Monitore o progresso em tempo real
   - Resultados aparecerão automaticamente quando encontrados

4. **Parar Busca**
   - Clique em "Stop" a qualquer momento

## 🔧 Funcionalidades Técnicas

### Comparação com BitCrack Original

| Funcionalidade | BitCrack (C++) | BitFinder (Flutter) |
|---|---|---|
| Busca de chaves | ✅ GPU (CUDA/OpenCL) | ✅ CPU (Dart Isolate) |
| Múltiplos alvos | ✅ | ✅ |
| Keyspace customizado | ✅ | ✅ |
| Stride | ✅ | ✅ |
| Compressão | ✅ Both | ✅ Both |
| Checkpoint | ✅ | ⏳ Planejado |
| Share mode | ✅ | ⏳ Planejado |
| Interface gráfica | ❌ | ✅ |
| Cross-platform | ⚠️ Limited | ✅ Full |

### Algoritmo de Busca

```dart
// Pseudocódigo simplificado
while (currentKey < endKey) {
  // 1. Gerar chave pública
  publicKey = secp256k1(currentKey)
  
  // 2. Converter para hash160
  hash160 = RIPEMD160(SHA256(publicKey))
  
  // 3. Comparar com alvos
  if (hash160 in targets) {
    // 4. Gerar endereço e reportar
    address = Base58CheckEncode(hash160)
    reportResult(address, currentKey)
  }
  
  // 5. Incrementar
  currentKey += stride
}
```

### Performance

**Aviso**: Esta é uma implementação em Dart puro rodando na CPU. O BitCrack original usa GPU (CUDA/OpenCL) e é **milhares de vezes mais rápido**.

Velocidades esperadas:
- CPU moderna: ~1-10 KKey/s (vs. GPU: MKey/s - GKey/s)
- Melhor para educação e demonstração
- Para uso sério, use o BitCrack original com GPU

## 📦 Dependências

```yaml
dependencies:
  provider: ^6.1.1        # Gerenciamento de estado
  crypto: ^3.0.3          # SHA-256
  pointycastle: ^3.7.4    # secp256k1, RIPEMD-160
  intl: ^0.19.0           # Formatação
```

## ⚠️ Avisos Importantes

### Educacional

Este projeto é **APENAS PARA FINS EDUCACIONAIS**:
- Demonstra conceitos de criptografia Bitcoin
- Ilustra força bruta e suas limitações
- Ensina sobre curvas elípticas e hashing

### Legal

**⚠️ AVISO LEGAL**: 
- Buscar chaves privadas de endereços que você **NÃO** possui pode ser **ILEGAL**
- Use apenas para:
  - Educação
  - Pesquisa
  - Recuperação de suas próprias chaves perdidas
  - Desafios públicos autorizados (como Bitcoin Puzzle)

### Segurança

- **Nunca** use em produção para carteiras reais
- **Não** confie neste código para segurança crítica
- A busca completa do keyspace Bitcoin é **computacionalmente inviável**
- Mesmo com milhões de GPUs levaria bilhões de anos

## 🎯 Casos de Uso

### ✅ Apropriados
- Aprender sobre criptografia Bitcoin
- Entender secp256k1 e ECDSA
- Demonstrações educacionais
- Resolver puzzles autorizados
- Recuperar suas próprias chaves (com hint de range)

### ❌ Inapropriados
- Tentar roubar Bitcoin
- Buscar chaves de carteiras alheias
- Qualquer uso malicioso

## 🔮 Roadmap

- [ ] Implementar checkpoint/save progress
- [ ] Adicionar modo share (M/N)
- [ ] Salvar resultados em arquivo
- [ ] Importar alvos de arquivo
- [ ] Estatísticas avançadas
- [ ] Estimativa de tempo restante
- [ ] Suporte a bech32 (endereços bc1)
- [ ] Otimizações de performance
- [ ] FFI binding para código C++ nativo (opcional)

## 📚 Recursos

### Bitcoin & Criptografia
- [Bitcoin Wiki - Private Key](https://en.bitcoin.it/wiki/Private_key)
- [secp256k1 Curve](https://en.bitcoin.it/wiki/Secp256k1)
- [Base58Check encoding](https://en.bitcoin.it/wiki/Base58Check_encoding)

### BitCrack Original
- [GitHub - BitCrack](https://github.com/brichard19/BitCrack)
- [Bitcoin Puzzle Transaction](https://privatekeys.pw/puzzles/bitcoin-puzzle-tx)

## 🤝 Contribuindo

Contribuições são bem-vindas! Áreas de interesse:
- Otimizações de performance
- Melhorias na UI/UX
- Testes unitários
- Documentação
- Correções de bugs

## 📄 Licença

Este projeto segue a mesma licença do BitCrack original (MIT).

---

**Desenvolvido com Flutter 💙**

*"Understanding makes the world safer, not more dangerous."*
