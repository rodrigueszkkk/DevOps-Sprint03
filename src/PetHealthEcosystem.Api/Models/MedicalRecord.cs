using System.Text.Json.Serialization;

namespace PetHealthEcosystem.Api.Models
{
    public class MedicalRecord
    {
        public int Id { get; set; }
        public int PetId { get; set; }
        public string Description { get; set; } = string.Empty;
        public string Diagnosis { get; set; } = string.Empty;
        public string Treatment { get; set; } = string.Empty;
        public string VeterinarianName { get; set; } = string.Empty;
        public DateTime RecordDate { get; set; } = DateTime.UtcNow;

        [JsonIgnore]
        public Pet? Pet { get; set; }
    }
}
