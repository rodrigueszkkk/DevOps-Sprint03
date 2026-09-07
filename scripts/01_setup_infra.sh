#!/bin/bash
# =====================================================================
# SCRIPT 01: PROVISIONAMENTO DE INFRAESTRUTURA BASE NA AZURE
# FIAP - DevOps Tools & Cloud Computing - Sprint 3
# =====================================================================

set -e

# Obtenção de parâmetros (via argumento ou prompt interativo seguro)
if [ -n "$1" ]; then
    RM="$1"
else
    read -p "Informe seu RM (somente números): " RM
fi

if [ -z "$RM" ]; then
    echo "ERRO: O RM é obrigatório para nomear os recursos."
    exit 1
fi

if [ -n "$2" ]; then
    LOCATION="$2"
else
    read -p "Informe a região da Azure [padrão: eastus]: " LOCATION
    LOCATION="${LOCATION:-eastus}"
fi

# Variáveis de Recursos
RESOURCE_GROUP="rg-pethealth-rm${RM}"
STORAGE_ACCOUNT="storagerm${RM}"
FILE_SHARE_NAME="mysql-data-share"
KEY_VAULT_NAME="kv-pethealth-rm${RM}"

echo "=================================================================="
echo "Iniciando Etapa 01: Infraestrutura Base Azure"
echo "Grupo de Recursos: $RESOURCE_GROUP | Região: $LOCATION"
echo "=================================================================="

# 1. Registrar provedores de recursos necessários na assinatura
echo "Registrando Resource Providers..."
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.ContainerInstance

# 2. Criar Grupo de Recursos
if ! az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    echo "Criando Resource Group '$RESOURCE_GROUP' em '$LOCATION'..."
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
else
    echo "Resource Group '$RESOURCE_GROUP' já existe."
fi

# 3. Criar Conta de Armazenamento (Storage Account)
if ! az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "Criando Storage Account '$STORAGE_ACCOUNT'..."
    az storage account create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$STORAGE_ACCOUNT" \
        --location "$LOCATION" \
        --sku Standard_LRS
else
    echo "Storage Account '$STORAGE_ACCOUNT' já existe."
fi

# 4. Obter Connection String do Storage e Criar Compartilhamento de Arquivos
echo "Obtendo connection string do Storage Account..."
STORAGE_CONN_STRING=$(az storage account show-connection-string \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --query connectionString -o tsv)

echo "Criando Azure File Share '$FILE_SHARE_NAME' para persistência do banco..."
if ! az storage share exists --name "$FILE_SHARE_NAME" --account-name "$STORAGE_ACCOUNT" --connection-string "$STORAGE_CONN_STRING" --output tsv | grep -i true &>/dev/null; then
    az storage share create \
        --name "$FILE_SHARE_NAME" \
        --account-name "$STORAGE_ACCOUNT" \
        --connection-string "$STORAGE_CONN_STRING" \
        --quota 5
    echo "Compartilhamento '$FILE_SHARE_NAME' criado com sucesso."
else
    echo "Compartilhamento '$FILE_SHARE_NAME' já existe."
fi

# 5. Criar Azure Key Vault para armazenamento seguro de credenciais
if ! az keyvault show --name "$KEY_VAULT_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "Criando Key Vault '$KEY_VAULT_NAME'..."
    az keyvault create \
        --name "$KEY_VAULT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --enable-rbac-authorization false
else
    echo "Key Vault '$KEY_VAULT_NAME' já existe."
fi

# 6. Atribuir permissões no Key Vault para o usuário autenticado
CURRENT_USER=$(az account show --query user.name -o tsv)
echo "Configurando política de acesso no Key Vault para '$CURRENT_USER'..."
az keyvault set-policy \
    --name "$KEY_VAULT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --upn "$CURRENT_USER" \
    --secret-permissions get list set delete recover backup restore purge 2>/dev/null || true

# 7. Definição segura das senhas do Banco de Dados
if [ -z "$MYSQL_ROOT_PASS" ]; then
    read -s -p "Defina a senha de ROOT do MySQL: " MYSQL_ROOT_PASS
    echo ""
fi

if [ -z "$MYSQL_USER_PASS" ]; then
    read -s -p "Defina a senha do USUÁRIO da aplicação: " MYSQL_USER_PASS
    echo ""
fi

echo "Gravando credenciais e segredos no Key Vault..."
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "mysql-database" --value "pethealth_db" -o none
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "mysql-user" --value "pethealth_user" -o none
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "mysql-password" --value "$MYSQL_USER_PASS" -o none
az keyvault secret set --vault-name "$KEY_VAULT_NAME" --name "mysql-root-password" --value "$MYSQL_ROOT_PASS" -o none

echo "=================================================================="
echo "Etapa 01 concluída com sucesso!"
echo "Storage Account: $STORAGE_ACCOUNT | Key Vault: $KEY_VAULT_NAME"
echo "=================================================================="
