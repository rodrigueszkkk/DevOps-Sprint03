using System.Text.Json.Serialization;

namespace PetHealthEcosystem.Api.Models
{
    /// <summary>
    /// Representa o prontuário / registro médico de atendimento de um Pet.
    /// Tabela CORE relacionada 1:N com PETS.
    /// </summary>
    public class MedicalRecord
    {
        public int Id { get; set; }

        /// <summary>
        /// Chave estrangeira referenciando o Pet atendido.
        /// </summary>
        public int PetId { get; set; }

        /// <summary>
        /// Descrição do procedimento ou motivo da consulta.
        /// </summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>
        /// Diagnóstico clínico veterinário.
        /// </summary>
        public string Diagnosis { get; set; } = string.Empty;

        /// <summary>
        /// Prescrição médica ou tratamento indicado.
        /// </summary>
        public string Treatment { get; set; } = string.Empty;

        /// <summary>
        /// Nome e CRMV do médico veterinário responsável.
        /// </summary>
        public string VeterinarianName { get; set; } = string.Empty;

        /// <summary>
        /// Data e hora do atendimento médico.
        /// </summary>
        public DateTime RecordDate { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Propriedade de navegação para a entidade Pet.
        /// </summary>
        [JsonIgnore]
        public Pet? Pet { get; set; }
    }
}
