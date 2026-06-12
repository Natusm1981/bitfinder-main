#!/bin/bash
# Script para baixar e compilar libsecp256k1 para Android

set -e

echo "Downloading libsecp256k1..."

# Criar diretório para dependências
mkdir -p android/app/src/main/cpp/deps
cd android/app/src/main/cpp/deps

# Clonar libsecp256k1 oficial do Bitcoin Core
if [ ! -d "secp256k1" ]; then
    git clone https://github.com/bitcoin-core/secp256k1.git
    cd secp256k1
    git checkout v0.4.1  # Versão estável
else
    cd secp256k1
    git pull
fi

echo "Configuring libsecp256k1..."

# Configurar para Android
./autogen.sh

echo "libsecp256k1 downloaded and configured!"
echo "Note: You'll need Android NDK to compile this properly"
echo "The build will happen automatically when you run: flutter build apk"
