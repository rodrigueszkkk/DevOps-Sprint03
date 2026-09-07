# Roteiro Completo de Gravação do Vídeo Demonstrativo (Até 80 Pontos)

> **Regras Oficiais da Sprint:**
> - Resolução mínima: 720p.
> - Áudio claro com explicação falada (não usar apenas legendas).
> - **Obrigatório começar os testes clonando o repositório do GitHub.**
> - **Sem cortes** durante a demonstração das operações do CRUD e da persistência de dados.
> - Evidenciar cada operação do CRUD com `SELECT` diretamente no banco de dados na nuvem.

---

## ⏱️ Duração Sugerida: 8 a 15 minutos

---

## Checklist de Pré-Gravação

1. [ ] Microfone testado e áudio nítido.
2. [ ] Navegador aberto em abas limpas:
   - Portal Azure (`portal.azure.com`).
   - Repositório GitHub: `https://github.com/rodrigueszkkk/DevOps-Sprint03`.
3. [ ] Terminal limpo (PowerShell ou Bash) com Azure CLI configurado (`az login`).
4. [ ] DBeaver, MySQL Workbench ou terminal pronto para conectar no MySQL da Azure.

---

## Passo a Passo Sequencial do Vídeo

### 1. Abertura e Identificação (30 segundos)
- **Fala:** *"Olá, sou [Seu Nome], RM 561760. Esta é a apresentação da 3ª Sprint da disciplina DevOps Tools & Cloud Computing na FIAP. A solução adotada é a Opção 1: ACR + ACI, com arquitetura 100% containerizada na nuvem Microsoft Azure para a aplicação .NET 8 PetHealthEcosystem e o banco de dados relacional MySQL com persistência em Azure File Share."*

---

### 2. Início Oficial dos Testes: Clone do GitHub (1 minuto)
- **Ação em tela:** Abrir o terminal em uma pasta vazia e executar o clone do repositório:
```bash
git clone https://github.com/rodrigueszkkk/DevOps-Sprint03.git
cd DevOps-Sprint03
```
- **Fala:** *"Conforme exigido pelos critérios de avaliação, iniciamos a demonstração clonando o código diretamente do repositório oficial no GitHub."*

---

### 3. Apresentação Rápida dos Artefatos Obrigatórios (1 a 2 minutos)
- **Ação em tela:** Mostrar os arquivos no VS Code ou terminal:
  - `script_bd.sql`: Mostrar o DDL com as tabelas CORE (`PETS` e `MEDICAL_RECORDS`), chaves primárias, estrangeiras e comentários descritivos.
  - `Dockerfile`: Destacar o estágio multi-stage e **a linha `USER $APP_UID`**, frisando que o container roda sob usuário não-root (requisito obrigatório 8.2).
  - `appsettings.json`: Mostrar que as credenciais foram removidas do código-fonte (segurança contra vazamento de senhas).
  - Pasta `scripts/`: Mostrar os scripts de automação via Azure CLI.

---

### 4. Execução dos Scripts e Provisionamento na Azure (3 a 5 minutos)
- **Ação em tela:** Executar o script de provisionamento:
```bash
bash scripts/deploy_all.sh 561760 eastus
# Ou no Windows PowerShell:
# .\scripts\deploy_all.ps1 -RM 561760 -Location eastus
```
- **Fala explicativa enquanto os comandos rodam:**
  - *"O script está criando o Resource Group `rg-pethealth-rm561760` na região `eastus`."*
  - *"Criamos a Storage Account e o Azure File Share `mysql-data-share` para persistência física do banco de dados no ACI."*
  - *"Criamos o Azure Key Vault para armazenar todas as senhas e connection strings de forma segura."*
  - *"Criamos o Azure Container Registry (ACR), compilamos as imagens e realizamos o push."*
  - *"Provisionamos o container do MySQL no ACI montando o compartilhamento CIFS em `/var/lib/mysql`."*
  - *"Por fim, provisionamos o container da API .NET no ACI, recebendo a connection string dinamicamente via variável de ambiente."*
- **Ação no Portal Azure:** Abrir o grupo de recursos no portal e mostrar todos os recursos criados via CLI.

---

### 5. Validação da Aplicação no Ar e Health Checks (1 minuto)
- **Ação em tela:** No navegador, abrir a URL fornecida pelo script:
  - `http://api-rm561760.eastus.azurecontainer.io:8080/swagger`
  - `http://api-rm561760.eastus.azurecontainer.io:8080/health`
- **Fala:** *"A aplicação está no ar no Azure Container Instances. O endpoint de `/health` retorna status 'Healthy' confirmando a comunicação ativa entre a API e o banco MySQL na nuvem."*

---

### 6. Demonstração do CRUD com Evidência em Banco via SELECT (SEM CORTES) (4 a 6 minutos)

> ⚠️ **ATENÇÃO:** Mantenha a gravação contínua nesta etapa!
> Conecte no MySQL do ACI usando o terminal (`az container exec`) ou via client MySQL:
> ```bash
> az container exec --resource-group rg-pethealth-rm561760 --name aci-mysql-rm561760 --exec-command "mysql -upethealth_user -pPetHealthPass@2026 pethealth_db"
> ```

#### A) Leitura Inicial (READ)
- Executar no banco:
  ```sql
  SELECT * FROM PETS;
  SELECT * FROM MEDICAL_RECORDS;
  ```
- **Fala:** *"Vemos os registros iniciais já carregados pelo script DDL (Thor e Luna, com seus respectivos prontuários)."*

#### B) Inclusão de Novo Registro (CREATE)
- No Swagger ou via `curl`:
  ```bash
  curl -X POST "http://api-rm561760.eastus.azurecontainer.io:8080/api/pets" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "Max",
      "breed": "Pastor Alemão",
      "age": 3,
      "tutorName": "Fernanda Lima",
      "needsPostOpCare": false
    }'
  ```
- **Evidência no Banco:**
  ```sql
  SELECT * FROM PETS WHERE Name = 'Max';
  ```
- Inserir prontuário para o Pet criado (ID 3):
  ```bash
  curl -X POST "http://api-rm561760.eastus.azurecontainer.io:8080/api/medicalrecords" \
    -H "Content-Type: application/json" \
    -d '{
      "petId": 3,
      "description": "Vacinação preventiva anual",
      "diagnosis": "Animal saudável",
      "treatment": "Vacina V10 e antirrábica",
      "veterinarianName": "Dra. Paula Rocha - CRMV 55210"
    }'
  ```
- **Evidência no Banco:**
  ```sql
  SELECT * FROM MEDICAL_RECORDS WHERE PetId = 3;
  ```

#### C) Atualização de Registro (UPDATE)
- Alterar dados do Pet (ID 3):
  ```bash
  curl -X PUT "http://api-rm561760.eastus.azurecontainer.io:8080/api/pets/3" \
    -H "Content-Type: application/json" \
    -d '{
      "id": 3,
      "name": "Max Atualizado",
      "breed": "Pastor Alemão",
      "age": 4,
      "tutorName": "Fernanda Lima",
      "needsPostOpCare": true
    }'
  ```
- **Evidência no Banco:**
  ```sql
  SELECT Id, Name, Age, NeedsPostOpCare FROM PETS WHERE Id = 3;
  ```
- **Fala:** *"O registro foi atualizado com sucesso na nuvem, com alteração de idade para 4 e indicação de cuidado pós-operatório."*

#### D) Exclusão de Registro (DELETE)
- Excluir o Pet criado (ID 3):
  ```bash
  curl -X DELETE "http://api-rm561760.eastus.azurecontainer.io:8080/api/pets/3"
  ```
- **Evidência no Banco:**
  ```sql
  SELECT * FROM PETS WHERE Id = 3;
  SELECT * FROM MEDICAL_RECORDS WHERE PetId = 3;
  ```
- **Fala:** *"O Pet foi removido e, graças ao cascade delete configurado no DDL, seus prontuários vinculados também foram removidos com integridade referencial."*

---

### 7. Encerramento (30 segundos)
- **Fala:** *"Demonstramos com sucesso a esteira completa na Azure: provisionamento 100% via Azure CLI, containerização com ACR e ACI, banco de dados MySQL com volume persistente, execução sem privilégios administrativos e validação de todas as operações de CRUD em tabelas CORE diretamente no banco. Obrigado!"*
- Executar limpeza caso queira mostrar o comando FinOps:
  ```bash
  # bash scripts/05_cleanup.sh 561760
  ```
