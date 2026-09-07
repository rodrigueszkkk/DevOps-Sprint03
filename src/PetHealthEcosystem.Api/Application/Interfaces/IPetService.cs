using PetHealthEcosystem.Api.Models;

namespace PetHealthEcosystem.Api.Application.Interfaces
{
    /// <summary>
    /// Camada de Aplicação: orquestra as regras de negócio e validação
    /// antes de delegar a persistência ao repositório (Domínio/Infraestrutura).
    /// </summary>
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
