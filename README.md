# PetHealthEcosystem - DevOps & Cloud Computing (FIAP - Sprint 3)

[![.NET 8](https://img.shields.io/badge/.NET-8.0-blue.svg)](https://dotnet.microsoft.com/)
[![Azure ACI](https://img.shields.io/badge/Azure-Container%20Instances-0078D4.svg)](https://azure.microsoft.com/services/container-instances/)
[![Azure ACR](https://img.shields.io/badge/Azure-Container%20Registry-0078D4.svg)](https://azure.microsoft.com/services/container-registry/)
[![MySQL 8.0](https://img.shields.io/badge/MySQL-8.0-orange.svg)](https://www.mysql.com/)

Repositório acadêmico desenvolvido para a **3ª Sprint da disciplina DevOps Tools & Cloud Computing** na FIAP. A solução aborda a conteinerização, automação de infraestrutura via **Azure CLI** e publicação em nuvem Microsoft Azure do ecossistema de saúde veterinária **PetHealthEcosystem**, utilizando a **Opção 1: ACR + ACI**.

---

## 👥 Identificação do Aluno / Grupo

- **Nome Completo:** [Nome do Integrante] | **RM:** 561760
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

O **PetHealthEcosystem** é uma API RESTful de alta performance desenvolvida em **ASP.NET Core (.NET 8)** voltada à gestão clínica e operacional de pacientes em hospitais e clínicas veterinárias.

A plataforma gerencia o ciclo completo de assistência animal:
- **Cadastro e Triagem de Pets:** Identificação do paciente (nome, raça, idade, tutor responsável e sinalização para cuidados pós-operatórios).
- **Prontuário e Histórico Clínico (`MedicalRecords`):** Registro cronológico de consultas, diagnósticos veterinários, procedimentos cirúrgicos e prescrições terapêuticas associadas ao animal.
- **Observabilidade Integrada:** Health Checks automatizados (`/health`, `/health/ready`, `/health/live`), métricas com OpenTelemetry e logging estruturado com Serilog.

---

## 2. Benefícios para o Negócio

1. **Centralização do Histórico Clínico do Paciente:** Elimina prontuários em papel e sistemas legados fragmentados, garantindo que qualquer profissional veterinário da equipe tenha acesso imediato a cirurgias prévias e alergias do animal.
2. **Segurança no Pós-Operatório:** A sinalização automática de `NeedsPostOpCare` viabiliza monitoramento prioritário para animais recém-operados, reduzindo drasticamente intercorrências pós-cirúrgicas.
3. **Alta Disponibilidade e Escalabilidade em Nuvem:** A execução em Azure Container Instances (ACI) combinada a persistência em Azure File Share permite provisionamento sob demanda com custos reduzidos (Serverless Containers).
4. **Conformidade com LGPD e Segurança Operacional:** Armazenamento seguro de credenciais em Azure Key Vault, eliminando segredos no código-fonte e garantindo isolamento através de contêineres sem privilégios administrativos (`non-root`).

---

## 3. Arquitetura em Nuvem Azure

A arquitetura foi desenhada em conformidade estrita com as diretrizes da disciplina DevOps Tools & Cloud Computing (Aula 12 e Arquitetura de Referência da FIAP):

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
- **Azure Container Registry (ACR):** Armazena com segurança as imagens Docker da aplicação .NET 8 e do banco MySQL customizado.
- **Azure Container Instances (ACI):** Executa os contêineres sob demanda sem necessidade de gerenciar VMs ou clusters Kubernetes.
- **Azure Key Vault:** Centraliza todas as senhas de banco, usuários e connection strings com controle de acesso RBAC.
- **Azure Storage Account & Azure Files:** Monta volume persistente em CIFS no contêiner MySQL (`/var/lib/mysql`), garantindo que reinicializações do contêiner não causem perda de dados.

---

## 4. Modelagem do Banco de Dados (CORE)

O banco de dados relacional é estruturado em duas tabelas centrais com integridade referencial e deleção em cascata (`ON DELETE CASCADE`), definidas no arquivo [`script_bd.sql`](script_bd.sql):

1. **`PETS` (Tabela Pai):**
   - `Id` (INT, PK, Auto Increment)
   - `Name` (VARCHAR(100), NOT NULL)
   - `Breed` (VARCHAR(50), NOT NULL)
   - `Age` (INT, NOT NULL)
   - `TutorName` (VARCHAR(100), NOT NULL)
   - `NeedsPostOpCare` (BOOLEAN, NOT NULL)
   - `CreatedAt` (TIMESTAMP)

2. **`MEDICAL_RECORDS` (Tabela Filha - Relacionamento 1:N):**
   - `Id` (INT, PK, Auto Increment)
   - `PetId` (INT, FK referenciando `PETS(Id)`)
   - `Description` (VARCHAR(255), NOT NULL)
   - `Diagnosis` (VARCHAR(255))
   - `Treatment` (VARCHAR(255))
   - `VeterinarianName` (VARCHAR(100), NOT NULL)
   - `RecordDate` (DATETIME, NOT NULL)

---

## 5. Segurança e Conformidade de Containers

- **Usuário Sem Privilégios (Requisito 8.2 da Sprint):** O [`Dockerfile`](Dockerfile) utiliza a instrução `USER $APP_UID` da imagem oficial `mcr.microsoft.com/dotnet/aspnet:8.0`, executando sob o usuário `app` (UID 1654) e impedindo qualquer escalonamento de privilégios como root.
- **Ausência de Credenciais no Código:** [`appsettings.json`](src/PetHealthEcosystem.Api/appsettings.json) não possui senhas hardcoded; as credenciais são injetadas exclusivamente em tempo de execução via Azure Key Vault e variáveis de ambiente (`ConnectionStrings__DefaultConnection`).

---

## 6. Guia de Execução Local

Para testar a solução completa localmente via Docker Compose:

```bash
# 1. Subir a stack completa (MySQL + API .NET)
docker compose up -d --build

# 2. Verificar status dos containers
docker compose ps

# 3. Acessar Swagger localmente
# Abra no navegador: http://localhost:8080/swagger
```

---

## 7. Guia de Deploy na Nuvem Azure (How-To Azure CLI)

> **Região Padrão:** `eastus` (ou outra autorizada pela sua política: `mexicocentral`, `canadacentral`, `centralus`, `southafricanorth`).  
> **RM:** `561760`

### Opção A: Execução Automatizada via Script Mestre

```bash
# Autenticar na Azure
az login

# Executar deploy completo via Bash:
bash scripts/deploy_all.sh 561760 eastus

# Ou no Windows via PowerShell:
.\scripts\deploy_all.ps1 -RM 561760 -Location eastus
```

---

### Opção B: Passo a Passo Manual com Azure CLI

#### 1. Definir Variáveis de Ambiente
```bash
RM="561760"
LOCATION="eastus"
RESOURCE_GROUP="rg-pethealth-rm${RM}"
STORAGE_ACCOUNT="storagerm${RM}"
FILE_SHARE="mysql-data-share"
KEY_VAULT="kv-pethealth-rm${RM}"
ACR_NAME="acrpethealthrm${RM}"
ACI_MYSQL="aci-mysql-rm${RM}"
ACI_API="aci-api-rm${RM}"
```

#### 2. Criar Grupo de Recursos e Provedores
```bash
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.ContainerInstance

az group create --name $RESOURCE_GROUP --location $LOCATION
```

#### 3. Provisionar Storage Account e Volume do MySQL
```bash
az storage account create --resource-group $RESOURCE_GROUP --name $STORAGE_ACCOUNT --location $LOCATION --sku Standard_LRS

CONN_STR=$(az storage account show-connection-string --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --query connectionString -o tsv)
az storage share create --name $FILE_SHARE --account-name $STORAGE_ACCOUNT --connection-string "$CONN_STR" --quota 5
```

#### 4. Criar Key Vault e Armazenar Credenciais
```bash
az keyvault create --name $KEY_VAULT --resource-group $RESOURCE_GROUP --location $LOCATION --enable-rbac-authorization false

az keyvault secret set --vault-name $KEY_VAULT --name "mysql-database" --value "pethealth_db"
az keyvault secret set --vault-name $KEY_VAULT --name "mysql-user" --value "pethealth_user"
az keyvault secret set --vault-name $KEY_VAULT --name "mysql-password" --value "PetHealthPass@2026"
az keyvault secret set --vault-name $KEY_VAULT --name "mysql-root-password" --value "PetHealth@2026"
```

#### 5. Criar ACR e Publicar as Imagens
```bash
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --location $LOCATION --admin-enabled true

ACR_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)
ACR_USER=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASS=$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)

# Build das imagens diretamente na Azure (Cloud Build):
az acr build --registry $ACR_NAME --image "pethealth-mysql:v1" --file database/Dockerfile.mysql database/
az acr build --registry $ACR_NAME --image "pethealth-api:v1" --file Dockerfile .
```

#### 6. Provisionar o Banco de Dados MySQL no ACI
```bash
STORAGE_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --query "[0].value" -o tsv)

az container create \
  --resource-group $RESOURCE_GROUP \
  --name $ACI_MYSQL \
  --location $LOCATION \
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
    MYSQL_PASSWORD="PetHealthPass@2026" \
    MYSQL_ROOT_PASSWORD="PetHealth@2026" \
  --restart-policy Always
```

#### 7. Provisionar a Aplicação .NET no ACI
```bash
MYSQL_FQDN=$(az container show --resource-group $RESOURCE_GROUP --name $ACI_MYSQL --query ipAddress.fqdn -o tsv)
CONN_STRING="Server=${MYSQL_FQDN};Port=3306;Database=pethealth_db;User=pethealth_user;Password=PetHealthPass@2026;"

az container create \
  --resource-group $RESOURCE_GROUP \
  --name $ACI_API \
  --location $LOCATION \
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

Obtenha o FQDN público da API:
```bash
API_URL=$(az container show --resource-group "rg-pethealth-rm561760" --name "aci-api-rm561760" --query ipAddress.fqdn -o tsv)
echo "API no ar em: http://${API_URL}:8080"
```

Acesse o Swagger no navegador:  
👉 **`http://<FQDN_DA_API>:8080/swagger`**

### Operações CRUD via terminal (`curl`):

#### 1. Consulta Inicial (READ)
```bash
curl -X GET "http://${API_URL}:8080/api/pets"
curl -X GET "http://${API_URL}:8080/api/medicalrecords"
```

#### 2. Inserção (CREATE)
```bash
# Inserir novo Pet:
curl -X POST "http://${API_URL}:8080/api/pets" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Bob",
    "breed": "Beagle",
    "age": 3,
    "tutorName": "Carla Dias",
    "needsPostOpCare": false
  }'

# Inserir Prontuário para o Pet (ID 3):
curl -X POST "http://${API_URL}:8080/api/medicalrecords" \
  -H "Content-Type: application/json" \
  -d '{
    "petId": 3,
    "description": "Exame oftalmológico e limpeza auricular",
    "diagnosis": "Leve conjuntivite alérgica",
    "treatment": "Colírio anti-inflamatório 2 gotas a cada 12 horas por 5 dias",
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
Conecte no container do MySQL no ACI:
```bash
az container exec \
  --resource-group "rg-pethealth-rm561760" \
  --name "aci-mysql-rm561760" \
  --exec-command "mysql -upethealth_user -pPetHealthPass@2026 pethealth_db -e 'SELECT * FROM PETS; SELECT * FROM MEDICAL_RECORDS;'"
```

---

## 9. Destruição de Recursos (FinOps)

Ao concluir os testes e a gravação do vídeo, execute o script de limpeza para desalocar todos os recursos e evitar consumo desnecessário de créditos de assinatura:

```bash
bash scripts/05_cleanup.sh 561760
```
Ou via Azure CLI direto:
```bash
az group delete --name "rg-pethealth-rm561760" --yes --no-wait
```
