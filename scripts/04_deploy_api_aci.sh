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
ACI_API_NAME="aci-api-rm${RM}"
DNS_LABEL="api-rm${RM}"

echo "=================================================================="
echo "Iniciando Etapa 04: Deploy da Aplicação .NET no Azure Container Instance"
echo "ACI API Name: $ACI_API_NAME | DNS Label: $DNS_LABEL"
echo "=================================================================="

echo "Recuperando segredos e dados de conexão do Key Vault..."
ACR_SERVER=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "acr-login-server" --query value -o tsv)
ACR_USER=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "acr-username" --query value -o tsv)
ACR_PASS=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "acr-password" --query value -o tsv)

MYSQL_FQDN=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "mysql-fqdn" --query value -o tsv)
MYSQL_DB=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "mysql-database" --query value -o tsv)
MYSQL_USER=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "mysql-user" --query value -o tsv)
MYSQL_PASS=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "mysql-password" --query value -o tsv)

CONNECTION_STRING="Server=${MYSQL_FQDN};Port=3306;Database=${MYSQL_DB};User=${MYSQL_USER};Password=${MYSQL_PASS};"
echo "Registrando connection string segura no Key Vault..."
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "connection-string" --value "$CONNECTION_STRING" -o none

if az container show --resource-group "$RESOURCE_GROUP" --name "$ACI_API_NAME" &>/dev/null; then
    echo "Instância anterior '$ACI_API_NAME' encontrada. Excluindo..."
    az container delete --resource-group "$RESOURCE_GROUP" --name "$ACI_API_NAME" --yes
fi

echo "Criando container da API .NET no ACI..."
az container create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$ACI_API_NAME" \
    --location "$LOCATION" \
    --image "$ACR_SERVER/pethealth-api:v1" \
    --cpu 1 \
    --memory 1 \
    --os-type Linux \
    --dns-name-label "$DNS_LABEL" \
    --ports 8080 \
    --registry-login-server "$ACR_SERVER" \
    --registry-username "$ACR_USER" \
    --registry-password "$ACR_PASS" \
    --environment-variables \
        "ConnectionStrings__DefaultConnection"="$CONNECTION_STRING" \
        "ASPNETCORE_ENVIRONMENT"="Development" \
    --restart-policy Always

echo "Aguardando inicialização da API..."
sleep 15

API_FQDN=$(az container show --resource-group "$RESOURCE_GROUP" --name "$ACI_API_NAME" --query ipAddress.fqdn -o tsv)
API_IP=$(az container show --resource-group "$RESOURCE_GROUP" --name "$ACI_API_NAME" --query ipAddress.ip -o tsv)

echo "=================================================================="
echo "APLICAÇÃO PUBLICADA COM SUCESSO NA AZURE!"
echo "=================================================================="
echo "URL Base:     http://${API_FQDN}:8080"
echo "Swagger UI:   http://${API_FQDN}:8080/swagger"
echo "Health Check: http://${API_FQDN}:8080/health"
echo "IP Público:   ${API_IP}"
echo "=================================================================="
