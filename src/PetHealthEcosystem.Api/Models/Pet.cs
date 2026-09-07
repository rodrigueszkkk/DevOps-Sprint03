namespace PetHealthEcosystem.Api.Models
{
    public class Pet
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Breed { get; set; } = string.Empty;
        public int Age { get; set; }
        public string TutorName { get; set; } = string.Empty;
        public bool NeedsPostOpCare { get; set; }

        /// <summary>
        /// Histórico de prontuários / atendimentos médicos do Pet.
        /// </summary>
        public ICollection<MedicalRecord> MedicalRecords { get; set; } = new List<MedicalRecord>();
    }
}
