# PetHealthEcosystem - DevOps & Cloud Computing (FIAP - Sprint 3)

[![.NET 8](https://img.shields.io/badge/.NET-8.0-blue.svg)](https://dotnet.microsoft.com/)
[![Azure ACI](https://img.shields.io/badge/Azure-Container%20Instances-0078D4.svg)](https://azure.microsoft.com/services/container-instances/)
[![Azure ACR](https://img.shields.io/badge/Azure-Container%20Registry-0078D4.svg)](https://azure.microsoft.com/services/container-registry/)
[![MySQL 8.0](https://img.shields.io/badge/MySQL-8.0-orange.svg)](https://www.mysql.com/)

Repositório acadêmico desenvolvido para a **3ª Sprint da disciplina DevOps Tools & Cloud Computing** na FIAP. A solução aborda a conteinerização, automação de infraestrutura via **Azure CLI** e publicação em nuvem Microsoft Azure do ecossistema de saúde veterinária **PetHealthEcosystem**, utilizando a **Opção 1: ACR + ACI**.

---

## 👥 Identificação do Aluno / Grupo

- **Nome Completo:** Kaiky Pereira | **RM:564578** | Leandro Guarido | **RM561760:** | Gabriel Solano | **RM562325:**
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
7. [Guia de Deploy na Nuvem Azure (How-To Definitivo do Zero)](#7-guia-de-deploy-na-nuvem-azure-how-to-definitivo-do-zero)
8. [Roteiro de Validação do CRUD, Swagger e Persistência](#8-roteiro-de-validação-do-crud-swagger-e-persistência)
9. [FinOps e Gestão de Recursos (Pausar ou Destruir)](#9-finops-e-gestão-de-recursos-pausar-ou-destruir)


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

## 7. Guia de Deploy na Nuvem Azure (How-To Definitivo do Zero)

O fluxo oficial foi projetado para execução no **Azure Cloud Shell (Bash)** ou terminal com **Azure CLI**, integrando-se com o **GitHub Actions** para a compilação e publicação automatizada dos contêineres no **Azure Container Registry (ACR)**.

---

### 7.1 Pré-requisitos e Clonagem do Repositório

1. Acesse o portal da Azure e abra o **Cloud Shell** (ícone `>_` no canto superior direito) escolhendo o ambiente **Bash**, ou utilize seu terminal local autenticado via:
   ```bash
   az login
   ```
2. Clone o repositório oficial da entrega:
   ```bash
   git clone https://github.com/rodrigueszkkk/DevOps-Sprint03.git
   cd DevOps-Sprint03
   ```

---

### 7.2 Etapa 1: Provisionamento da Infraestrutura Base

Execute o script de provisionamento passando seu RM e a região autorizada da Azure:

```bash
bash scripts/01_setup_infra.sh <SEU_RM> <SUA_REGIAO>
# Exemplo: bash scripts/01_setup_infra.sh 123456 eastus
```

**O que o script executa automaticamente:**
- Registra os Resource Providers necessários (`Microsoft.Storage`, `Microsoft.KeyVault`, `Microsoft.ContainerRegistry`, `Microsoft.ContainerInstance`).
- Cria o Resource Group `rg-pethealth-rm<RM>`.
- Cria a Storage Account `storagerm<RM>` e o Azure File Share persistente `mysql-data-share` (quota de 5 GB).
- Provisiona o Azure Key Vault `kv-pethealth-rm<RM>` e solicita de forma oculta no terminal as senhas de ROOT e do usuário da aplicação.
- Cria o Azure Container Registry (ACR) `acrpethealthrm<RM>` com credenciais de administrador habilitadas.
- Armazena todas as credenciais no Key Vault e exibe na tela os dados do ACR:
  ```
  ACR Name:     acrpethealthrm<RM>
  ACR Username: acrpethealthrm<RM>
  ACR Password: <SENHA_GERADA>
  ```

---

### 7.3 Etapa 2: Build e Publicação das Imagens no ACR via GitHub Actions

Como o Azure Cloud Shell opera em contêiner gerenciado sem o daemon do Docker, o build multi-stage das imagens é executado de forma rápida e automatizada na esteira do GitHub Actions:

1. Acesse seu repositório no GitHub: `https://github.com/rodrigueszkkk/DevOps-Sprint03`
2. Clique na aba **Actions**.
3. No menu lateral esquerdo, selecione o workflow **"Build and Push Containers to ACR"**.
4. Clique no botão **"Run workflow"** à direita e preencha os campos com os valores gerados na Etapa 1:
   - **Nome do ACR:** Informe o nome exibido (ex: `acrpethealthrm<RM>`).
   - **Usuário do ACR:** Informe o username exibido.
   - **Senha do ACR:** Informe o password exibido.
5. Clique em **"Run workflow"** (botão verde) e aguarde a conclusão (~2 minutos).
6. A esteira compilará as imagens e fará o push direto para o seu ACR:
   - `acrpethealthrm<RM>.azurecr.io/pethealth-mysql:v1`
   - `acrpethealthrm<RM>.azurecr.io/pethealth-api:v1`

> *(Opcional: Caso esteja executando em uma máquina local com Docker instalado e ativo, você pode executar alternativamente `bash scripts/02_build_push_acr.sh <SEU_RM> <SUA_REGIAO>`)*.

---

### 7.4 Etapa 3: Deploy do Banco de Dados MySQL no ACI

Com as imagens disponíveis no ACR, retorne ao Cloud Shell e execute:

```bash
bash scripts/03_deploy_mysql_aci.sh <SEU_RM> <SUA_REGIAO>
```

**O que o script executa automaticamente:**
- Recupera as chaves do Storage Account e as credenciais do ACR diretamente do Key Vault.
- Provisiona o contêiner `aci-mysql-rm<RM>` no Azure Container Instances (porta 3306, 1 vCPU, 1.5 GB de RAM).
- Monta o volume persistente do Azure Files em `/var/lib/mysql`.
- Executa o script de inicialização (`script_bd.sql`) populando as tabelas `PETS` e `MEDICAL_RECORDS`.
- Registra o FQDN público gerado no Key Vault e exibe ao final:
  ```
  MySQL ACI FQDN: mysql-rm<RM>.<regiao>.azurecontainer.io
  ```

---

### 7.5 Etapa 4: Deploy da Aplicação .NET 8 no ACI

No Cloud Shell, execute a etapa final para disponibilizar a API pública:

```bash
bash scripts/04_deploy_api_aci.sh <SEU_RM> <SUA_REGIAO>
```

**O que o script executa automaticamente:**
- Recupera o FQDN do MySQL do Key Vault e monta a connection string de produção.
- Grava o segredo `connection-string` de forma protegida no Azure Key Vault.
- Provisiona o contêiner `aci-api-rm<RM>` no Azure Container Instances (porta 8080, 1 vCPU, 1 GB de RAM, usuário `app` non-root).
- Injeta as variáveis de ambiente necessárias e aguarda a inicialização.
- Exibe os endpoints públicos ativos:
  ```
  URL Base:     http://api-rm<RM>.<regiao>.azurecontainer.io:8080
  Swagger UI:   http://api-rm<RM>.<regiao>.azurecontainer.io:8080/swagger
  Health Check: http://api-rm<RM>.<regiao>.azurecontainer.io:8080/health
  IP Público:   <IP_PUBLICO>
  ```

---

### 7.6 Script Automatizado Tudo-em-Um (Ambiente Local com Docker)

Caso possua Docker Desktop instalado localmente (Windows PowerShell ou Linux Bash), é possível executar o deploy do início ao fim com um único comando:

```bash
# Bash (Linux / macOS):
bash scripts/deploy_all.sh <SEU_RM> <SUA_REGIAO>

# PowerShell (Windows):
.\scripts\deploy_all.ps1 -RM <SEU_RM> -Location <SUA_REGIAO>
```

---

## 8. Roteiro de Validação do CRUD, Swagger e Persistência

### 8.1 Acesso via Navegador

Abra o navegador e acesse a documentação interativa Swagger no endereço retornado:
- **Swagger UI:** `http://api-rm<SEU_RM>.<SUA_REGIAO>.azurecontainer.io:8080/swagger`
- **Health Check:** `http://api-rm<SEU_RM>.<SUA_REGIAO>.azurecontainer.io:8080/health` (retorna HTTP 200 `Healthy`)

---

### 8.2 Validação das Operações CRUD (Swagger ou cURL)

Você pode testar diretamente pelos botões **"Try it out"** na interface do Swagger ou via terminal `curl`:

#### 1. Consulta Inicial (READ - GET)
```bash
API_URL="api-rm<SEU_RM>.<SUA_REGIAO>.azurecontainer.io"

curl -X GET "http://${API_URL}:8080/api/pets"
curl -X GET "http://${API_URL}:8080/api/medicalrecords"
```

#### 2. Inserção (CREATE - POST)
```bash
# Cadastrar novo Pet:
curl -X POST "http://${API_URL}:8080/api/pets" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Thor",
    "breed": "Golden Retriever",
    "age": 4,
    "tutorName": "Mariana Silva",
    "needsPostOpCare": true
  }'

# Cadastrar Prontuário para o Pet criado (ex: Id 3):
curl -X POST "http://${API_URL}:8080/api/medicalrecords" \
  -H "Content-Type: application/json" \
  -d '{
    "petId": 3,
    "description": "Consulta de rotina pós-cirúrgica",
    "diagnosis": "Boa cicatrização dos pontos",
    "treatment": "Manter repouso por mais 3 dias",
    "veterinarianName": "Dr. Fernando Costa - CRMV/SP 43210"
  }'
```

#### 3. Atualização (UPDATE - PUT)
```bash
curl -X PUT "http://${API_URL}:8080/api/pets/3" \
  -H "Content-Type: application/json" \
  -d '{
    "id": 3,
    "name": "Thor Atualizado",
    "breed": "Golden Retriever",
    "age": 5,
    "tutorName": "Mariana Silva",
    "needsPostOpCare": false
  }'
```

#### 4. Exclusão (DELETE)
```bash
curl -X DELETE "http://${API_URL}:8080/api/pets/3"
```

---

### 8.3 Evidência Direta no Banco de Dados (Sem Cortes)

Para comprovar que as operações realizadas no Swagger foram realmente persistidas no banco relacional, execute no Azure Cloud Shell:

```bash
az container exec \
  --resource-group "rg-pethealth-rm<SEU_RM>" \
  --name "aci-mysql-rm<SEU_RM>" \
  --exec-command "mysql -upethealth_user -p<SUA_SENHA> pethealth_db -e 'SELECT * FROM PETS; SELECT * FROM MEDICAL_RECORDS;'"
```

---

## 9. FinOps e Gestão de Recursos (Pausar ou Destruir)

Contêineres no Azure Container Instances (ACI) tarifam por segundo de CPU e memória alocados enquanto estiverem em execução.

### Pausar Contêineres (Sem perder dados do banco)
Durante pausas de estudo ou antes da gravação do vídeo, pause os contêineres para interromper o consumo de créditos:
```bash
az container stop --resource-group "rg-pethealth-rm<SEU_RM>" --name "aci-api-rm<SEU_RM>"
az container stop --resource-group "rg-pethealth-rm<SEU_RM>" --name "aci-mysql-rm<SEU_RM>"
```

Para reativar rapidamente o ambiente quando for apresentar ou gravar:
```bash
az container start --resource-group "rg-pethealth-rm<SEU_RM>" --name "aci-mysql-rm<SEU_RM>"
az container start --resource-group "rg-pethealth-rm<SEU_RM>" --name "aci-api-rm<SEU_RM>"
```
*(Os dados permanecem 100% salvos no volume persistente do Azure Files).*

---

### Destruição Total dos Recursos
Ao finalizar a entrega da Sprint e envio do vídeo, exclua todos os recursos criados para zerar quaisquer cobranças residuais:

```bash
bash scripts/05_cleanup.sh <SEU_RM>
```
Ou via Azure CLI direto:
```bash
az group delete --name "rg-pethealth-rm<SEU_RM>" --yes --no-wait
az keyvault purge --name "kv-pethealth-rm<SEU_RM>" --no-wait
```

