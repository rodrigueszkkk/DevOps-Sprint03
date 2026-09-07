#!/bin/bash

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

RESOURCE_GROUP="rg-pethealth-rm${RM}"

read -p "Deseja excluir o grupo '$RESOURCE_GROUP'? (s/N): " CONFIRM
if [[ "$CONFIRM" =~ ^[sS]$ ]]; then
    az group delete --name "$RESOURCE_GROUP" --yes --no-wait
    az keyvault purge --name "kv-pethealth-rm${RM}" --no-wait 2>/dev/null || true
fi

