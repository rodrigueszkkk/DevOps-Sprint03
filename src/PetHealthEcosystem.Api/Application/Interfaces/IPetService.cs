using PetHealthEcosystem.Api.Models;

namespace PetHealthEcosystem.Api.Application.Interfaces
{
    public interface IPetService
    {
        Task<IEnumerable<Pet>> GetAllAsync();
        Task<Pet?> GetByIdAsync(int id);
        Task<IEnumerable<Pet>> GetByBreedAsync(string breed);
        Task<IEnumerable<Pet>> GetByPostOpCareAsync(bool needsCare);
        Task<IEnumerable<Pet>> GetByTutorAsync(string tutorName);
        Task<(bool Success, string? Error, Pet? Pet)> CreateAsync(Pet pet);
        Task<(bool Success, string? Error)> UpdateAsync(int id, Pet pet);
        Task<bool> DeleteAsync(int id);
    }
}
