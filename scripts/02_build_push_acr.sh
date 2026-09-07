#!/bin/bash
# =====================================================================
# SCRIPT 02: CRIAÇÃO DO ACR, BUILD E PUSH DAS IMAGENS DE CONTAINER
# FIAP - DevOps Tools & Cloud Computing - Sprint 3
# RM: 561760
# =====================================================================

set -e

RM="${1:-561760}"
LOCATION="${2:-eastus}"
RESOURCE_GROUP="rg-pethealth-rm${RM}"
ACR_NAME="acrpethealthrm${RM}"
KEY_VAULT_NAME="kv-pethealth-rm${RM}"

echo "=================================================================="
echo "Iniciando Etapa 02: Azure Container Registry (ACR) e Build de Imagens"
echo "ACR: $ACR_NAME | Resource Group: $RESOURCE_GROUP"
echo "=================================================================="

# 1. Criar o Azure Container Registry (ACR)
if ! az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "Criando Azure Container Registry '$ACR_NAME'..."
    az acr create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$ACR_NAME" \
        --sku Basic \
        --location "$LOCATION" \
        --admin-enabled true
else
    echo "ACR '$ACR_NAME' já existe."
fi

# 2. Obter credenciais administrativas do ACR
echo "Obtendo credenciais do ACR..."
ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query passwords[0].value -o tsv)

# 3. Salvar credenciais do ACR no Key Vault
echo "Armazenando credenciais do ACR no Key Vault..."
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "acr-login-server" --value "$ACR_LOGIN_SERVER" -o none
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "acr-username" --value "$ACR_USERNAME" -o none
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "acr-password" --value "$ACR_PASSWORD" -o none

# 4. Build e Push das Imagens para o ACR
# Verificamos se o docker daemon local está acessível; caso não esteja, usamos 'az acr build' na nuvem
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if docker info &>/dev/null; then
    echo "Docker local detectado. Realizando build e push localmente..."
    
    echo "Realizando login no ACR..."
    az acr login --name "$ACR_NAME"

    echo "Build da imagem do banco MySQL customizado com DDL..."
    docker build -t "$ACR_LOGIN_SERVER/pethealth-mysql:v1" -f "$ROOT_DIR/database/Dockerfile.mysql" "$ROOT_DIR/database"
    echo "Push da imagem MySQL..."
    docker push "$ACR_LOGIN_SERVER/pethealth-mysql:v1"

    echo "Build da imagem da API .NET 8 (Multi-stage + Non-root)..."
    docker build -t "$ACR_LOGIN_SERVER/pethealth-api:v1" -f "$ROOT_DIR/Dockerfile" "$ROOT_DIR"
    echo "Push da imagem da API .NET..."
    docker push "$ACR_LOGIN_SERVER/pethealth-api:v1"
else
    echo "Docker daemon local indisponível. Utilizando Azure Cloud Build (az acr build)..."

    echo "Cloud Build da imagem MySQL..."
    az acr build \
        --registry "$ACR_NAME" \
        --image "pethealth-mysql:v1" \
        --file "$ROOT_DIR/database/Dockerfile.mysql" \
        "$ROOT_DIR/database"

    echo "Cloud Build da imagem da API .NET..."
    az acr build \
        --registry "$ACR_NAME" \
        --image "pethealth-api:v1" \
        --file "$ROOT_DIR/Dockerfile" \
        "$ROOT_DIR"
fi

echo "=================================================================="
echo "Etapa 02 concluída com sucesso!"
echo "Imagens publicadas no ACR $ACR_LOGIN_SERVER:"
az acr repository list --name "$ACR_NAME" --output table
echo "=================================================================="
