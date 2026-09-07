using Microsoft.EntityFrameworkCore;
using PetHealthEcosystem.Api.Data;
using PetHealthEcosystem.Api.Domain.Interfaces;
using PetHealthEcosystem.Api.Models;

namespace PetHealthEcosystem.Api.Infrastructure.Repositories
{
    public class MedicalRecordRepository : IMedicalRecordRepository
    {
        private readonly AppDbContext _context;

        public MedicalRecordRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<MedicalRecord>> GetAllAsync()
        {
            return await _context.MedicalRecords
                .Include(m => m.Pet)
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<MedicalRecord?> GetByIdAsync(int id)
        {
            return await _context.MedicalRecords
                .Include(m => m.Pet)
                .FirstOrDefaultAsync(m => m.Id == id);
        }

        public async Task<IEnumerable<MedicalRecord>> GetByPetIdAsync(int petId)
        {
            return await _context.MedicalRecords
                .Where(m => m.PetId == petId)
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<MedicalRecord> AddAsync(MedicalRecord record)
        {
            _context.MedicalRecords.Add(record);
            await _context.SaveChangesAsync();
            return record;
        }

        public async Task UpdateAsync(MedicalRecord record)
        {
            _context.MedicalRecords.Update(record);
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(MedicalRecord record)
        {
            _context.MedicalRecords.Remove(record);
            await _context.SaveChangesAsync();
        }
    }
}
