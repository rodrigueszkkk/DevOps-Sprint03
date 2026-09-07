using PetHealthEcosystem.Api.Models;

namespace PetHealthEcosystem.Api.Domain.Interfaces
{
    public interface IPetRepository
    {
        Task<IEnumerable<Pet>> GetAllAsync();
        Task<Pet?> GetByIdAsync(int id);
        Task<IEnumerable<Pet>> GetByBreedAsync(string breed);
        Task<IEnumerable<Pet>> GetByPostOpCareAsync(bool needsCare);
        Task<IEnumerable<Pet>> GetByTutorAsync(string tutorName);
        Task AddAsync(Pet pet);
        Task UpdateAsync(Pet pet);
        Task DeleteAsync(Pet pet);
        Task<bool> ExistsAsync(int id);
        Task SaveChangesAsync();
    }
}
