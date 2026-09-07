CREATE DATABASE IF NOT EXISTS pethealth_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE pethealth_db;

CREATE TABLE IF NOT EXISTS PETS (
    Id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Identificador único sequencial do Pet (Chave Primária)',
    Name VARCHAR(100) NOT NULL COMMENT 'Nome de registro do animal',
    Breed VARCHAR(50) NOT NULL COMMENT 'Raça do animal (ex: Labrador, Siamês, SRD)',
    Age INT NOT NULL DEFAULT 0 COMMENT 'Idade do animal em anos',
    TutorName VARCHAR(100) NOT NULL COMMENT 'Nome completo do tutor/responsável pelo animal',
    NeedsPostOpCare BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Indicador se o pet necessita de acompanhamento pós-operatório especial',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Data e hora do registro inicial no sistema'
) ENGINE=InnoDB COMMENT='Tabela de cadastro e gestão de animais de estimação (CORE da solução)';

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

CREATE INDEX IDX_PETS_BREED ON PETS (Breed);
CREATE INDEX IDX_PETS_TUTOR ON PETS (TutorName);
CREATE INDEX IDX_MEDICAL_RECORDS_PETID ON MEDICAL_RECORDS (PetId);
CREATE INDEX IDX_MEDICAL_RECORDS_DATE ON MEDICAL_RECORDS (RecordDate);

INSERT INTO PETS (Id, Name, Breed, Age, TutorName, NeedsPostOpCare) 
VALUES 
    (1, 'Thor', 'Golden Retriever', 4, 'Lucas Albuquerque', TRUE),
    (2, 'Luna', 'Gato Siamês', 2, 'Mariana Oliveira', FALSE)
ON DUPLICATE KEY UPDATE Name=VALUES(Name);

INSERT INTO MEDICAL_RECORDS (Id, PetId, Description, Diagnosis, Treatment, VeterinarianName, RecordDate)
VALUES
    (1, 1, 'Cirurgia ortopédica de ligamento cruzado cranial', 'Ruptura parcial do ligamento cruzado em membro pélvico direito', 'Anti-inflamatório Meloxicam 0.1mg/kg por 7 dias, repouso absoluto e fisioterapia motora', 'Dr. Rafael Costa - CRMV/SP 38421', '2026-09-01 10:30:00'),
    (2, 2, 'Consulta de rotina anual, avaliação odontológica e profilaxia', 'Saúde geral excelente, presença discreta de tártaro nos molares superiores', 'Vacinação polivalente V4 felina, reforço de raiva e higiene bucal preventiva com pasta enzimática', 'Dra. Beatriz Mendes - CRMV/SP 49120', '2026-09-03 15:00:00')
ON DUPLICATE KEY UPDATE Description=VALUES(Description);
