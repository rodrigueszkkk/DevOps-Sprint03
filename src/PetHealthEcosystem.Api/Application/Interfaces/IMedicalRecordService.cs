using PetHealthEcosystem.Api.Models;

namespace PetHealthEcosystem.Api.Application.Interfaces
{
    public interface IMedicalRecordService
    {
        Task<IEnumerable<MedicalRecord>> GetAllAsync();
        Task<MedicalRecord?> GetByIdAsync(int id);
        Task<IEnumerable<MedicalRecord>> GetByPetIdAsync(int petId);
        Task<(bool Success, string? Error, MedicalRecord? Created)> CreateAsync(MedicalRecord record);
        Task<(bool Success, string? Error)> UpdateAsync(int id, MedicalRecord record);
        Task<bool> DeleteAsync(int id);
    }
}
