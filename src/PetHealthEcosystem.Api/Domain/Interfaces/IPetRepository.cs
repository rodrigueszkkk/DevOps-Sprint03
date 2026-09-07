using PetHealthEcosystem.Api.Models;

namespace PetHealthEcosystem.Api.Domain.Interfaces
{
    /// <summary>
    /// Contrato de acesso a dados para a entidade Pet.
    /// Faz parte da camada de Domínio: a Aplicação depende desta abstração,
    /// nunca da implementação concreta em Infrastructure.
    /// </summary>
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
