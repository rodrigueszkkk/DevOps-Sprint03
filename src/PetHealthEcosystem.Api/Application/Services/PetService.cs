using Microsoft.Extensions.Logging;
using PetHealthEcosystem.Api.Application.Interfaces;
using PetHealthEcosystem.Api.Domain.Interfaces;
using PetHealthEcosystem.Api.Models;

namespace PetHealthEcosystem.Api.Application.Services
{
    public class PetService : IPetService
    {
        private readonly IPetRepository _repository;
        private readonly ILogger<PetService> _logger;

        public PetService(IPetRepository repository, ILogger<PetService> logger)
        {
            _repository = repository;
            _logger = logger;
        }

        public async Task<IEnumerable<Pet>> GetAllAsync()
        {
            _logger.LogInformation("Buscando todos os pets cadastrados");
            return await _repository.GetAllAsync();
        }

        public async Task<Pet?> GetByIdAsync(int id) =>
            await _repository.GetByIdAsync(id);

        public async Task<IEnumerable<Pet>> GetByBreedAsync(string breed) =>
            await _repository.GetByBreedAsync(breed);

        public async Task<IEnumerable<Pet>> GetByPostOpCareAsync(bool needsCare) =>
            await _repository.GetByPostOpCareAsync(needsCare);

        public async Task<IEnumerable<Pet>> GetByTutorAsync(string tutorName) =>
            await _repository.GetByTutorAsync(tutorName);

        public async Task<(bool Success, string? Error, Pet? Pet)> CreateAsync(Pet pet)
        {
            var validationError = Validate(pet);
            if (validationError != null)
            {
                _logger.LogWarning("Falha de validação ao criar pet: {Erro}", validationError);
                return (false, validationError, null);
            }

            await _repository.AddAsync(pet);
            await _repository.SaveChangesAsync();

            _logger.LogInformation("Pet {PetId} criado com sucesso", pet.Id);
            return (true, null, pet);
        }

        public async Task<(bool Success, string? Error)> UpdateAsync(int id, Pet pet)
        {
            if (id != pet.Id)
                return (false, "ID incompatível.");

            var validationError = Validate(pet);
            if (validationError != null)
                return (false, validationError);

            var existente = await _repository.GetByIdAsync(id);
            if (existente == null)
                return (false, "Pet não encontrado.");

            existente.Name = pet.Name;
            existente.Breed = pet.Breed;
            existente.Age = pet.Age;
            existente.TutorName = pet.TutorName;
            existente.NeedsPostOpCare = pet.NeedsPostOpCare;

            await _repository.UpdateAsync(existente);
            await _repository.SaveChangesAsync();

            _logger.LogInformation("Pet {PetId} atualizado com sucesso", id);
            return (true, null);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var pet = await _repository.GetByIdAsync(id);
            if (pet == null) return false;

            await _repository.DeleteAsync(pet);
            await _repository.SaveChangesAsync();

            _logger.LogInformation("Pet {PetId} removido com sucesso", id);
            return true;
        }

        private static string? Validate(Pet? pet)
        {
            if (pet == null) return "Dados inválidos.";
            if (string.IsNullOrWhiteSpace(pet.Name)) return "O nome do pet é obrigatório.";
            if (pet.Age < 0) return "A idade do pet não pode ser negativa.";
            if (string.IsNullOrWhiteSpace(pet.TutorName)) return "O nome do tutor é obrigatório.";
            return null;
        }
    }
}
