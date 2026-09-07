using PetHealthEcosystem.Api.Models;

namespace PetHealthEcosystem.Api.Domain.Interfaces
{
    public interface IMedicalRecordRepository
    {
        Task<IEnumerable<MedicalRecord>> GetAllAsync();
        Task<MedicalRecord?> GetByIdAsync(int id);
        Task<IEnumerable<MedicalRecord>> GetByPetIdAsync(int petId);
        Task<MedicalRecord> AddAsync(MedicalRecord record);
        Task UpdateAsync(MedicalRecord record);
        Task DeleteAsync(MedicalRecord record);
    }
}
