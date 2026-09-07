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
STORAGE_ACCOUNT="storagerm${RM}"
FILE_SHARE_NAME="mysql-data-share"
KEY_VAULT_NAME="kv-pethealth-rm${RM}"
ACI_MYSQL_NAME="aci-mysql-rm${RM}"
DNS_LABEL="mysql-rm${RM}"

STORAGE_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP" \
    --account-name "$STORAGE_ACCOUNT" \
    --query "[0].value" -o tsv)

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

MYSQL_DB=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "mysql-database" --query value -o tsv)
MYSQL_USER=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "mysql-user" --query value -o tsv)
MYSQL_PASS=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "mysql-password" --query value -o tsv)
MYSQL_ROOT_PASS=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "mysql-root-password" --query value -o tsv)

if az container show --resource-group "$RESOURCE_GROUP" --name "$ACI_MYSQL_NAME" >/dev/null 2>&1; then
    az container delete --resource-group "$RESOURCE_GROUP" --name "$ACI_MYSQL_NAME" --yes -o none
fi

az container create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$ACI_MYSQL_NAME" \
    --location "$LOCATION" \
    --image "$ACR_SERVER/pethealth-mysql:v1" \
    --cpu 1 \
    --memory 1.5 \
    --os-type Linux \
    --dns-name-label "$DNS_LABEL" \
    --ports 3306 \
    --registry-login-server "$ACR_SERVER" \
    --registry-username "$ACR_USER" \
    --registry-password "$ACR_PASS" \
    --azure-file-volume-account-name "$STORAGE_ACCOUNT" \
    --azure-file-volume-account-key "$STORAGE_KEY" \
    --azure-file-volume-share-name "$FILE_SHARE_NAME" \
    --azure-file-volume-mount-path "/var/lib/mysql" \
    --environment-variables \
        MYSQL_DATABASE="$MYSQL_DB" \
        MYSQL_USER="$MYSQL_USER" \
        MYSQL_PASSWORD="$MYSQL_PASS" \
        MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASS" \
    --restart-policy Always -o none

sleep 15

MYSQL_FQDN=$(az container show --resource-group "$RESOURCE_GROUP" --name "$ACI_MYSQL_NAME" --query ipAddress.fqdn -o tsv)
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "mysql-fqdn" --value "$MYSQL_FQDN" -o none

echo "MySQL ACI FQDN: $MYSQL_FQDN"
