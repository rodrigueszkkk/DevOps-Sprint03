param(
    [Parameter(Mandatory=$false)]
    [string]$RM,
    [Parameter(Mandatory=$false)]
    [string]$Location
)

$ErrorActionPreference = "Stop"

$rootDir = Split-Path -Parent $PSScriptRoot

if (-not $RM -or -not $Location) {
    $envAzurePath = Join-Path $rootDir ".env.azure"
    if (Test-Path $envAzurePath) {
        Get-Content $envAzurePath | ForEach-Object {
            if ($_ -match '^\s*([^#=]+)\s*=\s*(.*)$') {
                $varName = $matches[1].Trim()
                $varVal = $matches[2].Trim()
                if ($varName -eq "RM" -and -not $RM) { $RM = $varVal }
                if ($varName -eq "LOCATION" -and -not $Location) { $Location = $varVal }
            }
        }
    }
}

if (-not $RM) {
    $RM = Read-Host "Informe seu RM (somente números)"
}
if (-not $RM) {
    Write-Error "ERRO: O RM é obrigatório para nomear os recursos."
    exit 1
}

if (-not $Location) {
    $Location = Read-Host "Informe a região da Azure [padrão: eastus]"
    if (-not $Location) { $Location = "eastus" }
}

$ResourceGroup = "rg-pethealth-rm$RM"
$StorageAccount = "storagerm$RM"
$FileShareName = "mysql-data-share"
$KeyVaultName = "kv-pethealth-rm$RM"
$AcrName = "acrpethealthrm$RM"
$AciMysqlName = "aci-mysql-rm$RM"
$AciApiName = "aci-api-rm$RM"
$MysqlDns = "mysql-rm$RM"
$ApiDns = "api-rm$RM"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  FIAP - DEVOPS TOOLS & CLOUD COMPUTING - SPRINT 3" -ForegroundColor Cyan
Write-Host "  DEPLOY 100% AZURE CLI (ACR + ACI) - POWERSHELL" -ForegroundColor Cyan
Write-Host "  RM: $RM | Região: $Location | Grupo: $ResourceGroup" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

if (-not $env:MYSQL_ROOT_PASS) {
    $mysqlRootSec = Read-Host "Defina a senha de ROOT do MySQL para o Key Vault" -AsSecureString
    $bstrRoot = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($mysqlRootSec)
    $plainRoot = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstrRoot)
} else {
    $plainRoot = $env:MYSQL_ROOT_PASS
}

if (-not $env:MYSQL_USER_PASS) {
    $mysqlUserSec = Read-Host "Defina a senha do USUÁRIO da aplicação para o Key Vault" -AsSecureString
    $bstrUser = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($mysqlUserSec)
    $plainUser = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstrUser)
} else {
    $plainUser = $env:MYSQL_USER_PASS
}

Write-Host "`n[1/6] Registrando Resource Providers..." -ForegroundColor Yellow
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.ContainerInstance

Write-Host "`n[2/6] Criando/Verificando Resource Group..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -ne "true") {
    az group create --name $ResourceGroup --location $Location
}

Write-Host "`n[3/6] Criando Storage Account e File Share para o volume do banco..." -ForegroundColor Yellow
az storage account create --resource-group $ResourceGroup --name $StorageAccount --location $Location --sku Standard_LRS
$storageConnString = az storage account show-connection-string --name $StorageAccount --resource-group $ResourceGroup --query connectionString -o tsv
az storage share create --name $FileShareName --account-name $StorageAccount --connection-string $storageConnString --quota 5

Write-Host "`n[4/6] Criando Key Vault e gravando credenciais seguras..." -ForegroundColor Yellow
az keyvault create --name $KeyVaultName --resource-group $ResourceGroup --location $Location --enable-rbac-authorization false
$currentUser = az account show --query user.name -o tsv
az keyvault set-policy --name $KeyVaultName --resource-group $ResourceGroup --upn $currentUser --secret-permissions get list set delete recover backup restore purge

az keyvault secret set --vault-name $KeyVaultName --name "mysql-database" --value "pethealth_db" -o none
az keyvault secret set --vault-name $KeyVaultName --name "mysql-user" --value "pethealth_user" -o none
az keyvault secret set --vault-name $KeyVaultName --name "mysql-password" --value $plainUser -o none
az keyvault secret set --vault-name $KeyVaultName --name "mysql-root-password" --value $plainRoot -o none

Write-Host "`n[5/6] Criando ACR e compilando imagens com Docker..." -ForegroundColor Yellow
az acr create --resource-group $ResourceGroup --name $AcrName --sku Basic --location $Location --admin-enabled true

$acrLoginServer = az acr show --name $AcrName --query loginServer -o tsv
$acrUser = az acr credential show --name $AcrName --query username -o tsv
$acrPass = az acr credential show --name $AcrName --query passwords[0].value -o tsv

az keyvault secret set --vault-name $KeyVaultName --name "acr-login-server" --value $acrLoginServer -o none
az keyvault secret set --vault-name $KeyVaultName --name "acr-username" --value $acrUser -o none
az keyvault secret set --vault-name $KeyVaultName --name "acr-password" --value $acrPass -o none

Write-Host "Autenticando Docker no ACR ($acrLoginServer)..." -ForegroundColor Yellow
echo $acrPass | docker login $acrLoginServer -u $acrUser --password-stdin

Write-Host "Compilando imagem MySQL com DDL..." -ForegroundColor Yellow
docker build -t "$acrLoginServer/pethealth-mysql:v1" -f "$rootDir\database\Dockerfile.mysql" "$rootDir\database"
docker push "$acrLoginServer/pethealth-mysql:v1"

Write-Host "Compilando imagem API .NET 8 (Non-root)..." -ForegroundColor Yellow
docker build -t "$acrLoginServer/pethealth-api:v1" -f "$rootDir\Dockerfile" "$rootDir"
docker push "$acrLoginServer/pethealth-api:v1"

Write-Host "`n[6/6] Provisionando Containers no Azure Container Instances..." -ForegroundColor Yellow
$storageKey = az storage account keys list --resource-group $ResourceGroup --account-name $StorageAccount --query "[0].value" -o tsv

az container delete --resource-group $ResourceGroup --name $AciMysqlName --yes 2>$null
az container create `
    --resource-group $ResourceGroup `
    --name $AciMysqlName `
    --location $Location `
    --image "$acrLoginServer/pethealth-mysql:v1" `
    --cpu 1 `
    --memory 1.5 `
    --os-type Linux `
    --dns-name-label $MysqlDns `
    --ports 3306 `
    --registry-login-server $acrLoginServer `
    --registry-username $acrUser `
    --registry-password $acrPass `
    --azure-file-volume-account-name $StorageAccount `
    --azure-file-volume-account-key $storageKey `
    --azure-file-volume-share-name $FileShareName `
    --azure-file-volume-mount-path "/var/lib/mysql" `
    --environment-variables `
        MYSQL_DATABASE="pethealth_db" `
        MYSQL_USER="pethealth_user" `
        MYSQL_PASSWORD="$plainUser" `
        MYSQL_ROOT_PASSWORD="$plainRoot" `
    --restart-policy Always

Start-Sleep -Seconds 15

$mysqlFqdn = az container show --resource-group $ResourceGroup --name $AciMysqlName --query ipAddress.fqdn -o tsv
$connString = "Server=$mysqlFqdn;Port=3306;Database=pethealth_db;User=pethealth_user;Password=$plainUser;"
az keyvault secret set --vault-name $KeyVaultName --name "connection-string" --value $connString -o none

az container delete --resource-group $ResourceGroup --name $AciApiName --yes 2>$null
az container create `
    --resource-group $ResourceGroup `
    --name $AciApiName `
    --location $Location `
    --image "$acrLoginServer/pethealth-api:v1" `
    --cpu 1 `
    --memory 1 `
    --os-type Linux `
    --dns-name-label $ApiDns `
    --ports 8080 `
    --registry-login-server $acrLoginServer `
    --registry-username $acrUser `
    --registry-password $acrPass `
    --environment-variables `
        ConnectionStrings__DefaultConnection=$connString `
        ASPNETCORE_ENVIRONMENT="Development" `
    --restart-policy Always

Start-Sleep -Seconds 15

$apiFqdn = az container show --resource-group $ResourceGroup --name $AciApiName --query ipAddress.fqdn -o tsv
$apiIp = az container show --resource-group $ResourceGroup --name $AciApiName --query ipAddress.ip -o tsv

Write-Host "`n==================================================================" -ForegroundColor Green
Write-Host "DEPLOY FINALIZADO COM SUCESSO NA AZURE!" -ForegroundColor Green
Write-Host "Swagger UI:   http://${apiFqdn}:8080/swagger" -ForegroundColor Green
Write-Host "Health Check: http://${apiFqdn}:8080/health" -ForegroundColor Green
Write-Host "IP Público:   $apiIp" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Green
