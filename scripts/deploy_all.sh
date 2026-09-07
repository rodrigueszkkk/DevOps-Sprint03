#!/bin/bash
# =====================================================================
# SCRIPT MESTRE: EXECUÇÃO COMPLETA DA ESTEIRA DEVOPS NA AZURE
# FIAP - DevOps Tools & Cloud Computing - Sprint 3
# =====================================================================

set -e

if [ -n "$1" ]; then
    RM="$1"
else
    read -p "Informe seu RM (somente números): " RM
fi

if [ -z "$RM" ]; then
    echo "ERRO: O RM é obrigatório."
    exit 1
fi

if [ -n "$2" ]; then
    LOCATION="$2"
else
    read -p "Informe a região da Azure [padrão: eastus]: " LOCATION
    LOCATION="${LOCATION:-eastus}"
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================================="
echo "   FIAP - DEVOPS TOOLS & CLOUD COMPUTING - SPRINT 3"
echo "   DEPLOY AUTOMATIZADO 100% AZURE CLI (ACR + ACI)"
echo "   Região: $LOCATION"
echo "=================================================================="

# Etapa 1: Infraestrutura Base
bash "$DIR/01_setup_infra.sh" "$RM" "$LOCATION"

# Etapa 2: ACR e Build das Imagens
bash "$DIR/02_build_push_acr.sh" "$RM" "$LOCATION"

# Etapa 3: Deploy do Banco de Dados
bash "$DIR/03_deploy_mysql_aci.sh" "$RM" "$LOCATION"

# Etapa 4: Deploy da Aplicação .NET
bash "$DIR/04_deploy_api_aci.sh" "$RM" "$LOCATION"

echo ""
echo "=================================================================="
echo "DEPLOY GERAL FINALIZADO COM SUCESSO!"
echo "Acesse a documentação no README.md para o roteiro de testes e gravação do vídeo."
echo "=================================================================="
