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


if ! az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "acr-login-server" >/dev/null 2>&1; then
    ACR_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)
    ACR_USER=$(az acr credential show --name "$ACR_NAME" --query username -o tsv)
    ACR_PASS=$(az acr credential show --name "$ACR_NAME" --query passwords[0].value -o tsv)
    az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "acr-login-server" --value "$ACR_SERVER" -o none
    az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "acr-username" --value "$ACR_USER" -o none
    az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "acr-password" --value "$ACR_PASS" -o none
else
    ACR_SERVER=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "acr-login-server" --query value -o tsv)
    ACR_USER=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "acr-username" --query value -o tsv)
    ACR_PASS=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "acr-password" --query value -o tsv)
fi

MYSQL_FQDN=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "mysql-fqdn" --query value -o tsv)
MYSQL_DB=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "mysql-database" --query value -o tsv)
MYSQL_USER=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "mysql-user" --query value -o tsv)
MYSQL_PASS=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "mysql-password" --query value -o tsv)

CONNECTION_STRING="Server=${MYSQL_FQDN};Port=3306;Database=${MYSQL_DB};User=${MYSQL_USER};Password=${MYSQL_PASS};"
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "connection-string" --value "$CONNECTION_STRING" -o none

if az container show --resource-group "$RESOURCE_GROUP" --name "$ACI_API_NAME" >/dev/null 2>&1; then
    az container delete --resource-group "$RESOURCE_GROUP" --name "$ACI_API_NAME" --yes -o none
fi

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
    --restart-policy Always -o none

sleep 15

API_FQDN=$(az container show --resource-group "$RESOURCE_GROUP" --name "$ACI_API_NAME" --query ipAddress.fqdn -o tsv)
API_IP=$(az container show --resource-group "$RESOURCE_GROUP" --name "$ACI_API_NAME" --query ipAddress.ip -o tsv)

echo "URL Base:     http://${API_FQDN}:8080"
echo "Swagger UI:   http://${API_FQDN}:8080/swagger"
echo "Health Check: http://${API_FQDN}:8080/health"
echo "IP Público:   ${API_IP}"

