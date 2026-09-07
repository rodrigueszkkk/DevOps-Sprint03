# PetHealthEcosystem - DevOps & Cloud Computing (FIAP - Sprint 3)

[![.NET 8](https://img.shields.io/badge/.NET-8.0-blue.svg)](https://dotnet.microsoft.com/)
[![Azure ACI](https://img.shields.io/badge/Azure-Container%20Instances-0078D4.svg)](https://azure.microsoft.com/services/container-instances/)
[![Azure ACR](https://img.shields.io/badge/Azure-Container%20Registry-0078D4.svg)](https://azure.microsoft.com/services/container-registry/)
[![MySQL 8.0](https://img.shields.io/badge/MySQL-8.0-orange.svg)](https://www.mysql.com/)

Repositório acadêmico desenvolvido para a **3ª Sprint da disciplina DevOps Tools & Cloud Computing** na FIAP. A solução aborda a conteinerização, automação de infraestrutura via **Azure CLI** e publicação em nuvem Microsoft Azure do ecossistema de saúde veterinária **PetHealthEcosystem**, utilizando a **Opção 1: ACR + ACI**.

---

## 👥 Identificação do Aluno / Grupo

- **Nome Completo:** [Nome do Integrante] | **RM:** [Seu RM]
- **Repositório GitHub:** [https://github.com/rodrigueszkkk/DevOps-Sprint03.git](https://github.com/rodrigueszkkk/DevOps-Sprint03.git)
- **Vídeo Demonstrativo no YouTube:** [Link do Vídeo](https://www.youtube.com/watch?v=SEU_ID_DO_VIDEO)

---

## 📋 Sumário

1. [Descrição da Solução](#1-descrição-da-solução)
2. [Benefícios para o Negócio](#2-benefícios-para-o-negócio)
3. [Arquitetura em Nuvem Azure](#3-arquitetura-em-nuvem-azure)
4. [Modelagem do Banco de Dados (CORE)](#4-modelagem-do-banco-de-dados-core)
5. [Segurança e Conformidade de Containers](#5-segurança-e-conformidade-de-containers)
6. [Guia de Execução Local](#6-guia-de-execução-local)
7. [Guia de Deploy na Nuvem Azure (How-To Azure CLI)](#7-guia-de-deploy-na-nuvem-azure-how-to-azure-cli)
8. [Roteiro de Validação do CRUD e Persistência](#8-roteiro-de-validação-do-crud-e-persistência)
9. [Destruição de Recursos (FinOps)](#9-destruição-de-recursos-finops)

---

## 1. Descrição da Solução

O **PetHealthEcosystem** é uma API RESTful desenvolvida em **ASP.NET Core (.NET 8)** voltada à gestão clínica e operacional de pacientes em hospitais e clínicas veterinárias.

A plataforma gerencia o ciclo completo de assistência animal:
- **Cadastro e Triagem de Pets:** Identificação do paciente (nome, raça, idade, tutor responsável e sinalização para cuidados pós-operatórios).
- **Prontuário e Histórico Clínico (`MedicalRecords`):** Registro cronológico de consultas, diagnósticos veterinários, procedimentos cirúrgicos e prescrições terapêuticas associadas ao animal (Relacionamento 1:N com integridade referencial).
- **Observabilidade Integrada:** Health Checks automatizados (`/health`, `/health/ready`, `/health/live`), métricas com OpenTelemetry e logging estruturado com Serilog.

---

## 2. Benefícios para o Negócio

1. **Centralização do Histórico Clínico do Paciente:** Elimina prontuários em papel e sistemas fragmentados, permitindo que a equipe veterinária consulte diagnósticos prévios e condutas terapêuticas em tempo real.
2. **Segurança no Pós-Operatório:** A flag `NeedsPostOpCare` viabiliza monitoramento prioritário para animais recém-operados, reduzindo o risco de intercorrências pós-cirúrgicas.
3. **Escalabilidade Serverless com Custos Otimizados:** A arquitetura em contêineres gerenciados (ACI) combinada a volumes persistentes (Azure Files) viabiliza alta disponibilidade com cobrança por segundo de uso, sem custos ociosos de máquinas virtuais.
4. **Segurança e Conformidade com Boas Práticas:** Isolamento com contêiner não-root (`USER $APP_UID`), eliminação completa de senhas no repositório e segredos protegidos pelo **Azure Key Vault**.

---

## 3. Arquitetura em Nuvem Azure

A arquitetura segue rigorosamente as diretrizes da disciplina DevOps Tools & Cloud Computing (Aula 12 e Arquitetura de Referência da FIAP):

```
       +-------------------------------------------------------------------+
       |                  1. AMBIENTE DE DESENVOLVIMENTO                   |
       |                                                                   |
       |    [ VS Code / Git ]                                              |
       |            |                                                      |
       |            +---> [ Docker Build Multi-Stage (Non-Root) ]          |
       |            |                                                      |
       |            +---> [ Docker Push ]                                  |
       +----------------------|--------------------------------------------+
                              |
                              v
       +-------------------------------------------------------------------+
       |                 2. MICROSOFT AZURE (AZURE CLI)                    |
       |                                                                   |
       |   +-----------------------------------------------------------+   |
       |   | Azure Container Registry (ACR)                            |   |
       |   | - pethealth-mysql:v1                                      |   |
       |   | - pethealth-api:v1                                        |   |
       |   +---------------------------|-------------------------------+   |
       |                               | Pull Imagem                       |
       |   +------------------------+  |  +----------------------------+   |
       |   | Azure Key Vault        |  |  | Storage Account            |   |
       |   | - Senhas DB / Conns    |  |  | - Azure File Share         |   |
       |   +-----------|------------+  |  +--------------|-------------+   |
       |               | Injeta        |                 | Volume Montado  |
       |               v               v                 v                 |
       |   +-----------------------------------------------------------+   |
       |   | Azure Container Instances (ACI)                           |   |
       |   |                                                           |   |
       |   |  +----------------------+     +------------------------+  |   |
       |   |  | Container: MySQL     |<--->| Container: .NET API    |  |   |
       |   |  | Porta 3306           |     | Porta 8080 (Non-root)  |  |   |
       |   |  | Volume /var/lib/mysql|     | ASPNETCORE_HTTP_PORTS  |  |   |
       |   |  +----------------------+     +-----------|------------+  |   |
       |   +-------------------------------------------|---------------+   |
       +-----------------------------------------------|-------------------+
                                                       |
                                                       v HTTP :8080
       +-------------------------------------------------------------------+
       |                   3. CLIENTE / AVALIADOR                          |
       |                                                                   |
       |        [ Navegador: Swagger UI / Health Checks / cURL ]           |
       +-------------------------------------------------------------------+
```

### Componentes Utilizados:
- **Azure Container Registry (ACR):** Armazena de forma privada as imagens da aplicação .NET 8 e do banco MySQL customizado.
- **Azure Container Instances (ACI):** Executa os contêineres sob demanda de forma serverless.
- **Azure Key Vault:** Gerencia e armazena com criptografia senhas, usuários e a string de conexão em tempo de execução.
- **Azure Storage Account & Azure Files:** Monta volume persistente CIFS no container MySQL (`/var/lib/mysql`), preservando os dados mesmo após reinicializações.

---

## 4. Modelagem do Banco de Dados (CORE)

O banco de dados relacional é estruturado em duas tabelas centrais com integridade referencial e deleção em cascata (`ON DELETE CASCADE`), definidas no arquivo [`script_bd.sql`](script_bd.sql):

1. **`PETS` (Tabela Pai - CORE):**
   - `Id` (INT, PK, Auto Increment)
   - `Name` (VARCHAR(100), NOT NULL)
   - `Breed` (VARCHAR(50), NOT NULL)
   - `Age` (INT, NOT NULL)
   - `TutorName` (VARCHAR(100), NOT NULL)
   - `NeedsPostOpCare` (BOOLEAN, NOT NULL)
   - `CreatedAt` (TIMESTAMP)

2. **`MEDICAL_RECORDS` (Tabela Filha - CORE, Relacionamento 1:N):**
   - `Id` (INT, PK, Auto Increment)
   - `PetId` (INT, FK referenciando `PETS(Id)`)
   - `Description` (VARCHAR(255), NOT NULL)
   - `Diagnosis` (VARCHAR(255))
   - `Treatment` (VARCHAR(255))
   - `VeterinarianName` (VARCHAR(100), NOT NULL)
   - `RecordDate` (DATETIME, NOT NULL)

---

## 5. Segurança e Conformidade de Containers

- **Usuário Sem Privilégios (Requisito 8.2 da Sprint):** O [`Dockerfile`](Dockerfile) utiliza a instrução `USER $APP_UID` da imagem oficial `mcr.microsoft.com/dotnet/aspnet:8.0`, executando sob o usuário `app` (UID 1654) e bloqueando privilégios administrativos.
- **Ausência de Credenciais no Código-Fonte:** [`appsettings.json`](src/PetHealthEcosystem.Api/appsettings.json) não possui senhas gravadas; as credenciais são injetadas estritamente em tempo de execução via Azure Key Vault e variáveis de ambiente (`ConnectionStrings__DefaultConnection`).

---

## 6. Guia de Execução Local

Para testar localmente via Docker Compose:

```bash
# 1. Copiar variáveis de ambiente de exemplo
cp .env.example .env

# 2. Definir senhas locais no arquivo .env (não commitado)

# 3. Subir a stack completa (MySQL + API .NET)
docker compose up -d --build

# 4. Acessar Swagger localmente
# http://localhost:8080/swagger
```

---

## 7. Guia de Deploy na Nuvem Azure (How-To Azure CLI)

### Opção A: Execução Automatizada via Script Mestre

Os scripts solicitam o RM, a região autorizada e as senhas do banco de forma segura via terminal:

```bash
# Autenticar na Azure
az login

# Executar deploy completo via Bash (Linux/macOS/Cloud Shell):
bash scripts/deploy_all.sh <SEU_RM> <SUA_REGIAO>
# Exemplo: bash scripts/deploy_all.sh 123456 eastus

# Ou no Windows via PowerShell:
.\scripts\deploy_all.ps1 -RM <SEU_RM> -Location <SUA_REGIAO>
```

---

### Opção B: Passo a Passo Manual com Azure CLI

#### 1. Definir Variáveis
```bash
RM="<SEU_RM>"
LOCATION="<SUA_REGIAO>" # Ex: eastus
RESOURCE_GROUP="rg-pethealth-rm${RM}"
STORAGE_ACCOUNT="storagerm${RM}"
FILE_SHARE="mysql-data-share"
KEY_VAULT="kv-pethealth-rm${RM}"
ACR_NAME="acrpethealthrm${RM}"
ACI_MYSQL="aci-mysql-rm${RM}"
ACI_API="aci-api-rm${RM}"
```

#### 2. Registrar Provedores e Criar Grupo de Recursos
```bash
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.ContainerInstance

az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
```

#### 3. Provisionar Storage Account e Volume do MySQL
```bash
az storage account create --resource-group "$RESOURCE_GROUP" --name "$STORAGE_ACCOUNT" --location "$LOCATION" --sku Standard_LRS

CONN_STR=$(az storage account show-connection-string --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" --query connectionString -o tsv)
az storage share create --name "$FILE_SHARE" --account-name "$STORAGE_ACCOUNT" --connection-string "$CONN_STR" --quota 5
```

#### 4. Criar Key Vault e Armazenar Credenciais com Segurança
```bash
az keyvault create --name "$KEY_VAULT" --resource-group "$RESOURCE_GROUP" --location "$LOCATION" --enable-rbac-authorization false

# Solicitar senhas no terminal de forma oculta
read -s -p "Senha ROOT do MySQL: " MYSQL_ROOT_PASS; echo ""
read -s -p "Senha do Usuario da App: " MYSQL_USER_PASS; echo ""

az keyvault secret set --vault-name "$KEY_VAULT" --name "mysql-database" --value "pethealth_db"
az keyvault secret set --vault-name "$KEY_VAULT" --name "mysql-user" --value "pethealth_user"
az keyvault secret set --vault-name "$KEY_VAULT" --name "mysql-password" --value "$MYSQL_USER_PASS"
az keyvault secret set --vault-name "$KEY_VAULT" --name "mysql-root-password" --value "$MYSQL_ROOT_PASS"
```

#### 5. Criar ACR e Publicar as Imagens
```bash
az acr create --resource-group "$RESOURCE_GROUP" --name "$ACR_NAME" --sku Basic --location "$LOCATION" --admin-enabled true

ACR_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)
ACR_USER=$(az acr credential show --name "$ACR_NAME" --query username -o tsv)
ACR_PASS=$(az acr credential show --name "$ACR_NAME" --query passwords[0].value -o tsv)

# Salvar credenciais do ACR no Key Vault
az keyvault secret set --vault-name "$KEY_VAULT" --name "acr-login-server" --value "$ACR_SERVER"
az keyvault secret set --vault-name "$KEY_VAULT" --name "acr-username" --value "$ACR_USER"
az keyvault secret set --vault-name "$KEY_VAULT" --name "acr-password" --value "$ACR_PASS"

# Build das imagens diretamente na nuvem (Cloud Build):
az acr build --registry "$ACR_NAME" --image "pethealth-mysql:v1" --file database/Dockerfile.mysql database/
az acr build --registry "$ACR_NAME" --image "pethealth-api:v1" --file Dockerfile .
```

#### 6. Provisionar o Banco de Dados MySQL no ACI
```bash
STORAGE_KEY=$(az storage account keys list --resource-group "$RESOURCE_GROUP" --account-name "$STORAGE_ACCOUNT" --query "[0].value" -o tsv)

az container create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACI_MYSQL" \
  --location "$LOCATION" \
  --image "$ACR_SERVER/pethealth-mysql:v1" \
  --cpu 1 --memory 1.5 \
  --os-type Linux \
  --dns-name-label "mysql-rm${RM}" \
  --ports 3306 \
  --registry-login-server "$ACR_SERVER" \
  --registry-username "$ACR_USER" \
  --registry-password "$ACR_PASS" \
  --azure-file-volume-account-name "$STORAGE_ACCOUNT" \
  --azure-file-volume-account-key "$STORAGE_KEY" \
  --azure-file-volume-share-name "$FILE_SHARE" \
  --azure-file-volume-mount-path "/var/lib/mysql" \
  --environment-variables \
    MYSQL_DATABASE="pethealth_db" \
    MYSQL_USER="pethealth_user" \
    MYSQL_PASSWORD="$MYSQL_USER_PASS" \
    MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASS" \
  --restart-policy Always
```

#### 7. Provisionar a Aplicação .NET no ACI
```bash
MYSQL_FQDN=$(az container show --resource-group "$RESOURCE_GROUP" --name "$ACI_MYSQL" --query ipAddress.fqdn -o tsv)
CONN_STRING="Server=${MYSQL_FQDN};Port=3306;Database=pethealth_db;User=pethealth_user;Password=${MYSQL_USER_PASS};"

az keyvault secret set --vault-name "$KEY_VAULT" --name "connection-string" --value "$CONN_STRING"

az container create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACI_API" \
  --location "$LOCATION" \
  --image "$ACR_SERVER/pethealth-api:v1" \
  --cpu 1 --memory 1 \
  --os-type Linux \
  --dns-name-label "api-rm${RM}" \
  --ports 8080 \
  --registry-login-server "$ACR_SERVER" \
  --registry-username "$ACR_USER" \
  --registry-password "$ACR_PASS" \
  --environment-variables \
    ConnectionStrings__DefaultConnection="$CONN_STRING" \
    ASPNETCORE_ENVIRONMENT="Development" \
  --restart-policy Always
```

---

## 8. Roteiro de Validação do CRUD e Persistência

Obtenha o endereço FQDN da API:
```bash
API_URL=$(az container show --resource-group "rg-pethealth-rm${RM}" --name "aci-api-rm${RM}" --query ipAddress.fqdn -o tsv)
echo "Swagger: http://${API_URL}:8080/swagger"
```

### Operações CRUD via `curl`:

#### 1. Consulta Inicial (READ)
```bash
curl -X GET "http://${API_URL}:8080/api/pets"
curl -X GET "http://${API_URL}:8080/api/medicalrecords"
```

#### 2. Inserção (CREATE)
```bash
# Inserir Pet:
curl -X POST "http://${API_URL}:8080/api/pets" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Bob",
    "breed": "Beagle",
    "age": 3,
    "tutorName": "Carla Dias",
    "needsPostOpCare": false
  }'

# Inserir Prontuário para o Pet criado:
curl -X POST "http://${API_URL}:8080/api/medicalrecords" \
  -H "Content-Type: application/json" \
  -d '{
    "petId": 3,
    "description": "Exame oftalmológico e limpeza auricular",
    "diagnosis": "Leve conjuntivite alérgica",
    "treatment": "Colírio anti-inflamatório 2 gotas a cada 12 horas",
    "veterinarianName": "Dra. Paula Rocha - CRMV/SP 55210"
  }'
```

#### 3. Atualização (UPDATE)
```bash
curl -X PUT "http://${API_URL}:8080/api/pets/3" \
  -H "Content-Type: application/json" \
  -d '{
    "id": 3,
    "name": "Bob Atualizado",
    "breed": "Beagle",
    "age": 4,
    "tutorName": "Carla Dias",
    "needsPostOpCare": true
  }'
```

#### 4. Exclusão (DELETE)
```bash
curl -X DELETE "http://${API_URL}:8080/api/pets/3"
```

#### 5. Evidência no Banco de Dados via SELECT
Conecte diretamente no container do MySQL:
```bash
az container exec \
  --resource-group "rg-pethealth-rm${RM}" \
  --name "aci-mysql-rm${RM}" \
  --exec-command "mysql -upethealth_user -p<SUA_SENHA> pethealth_db -e 'SELECT * FROM PETS; SELECT * FROM MEDICAL_RECORDS;'"
```

---

## 9. Destruição de Recursos (FinOps)

Ao concluir os testes e gravação do vídeo, execute o script de limpeza:

```bash
bash scripts/05_cleanup.sh <SEU_RM>
```
Ou via Azure CLI direto:
```bash
az group delete --name "rg-pethealth-rm<SEU_RM>" --yes --no-wait
```
