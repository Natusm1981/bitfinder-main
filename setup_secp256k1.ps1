# Script para baixar libsecp256k1 para Android

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  BitFinder - Setup libsecp256k1" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

$depsDir = "android\app\src\main\cpp\deps"
$secp256k1Dir = "$depsDir\secp256k1"

# Criar diretorio deps
if (-not (Test-Path $depsDir)) {
    Write-Host "[1/3] Criando diretorio deps..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $depsDir -Force | Out-Null
    Write-Host "      OK - Diretorio criado" -ForegroundColor Green
} else {
    Write-Host "[1/3] Diretorio deps ja existe" -ForegroundColor Green
}

# Verificar Git
Write-Host "[2/3] Verificando Git..." -ForegroundColor Yellow
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitInstalled) {
    Write-Host "      ERRO - Git nao encontrado!" -ForegroundColor Red
    Write-Host "      Instale: https://git-scm.com/download/win" -ForegroundColor Red
    exit 1
}
Write-Host "      OK - Git encontrado" -ForegroundColor Green

# Clonar libsecp256k1
Write-Host "[3/3] Baixando libsecp256k1..." -ForegroundColor Yellow
if (Test-Path $secp256k1Dir) {
    Write-Host "      -> libsecp256k1 ja existe, atualizando..." -ForegroundColor Cyan
    Push-Location $secp256k1Dir
    git pull origin master 2>&1 | Out-Null
    Pop-Location
    Write-Host "      OK - Atualizado" -ForegroundColor Green
} else {
    Write-Host "      -> Clonando repositorio Bitcoin Core..." -ForegroundColor Cyan
    git clone https://github.com/bitcoin-core/secp256k1.git $secp256k1Dir 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      OK - Clone concluido" -ForegroundColor Green
        
        Push-Location $secp256k1Dir
        Write-Host "      -> Selecionando versao v0.4.1..." -ForegroundColor Cyan
        git checkout v0.4.1 2>&1 | Out-Null
        Pop-Location
        Write-Host "      OK - Versao v0.4.1 selecionada" -ForegroundColor Green
    } else {
        Write-Host "      ERRO ao clonar" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  Setup concluido com sucesso!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Proximos passos:" -ForegroundColor Cyan
Write-Host "  1. flutter build apk --release" -ForegroundColor White
Write-Host "  2. CMake compilara libsecp256k1 automaticamente" -ForegroundColor White
Write-Host "  3. Performance: 10-100x mais rapido!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Biblioteca: $secp256k1Dir" -ForegroundColor Cyan
Write-Host "Versao: v0.4.1 (Bitcoin Core)" -ForegroundColor Cyan
Write-Host ""
