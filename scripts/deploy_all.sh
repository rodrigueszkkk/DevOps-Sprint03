#!/bin/bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$DIR/.." && pwd)"

if [ -f "$ROOT_DIR/.env.azure" ]; then
    set -a
    source "$ROOT_DIR/.env.azure"
    set +a
fi

if [ -n "$1" ]; then
    RM="$1"
elif [ -z "$RM" ]; then
    read -p "Informe seu RM (somente números): " RM
fi

if [ -z "$RM" ]; then
    echo "ERRO: O RM é obrigatório."
    exit 1
fi

if [ -n "$2" ]; then
    LOCATION="$2"
elif [ -z "$LOCATION" ]; then
    read -p "Informe a região da Azure [padrão: eastus]: " LOCATION
    LOCATION="${LOCATION:-eastus}"
fi

echo "=================================================================="
echo "   FIAP - DEVOPS TOOLS & CLOUD COMPUTING - SPRINT 3"
echo "   DEPLOY AUTOMATIZADO 100% AZURE CLI (ACR + ACI)"
echo "   RM: $RM | Região: $LOCATION"
echo "=================================================================="

bash "$DIR/01_setup_infra.sh" "$RM" "$LOCATION"
bash "$DIR/02_build_push_acr.sh" "$RM" "$LOCATION"
bash "$DIR/03_deploy_mysql_aci.sh" "$RM" "$LOCATION"
bash "$DIR/04_deploy_api_aci.sh" "$RM" "$LOCATION"

echo ""
echo "=================================================================="
echo "DEPLOY GERAL FINALIZADO COM SUCESSO!"
echo "Acesse a documentação no README.md para o roteiro de testes e gravação do vídeo."
echo "=================================================================="
