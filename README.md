# BitFinder 🔍

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Bitcoin-F7931A?style=for-the-badge&logo=bitcoin&logoColor=white" alt="Bitcoin">
</p>

Uma réplica Flutter do **BitCrack KeyFinder** - ferramenta educacional para busca de chaves privadas Bitcoin.

## 📋 Sobre

BitFinder é uma implementação completa em Flutter/Dart do algoritmo de busca de chaves privadas Bitcoin, baseado no projeto [BitCrack](https://github.com/brichard19/BitCrack) (C++/CUDA/OpenCL).

### ✨ Características

- 🎯 Busca em múltiplos endereços Bitcoin simultaneamente
- ⚙️ Keyspace configurável (START:END, START:+COUNT, etc.)
- 🔄 Sistema de stride personalizável
- 🗜️ Suporte para chaves comprimidas e não-comprimidas
- 📊 Monitoramento de status em tempo real
- 🎨 Interface gráfica moderna (Material 3)
- 📱 Cross-platform (Windows, Linux, macOS, Android, iOS, Web)
- 🔒 Código educacional e bem documentado

## 🚀 Quick Start

```bash
# Clone e entre no diretório
cd bitfinder

# Instale as dependências
flutter pub get

# Execute
flutter run
```

## 📖 Documentação

- **[QUICKSTART.md](QUICKSTART.md)** - Guia rápido de uso
- **[DOCUMENTATION.md](DOCUMENTATION.md)** - Documentação completa
- **[ANALYSIS.md](ANALYSIS.md)** - Análise técnica e comparação com BitCrack

## 🎯 Uso Básico

1. **Adicione um endereço Bitcoin alvo**
2. **Configure o keyspace** (opcional)
3. **Clique em "Start Search"**
4. **Monitore o progresso em tempo real**

## ⚠️ AVISO IMPORTANTE

Este projeto é **APENAS PARA FINS EDUCACIONAIS**:

- ✅ Aprender sobre criptografia Bitcoin
- ✅ Demonstrações educacionais
- ✅ Resolver puzzles autorizados
- ❌ **NÃO** tente acessar carteiras alheias
- ❌ **NÃO** use para propósitos ilegais

**Buscar chaves privadas de endereços que você não possui pode ser ILEGAL em sua jurisdição.**

## 📊 Performance

| Device | Velocidade |
|--------|-----------|
| CPU Moderna | ~5-15 KKey/s |
| CPU Antiga | ~1-5 KKey/s |
| Mobile | ~0.5-2 KKey/s |

**Nota**: BitCrack original com GPU é ~200,000x mais rápido (MKey/s - GKey/s). Esta implementação é para fins educacionais.

## 🏗️ Arquitetura

```
lib/
├── models/          # Estruturas de dados
├── utils/           # Utilitários cripto
├── services/        # Engine de busca
├── providers/       # State management
├── screens/         # UI
└── main.dart        # Entry point
```

## 🔧 Tecnologias

- **Flutter/Dart** - Framework UI cross-platform
- **Provider** - Gerenciamento de estado
- **PointyCastle** - Criptografia (secp256k1, RIPEMD-160)
- **Crypto** - SHA-256
- **Isolates** - Processamento paralelo

## 🤝 Comparação com BitCrack

| Aspecto | BitCrack | BitFinder |
|---------|----------|-----------|
| Linguagem | C++ | Dart |
| Interface | CLI | GUI |
| Processing | GPU | CPU |
| Performance | MKey/s | KKey/s |
| Platform | Windows/Linux | Cross-platform |
| Uso | Produção | Educacional |

## 📚 Conceitos Aprendidos

- Curva elíptica **secp256k1**
- Geração de chaves públicas/privadas
- Endereços Bitcoin (Base58Check)
- Hash functions (SHA-256, RIPEMD-160)
- Processamento paralelo (Isolates)
- State management (Provider)

## 🔮 Roadmap

- [ ] Sistema de checkpoint
- [ ] Importar/exportar alvos de arquivo
- [ ] Modo share (M/N)
- [ ] Estatísticas avançadas
- [ ] Suporte a Bech32 (bc1)
- [ ] FFI para código nativo (performance)

## 📄 Licença

MIT License - mesmo do BitCrack original

## 🙏 Créditos

- **BitCrack Original**: [brichard19/BitCrack](https://github.com/brichard19/BitCrack)
- **Bitcoin Community**: Por toda a documentação e recursos

## ⚖️ Disclaimer

**Este software é fornecido "como está", sem garantias de qualquer tipo. O autor não se responsabiliza por qualquer uso indevido ou ilegal desta ferramenta. Use por sua própria conta e risco.**

---

<p align="center">
  Desenvolvido com ❤️ em Flutter<br>
  <i>"Understanding makes the world safer, not more dangerous."</i>
</p>
