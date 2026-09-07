using PetHealthEcosystem.Api.Application.Interfaces;
using PetHealthEcosystem.Api.Domain.Interfaces;
using PetHealthEcosystem.Api.Models;

namespace PetHealthEcosystem.Api.Application.Services
{
    public class MedicalRecordService : IMedicalRecordService
    {
        private readonly IMedicalRecordRepository _recordRepository;
        private readonly IPetRepository _petRepository;

        public MedicalRecordService(IMedicalRecordRepository recordRepository, IPetRepository petRepository)
        {
            _recordRepository = recordRepository;
            _petRepository = petRepository;
        }

        public async Task<IEnumerable<MedicalRecord>> GetAllAsync()
        {
            return await _recordRepository.GetAllAsync();
        }

        public async Task<MedicalRecord?> GetByIdAsync(int id)
        {
            return await _recordRepository.GetByIdAsync(id);
        }

        public async Task<IEnumerable<MedicalRecord>> GetByPetIdAsync(int petId)
        {
            return await _recordRepository.GetByPetIdAsync(petId);
        }

        public async Task<(bool Success, string? Error, MedicalRecord? Created)> CreateAsync(MedicalRecord record)
        {
            if (record.PetId <= 0)
                return (false, "O ID do Pet é obrigatório e deve ser maior que zero.", null);

            var pet = await _petRepository.GetByIdAsync(record.PetId);
            if (pet == null)
                return (false, $"Pet com ID {record.PetId} não foi encontrado no sistema.", null);

            if (string.IsNullOrWhiteSpace(record.Description))
                return (false, "A descrição do procedimento/consulta é obrigatória.", null);

            if (string.IsNullOrWhiteSpace(record.VeterinarianName))
                return (false, "O nome do médico veterinário responsável é obrigatório.", null);

            if (record.RecordDate == default)
                record.RecordDate = DateTime.UtcNow;

            var created = await _recordRepository.AddAsync(record);
            return (true, null, created);
        }

        public async Task<(bool Success, string? Error)> UpdateAsync(int id, MedicalRecord record)
        {
            var existing = await _recordRepository.GetByIdAsync(id);
            if (existing == null)
                return (false, "Registro médico não encontrado.");

            if (string.IsNullOrWhiteSpace(record.Description))
                return (false, "A descrição do procedimento/consulta é obrigatória.");

            if (string.IsNullOrWhiteSpace(record.VeterinarianName))
                return (false, "O nome do médico veterinário responsável é obrigatório.");

            if (record.PetId > 0 && record.PetId != existing.PetId)
            {
                var pet = await _petRepository.GetByIdAsync(record.PetId);
                if (pet == null)
                    return (false, $"Pet com ID {record.PetId} não foi encontrado.");
                existing.PetId = record.PetId;
            }

            existing.Description = record.Description;
            existing.Diagnosis = record.Diagnosis;
            existing.Treatment = record.Treatment;
            existing.VeterinarianName = record.VeterinarianName;
            if (record.RecordDate != default)
                existing.RecordDate = record.RecordDate;

            await _recordRepository.UpdateAsync(existing);
            return (true, null);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var existing = await _recordRepository.GetByIdAsync(id);
            if (existing == null)
                return false;

            await _recordRepository.DeleteAsync(existing);
            return true;
        }
    }
}
