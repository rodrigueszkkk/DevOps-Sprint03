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

echo "=================================================================="
echo "ATENÇÃO: Este comando excluirá TODOS os recursos do grupo '$RESOURCE_GROUP'."
echo "=================================================================="

read -p "Deseja realmente prosseguir com a exclusão? (s/N): " CONFIRM
if [[ "$CONFIRM" =~ ^[sS]$ ]]; then
    echo "Excluindo Resource Group '$RESOURCE_GROUP'..."
    az group delete --name "$RESOURCE_GROUP" --yes --no-wait
    echo "Exclusão solicitada com sucesso em background."
else
    echo "Operação cancelada."
fi
