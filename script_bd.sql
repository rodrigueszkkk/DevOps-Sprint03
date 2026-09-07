-- ==================================================================================
-- FIAP - DEVOPS TOOLS & CLOUD COMPUTING
-- SPRINT 3: ENTREGA DEVOPS & CLOUD COMPUTING NA AZURE
-- ALUNO / RM: RM561760
-- REPOSITÓRIO: https://github.com/rodrigueszkkk/DevOps-Sprint03.git
-- APLICAÇÃO: PetHealthEcosystem.Api (.NET 8)
-- ARQUITETURA: Solução Containerizada (ACR + ACI + MySQL + Azure Files Volume)
-- ==================================================================================
--
-- Descrição das Tabelas Core:
-- 1. PETS: Armazena o cadastro dos animais de estimação sob cuidados veterinários.
-- 2. MEDICAL_RECORDS: Registros médicos, consultas, diagnósticos e procedimentos (Relacionamento 1:N com PETS).
--
-- ==================================================================================

-- Criação da base de dados se não existir
CREATE DATABASE IF NOT EXISTS pethealth_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE pethealth_db;

-- ----------------------------------------------------------------------------------
-- 1. TABELA CORE: PETS
-- Armazena os dados dos animais pacientes da clínica.
-- ----------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS PETS (
    Id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único sequencial do Pet (Chave Primária)',
    Name VARCHAR(100) NOT NULL COMMENT 'Nome de registro do animal',
    Breed VARCHAR(50) NOT NULL COMMENT 'Raça do animal (ex: Labrador, Siamês, SRD)',
    Age INT NOT NULL DEFAULT 0 COMMENT 'Idade do animal em anos',
    TutorName VARCHAR(100) NOT NULL COMMENT 'Nome completo do tutor/responsável pelo animal',
    NeedsPostOpCare BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Indicador se o pet necessita de acompanhamento pós-operatório especial',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Data e hora do registro inicial no sistema'
) ENGINE=InnoDB COMMENT='Tabela de cadastro e gestão de animais de estimação (CORE da solução)';

-- ----------------------------------------------------------------------------------
-- 2. TABELA CORE RELACIONADA: MEDICAL_RECORDS
-- Armazena o histórico clínico, atendimentos e procedimentos veterinários de cada Pet.
-- Relacionamento: 1 Pet possui N Medical Records (1:N)
-- ----------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS MEDICAL_RECORDS (
    Id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único do prontuário/atendimento (Chave Primária)',
    PetId INT NOT NULL COMMENT 'Identificador do Pet atendido (Chave Estrangeira referenciando PETS.Id)',
    Description VARCHAR(255) NOT NULL COMMENT 'Descrição sumária da queixa principal ou motivo da consulta',
    Diagnosis VARCHAR(255) COMMENT 'Diagnóstico clínico emitido pelo médico veterinário',
    Treatment VARCHAR(255) COMMENT 'Tratamento prescrito, dosagens e conduta terapêutica',
    VeterinarianName VARCHAR(100) NOT NULL COMMENT 'Nome do profissional veterinário responsável e CRMV',
    RecordDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Data e horário em que o atendimento médico foi realizado',
    CONSTRAINT FK_MedicalRecords_Pets FOREIGN KEY (PetId) 
        REFERENCES PETS(Id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Tabela de prontuários clínicos veterinários vinculados a cada Pet (CORE da solução)';

-- ----------------------------------------------------------------------------------
-- 3. ÍNDICES DE PERFORMANCE E PESQUISA
-- ----------------------------------------------------------------------------------
CREATE INDEX IDX_PETS_BREED ON PETS (Breed);
CREATE INDEX IDX_PETS_TUTOR ON PETS (TutorName);
CREATE INDEX IDX_MEDICAL_RECORDS_PETID ON MEDICAL_RECORDS (PetId);
CREATE INDEX IDX_MEDICAL_RECORDS_DATE ON MEDICAL_RECORDS (RecordDate);

-- ----------------------------------------------------------------------------------
-- 4. CARGA INICIAL (SEED DATA): Pelo menos 2 registros significativos em cada tabela
-- Requisito da Sprint: "Inserir e manipular pelo menos 2 linhas com conteúdo significativo nessas tabelas"
-- ----------------------------------------------------------------------------------

-- Inserção de Pets iniciais
INSERT INTO PETS (Id, Name, Breed, Age, TutorName, NeedsPostOpCare) 
VALUES 
    (1, 'Thor', 'Golden Retriever', 4, 'Lucas Albuquerque', TRUE),
    (2, 'Luna', 'Gato Siamês', 2, 'Mariana Oliveira', FALSE)
ON DUPLICATE KEY UPDATE Name=VALUES(Name);

-- Inserção de Prontuários/Consultas vinculados aos Pets
INSERT INTO MEDICAL_RECORDS (Id, PetId, Description, Diagnosis, Treatment, VeterinarianName, RecordDate)
VALUES
    (1, 1, 'Cirurgia ortopédica de ligamento cruzado cranial', 'Ruptura parcial do ligamento cruzado em membro pélvico direito', 'Anti-inflamatório Meloxicam 0.1mg/kg por 7 dias, repouso absoluto e fisioterapia motora', 'Dr. Rafael Costa - CRMV/SP 38421', '2026-09-01 10:30:00'),
    (2, 2, 'Consulta de rotina anual, avaliação odontológica e profilaxia', 'Saúde geral excelente, presença discreta de tártaro nos molares superiores', 'Vacinação polivalente V4 felina, reforço de raiva e higiene bucal preventiva com pasta enzimática', 'Dra. Beatriz Mendes - CRMV/SP 49120', '2026-09-03 15:00:00')
ON DUPLICATE KEY UPDATE Description=VALUES(Description);

-- ----------------------------------------------------------------------------------
-- 5. QUERIES DE VALIDAÇÃO (Utilizadas na demonstração do vídeo da Sprint)
-- ----------------------------------------------------------------------------------
-- Consulta geral de Pets:
-- SELECT * FROM PETS;

-- Consulta geral de Registros Médicos com JOIN no Pet:
-- SELECT m.Id, p.Name AS PetNome, p.Breed, m.Description, m.Diagnosis, m.VeterinarianName, m.RecordDate
-- FROM MEDICAL_RECORDS m
-- INNER JOIN PETS p ON m.PetId = p.Id;
