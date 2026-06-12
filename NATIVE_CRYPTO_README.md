# Native C++ Crypto for BitFinder

## Estrutura

Esta implementação usa FFI (Foreign Function Interface) para chamar código C++ nativo do Dart, proporcionando até **100x mais performance** na geração de endereços Bitcoin.

### Arquivos Criados

```
android/
  app/
    src/
      main/
        cpp/
          ├── CMakeLists.txt          # Configuração CMake
          └── bitcoin_crypto.cpp      # Implementação C++ (PLACEHOLDER)
        kotlin/
          └── com/example/bitfinder/
              └── NativeCrypto.kt     # Wrapper Kotlin

lib/
  utils/
    ├── native_crypto_binding.dart  # Binding FFI Dart
    └── fast_crypto.dart            # Wrapper com fallback automático
```

### Status Atual

⚠️ **PLACEHOLDER** - A implementação C++ atual é apenas uma estrutura. Para funcionar completamente, precisa:

1. **Biblioteca secp256k1**
   - Adicionar libsecp256k1 ao projeto
   - Implementar geração de chave pública

2. **Funções Hash**
   - SHA-256 (pode usar OpenSSL)
   - RIPEMD-160 (pode usar OpenSSL)

3. **Base58 Encoding**
   - Implementar Base58Check para endereços Bitcoin

### Como Completar a Implementação

#### Opção 1: Usar libsecp256k1 (Recomendado)

1. Baixar libsecp256k1 compilada para Android
2. Adicionar ao CMakeLists.txt:
```cmake
add_library(secp256k1 SHARED IMPORTED)
set_target_properties(secp256k1 PROPERTIES
    IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/libs/${ANDROID_ABI}/libsecp256k1.so
)
target_link_libraries(bitcoin_crypto secp256k1)
```

#### Opção 2: Usar OpenSSL

1. Adicionar OpenSSL ao projeto Android
2. Usar para SHA-256 e RIPEMD-160

### Compilação

O código C++ será compilado automaticamente quando você executar:

```bash
flutter build apk
```

ou

```bash
flutter run
```

### Fallback Automático

Se a biblioteca nativa não estiver disponível ou falhar:
- ✅ O app continua funcionando
- ⚠️ Usa implementação Dart (mais lenta)
- 📊 Indicador visual nas configurações mostra qual está em uso

### Performance Esperada

- **Dart puro**: ~100-1.000 keys/s por thread
- **C++ nativo**: ~10.000-100.000 keys/s por thread (até 100x mais rápido!)

### Verificação

Abra **Configurações → Motor de Criptografia** para ver:
- 🟢 **C++ Nativo (Rápido)** - Implementação nativa ativa
- 🟠 **Dart (Padrão)** - Usando fallback

### Próximos Passos

Para ativar o C++ nativo de verdade:

1. Implementar as funções criptográficas reais
2. Adicionar libsecp256k1 ou OpenSSL
3. Testar com endereços conhecidos
4. Compilar e rodar no Android

### Debug

Se houver problemas, o log mostrará:
```
✅ Using NATIVE C++ crypto (fast)
```
ou
```
⚠️ Using Dart crypto (fallback, slower)
```
