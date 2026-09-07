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

echo "=================================================================="
echo "Iniciando Etapa 02: Azure Container Registry (ACR) e Build de Imagens"
echo "ACR: $ACR_NAME | Resource Group: $RESOURCE_GROUP"
echo "=================================================================="

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

echo "Obtendo credenciais do ACR..."
ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query passwords[0].value -o tsv)

echo "Armazenando credenciais do ACR no Key Vault..."
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "acr-login-server" --value "$ACR_LOGIN_SERVER" -o none
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "acr-username" --value "$ACR_USERNAME" -o none
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "acr-password" --value "$ACR_PASSWORD" -o none

DOCKER_CMD="docker"

if ! docker info &>/dev/null; then
    if sudo docker info &>/dev/null; then
        DOCKER_CMD="sudo docker"
    else
        echo "Iniciando serviço Docker..."
        sudo service docker start 2>/dev/null || sudo systemctl start docker 2>/dev/null || true
        sleep 2
        
        if docker info &>/dev/null; then
            DOCKER_CMD="docker"
        elif sudo docker info &>/dev/null; then
            DOCKER_CMD="sudo docker"
        fi
    fi
fi

if ! $DOCKER_CMD info &>/dev/null; then
    echo ""
    echo "=================================================================="
    echo "ERRO: O Docker daemon não está em execução nesta máquina!"
    echo "=================================================================="
    echo "A assinatura educacional da Azure bloqueia compilações remotas (TasksOperationsNotAllowed)."
    echo "O build precisa ser realizado com Docker local (padrão da Aula 12)."
    echo ""
    echo "Para resolver:"
    echo "1) Se estiver no Linux/WSL, execute:"
    echo "   sudo service docker start"
    echo "2) Se estiver no Windows/Mac:"
    echo "   Abra o aplicativo Docker Desktop e aguarde ele inicializar."
    echo "=================================================================="
    exit 1
fi

echo "Docker operacional utilizando: $DOCKER_CMD"

echo "Realizando login no ACR ($ACR_LOGIN_SERVER)..."
echo "$ACR_PASSWORD" | $DOCKER_CMD login "$ACR_LOGIN_SERVER" -u "$ACR_USERNAME" --password-stdin

echo "Compilando imagem do banco MySQL com DDL embutido..."
$DOCKER_CMD build -t "$ACR_LOGIN_SERVER/pethealth-mysql:v1" -f "$ROOT_DIR/database/Dockerfile.mysql" "$ROOT_DIR/database"

echo "Enviando imagem do MySQL para o ACR..."
$DOCKER_CMD push "$ACR_LOGIN_SERVER/pethealth-mysql:v1"

echo "Compilando imagem da API .NET 8 (Multi-stage + Non-root)..."
$DOCKER_CMD build -t "$ACR_LOGIN_SERVER/pethealth-api:v1" -f "$ROOT_DIR/Dockerfile" "$ROOT_DIR"

echo "Enviando imagem da API .NET para o ACR..."
$DOCKER_CMD push "$ACR_LOGIN_SERVER/pethealth-api:v1"

echo "=================================================================="
echo "Etapa 02 concluída com sucesso!"
echo "Imagens publicadas no ACR $ACR_LOGIN_SERVER:"
az acr repository list --name "$ACR_NAME" --output table
echo "=================================================================="
