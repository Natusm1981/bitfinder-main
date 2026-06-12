# BitFinder - Quick Start Guide

## 🚀 Início Rápido

### 1. Execute a Aplicação

```bash
flutter run
```

Ou para uma plataforma específica:
```bash
flutter run -d windows
flutter run -d chrome
flutter run -d android
```

### 2. Primeiro Uso

#### Passo 1: Adicione um Endereço Target
1. No campo "Bitcoin Address", cole um endereço válido
2. Exemplo: `1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa` (endereço do Satoshi)
3. Clique no botão **+** para adicionar

#### Passo 2: Configure a Busca (Opcional)
- **Keyspace**: Defina o intervalo
  - Exemplo: `1:10000` (buscar de 1 até 10000)
  - Exemplo: `1000:+1000` (buscar de 1000 por mais 1000 chaves)
  - Deixe vazio para buscar todo o range (não recomendado!)

- **Stride**: Incremento entre chaves
  - Padrão: `1` (busca sequencial)
  - Exemplo: `2` (busca apenas chaves pares)

- **Compression Mode**:
  - **Compressed**: Apenas endereços com chaves comprimidas
  - **Uncompressed**: Apenas endereços com chaves não-comprimidas
  - **Both**: Ambos (leva 2x mais tempo)

#### Passo 3: Inicie a Busca
1. Clique no botão **Start Search**
2. Observe o status em tempo real:
   - Speed: Velocidade em MKey/s
   - Total Keys: Total de chaves verificadas
   - Elapsed: Tempo decorrido
   - Next Key: Próxima chave a ser verificada

#### Passo 4: Resultados
- Quando uma chave for encontrada, aparecerá na seção **Results**
- Você pode copiar o resultado clicando no ícone de **copy**
- O resultado inclui:
  - Endereço encontrado
  - Chave privada (em hexadecimal)
  - Chave pública (X e Y)
  - Se estava comprimida ou não

### 3. Exemplos Práticos

#### Exemplo 1: Busca Simples (Demonstração)
```
Target: 1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa
Keyspace: 1:1000
Stride: 1
Compression: Compressed
```

Este exemplo busca as primeiras 1000 chaves. **Não encontrará resultado** (a chave privada do Satoshi é desconhecida).

#### Exemplo 2: Teste com Chave Conhecida
Para testar, você pode:
1. Gerar um endereço de teste
2. Usar uma ferramenta online para converter uma chave privada pequena em endereço
3. Exemplo: chave `1` → endereço específico
4. Buscar keyspace `1:10` e encontrará

#### Exemplo 3: Bitcoin Puzzle #1-20
```
Target: (adicione endereços do puzzle)
Keyspace: (range específico do puzzle)
Stride: 1
Compression: Compressed
```

**Nota**: Puzzles 1-20 já foram resolvidos. Use apenas para teste.

### 4. Dicas de Performance

#### ⚡ Otimização
- **Keyspace menor**: Quanto menor o range, mais rápido
- **Stride maior**: Pula chaves, mais rápido mas menos completo
- **Compression única**: Escolha compressed OU uncompressed, não both
- **CPU moderna**: Processador rápido = busca mais rápida

#### 📊 Performance Esperada
- **CPU moderna (i7/Ryzen 7)**: ~5-15 KKey/s
- **CPU antiga**: ~1-5 KKey/s
- **Mobile**: ~0.5-2 KKey/s

#### ⏱️ Estimativa de Tempo
Para buscar diferentes ranges:
- **1,000 keys**: ~0.1-1 segundo
- **10,000 keys**: ~1-10 segundos
- **100,000 keys**: ~10-100 segundos
- **1,000,000 keys**: ~2-15 minutos
- **10,000,000 keys**: ~20-150 minutos

### 5. Limitações

⚠️ **IMPORTANTE**:
- Esta é uma implementação **educacional**
- A velocidade é **milhares de vezes mais lenta** que BitCrack com GPU
- **NÃO** use para tentar encontrar chaves de carteiras reais
- O keyspace completo do Bitcoin (2^256) levaria **bilhões de anos** mesmo com supercomputadores

### 6. Troubleshooting

#### Problema: App trava ao iniciar busca
**Solução**: O isolate está trabalhando. Aguarde alguns segundos para o primeiro status aparecer.

#### Problema: "Invalid address"
**Solução**: 
- Verifique se o endereço é válido
- Deve começar com 1, 3, ou bc1
- Deve ter 26-62 caracteres
- Não pode ter caracteres especiais (exceto base58)

#### Problema: Busca muito lenta
**Solução**:
- Reduza o keyspace
- Aumente o stride
- Use apenas compressed OU uncompressed
- Feche outros apps para liberar CPU

#### Problema: Não encontra resultado
**Solução**: Isso é normal! A chance de encontrar uma chave aleatória é:
- Em 1,000 keys: ~0% (essencialmente zero)
- Em 1,000,000 keys: ~0% (essencialmente zero)
- Em todo o keyspace: ~0% (impossível)

### 7. Casos de Uso Válidos

✅ **Use para**:
- Aprender sobre Bitcoin e criptografia
- Demonstrações educacionais
- Testar com chaves conhecidas (suas próprias)
- Resolver puzzles autorizados
- Entender força bruta e suas limitações

❌ **NÃO use para**:
- Tentar roubar Bitcoin
- Buscar chaves de carteiras alheias
- Qualquer propósito ilegal

### 8. Próximos Passos

Depois de dominar o básico:
1. Leia `DOCUMENTATION.md` para detalhes técnicos
2. Leia `ANALYSIS.md` para entender a implementação
3. Explore o código fonte em `lib/`
4. Experimente modificar parâmetros
5. Contribua com melhorias!

### 9. Suporte

Para dúvidas:
- Leia a documentação completa
- Verifique os comentários no código
- Abra uma issue no repositório (se aplicável)

### 10. Recursos Adicionais

- [Bitcoin Wiki](https://en.bitcoin.it/wiki/Main_Page)
- [BitCrack Original](https://github.com/brichard19/BitCrack)
- [secp256k1 Info](https://en.bitcoin.it/wiki/Secp256k1)
- [Bitcoin Puzzle Transaction](https://privatekeys.pw/puzzles/bitcoin-puzzle-tx)

---

**Boa sorte e bom aprendizado! 🚀**

*Lembre-se: Este é um projeto educacional. Use com responsabilidade.*
