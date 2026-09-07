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

if [ -n "$2" ]; then
    LOCATION="$2"
elif [ -z "$LOCATION" ]; then
    read -p "Informe a região da Azure [padrão: eastus]: " LOCATION
    LOCATION="${LOCATION:-eastus}"
fi

RESOURCE_GROUP="rg-pethealth-rm${RM}"
ACR_NAME="acrpethealthrm${RM}"
KEY_VAULT_NAME="kv-pethealth-rm${RM}"

if ! az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1; then
    az acr create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$ACR_NAME" \
        --sku Basic \
        --location "$LOCATION" \
        --admin-enabled true -o none
fi

ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query passwords[0].value -o tsv)

az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "acr-login-server" --value "$ACR_LOGIN_SERVER" -o none
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "acr-username" --value "$ACR_USERNAME" -o none
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "acr-password" --value "$ACR_PASSWORD" -o none

DOCKER_CMD="docker"

if ! docker info >/dev/null 2>&1; then
    if sudo docker info >/dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
    else
        sudo service docker start >/dev/null 2>&1 || sudo systemctl start docker >/dev/null 2>&1 || true
        sleep 2
        
        if docker info >/dev/null 2>&1; then
            DOCKER_CMD="docker"
        elif sudo docker info >/dev/null 2>&1; then
            DOCKER_CMD="sudo docker"
        fi
    fi
fi

if ! $DOCKER_CMD info >/dev/null 2>&1; then
    echo "Docker não encontrado ou inativo."
    exit 1
fi

echo "$ACR_PASSWORD" | $DOCKER_CMD login "$ACR_LOGIN_SERVER" -u "$ACR_USERNAME" --password-stdin

$DOCKER_CMD build -t "$ACR_LOGIN_SERVER/pethealth-mysql:v1" -f "$ROOT_DIR/database/Dockerfile.mysql" "$ROOT_DIR/database"
$DOCKER_CMD push "$ACR_LOGIN_SERVER/pethealth-mysql:v1"

$DOCKER_CMD build -t "$ACR_LOGIN_SERVER/pethealth-api:v1" -f "$ROOT_DIR/Dockerfile" "$ROOT_DIR"
$DOCKER_CMD push "$ACR_LOGIN_SERVER/pethealth-api:v1"

az acr repository list --name "$ACR_NAME" --output table
