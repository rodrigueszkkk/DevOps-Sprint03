using Microsoft.EntityFrameworkCore;
using PetHealthEcosystem.Api.Data;
using PetHealthEcosystem.Api.Domain.Interfaces;
using PetHealthEcosystem.Api.Models;

namespace PetHealthEcosystem.Api.Infrastructure.Repositories
{
    public class PetRepository : IPetRepository
    {
        private readonly AppDbContext _context;

        public PetRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Pet>> GetAllAsync() =>
            await _context.Pets.AsNoTracking().ToListAsync();

        public async Task<Pet?> GetByIdAsync(int id) =>
            await _context.Pets.FindAsync(id);

        public async Task<IEnumerable<Pet>> GetByBreedAsync(string breed) =>
            await _context.Pets
                .Where(p => p.Breed.ToLower() == breed.ToLower())
                .ToListAsync();

        public async Task<IEnumerable<Pet>> GetByPostOpCareAsync(bool needsCare) =>
            await _context.Pets
                .Where(p => p.NeedsPostOpCare == needsCare)
                .ToListAsync();

        public async Task<IEnumerable<Pet>> GetByTutorAsync(string tutorName) =>
            await _context.Pets
                .Where(p => p.TutorName.Contains(tutorName))
                .ToListAsync();

        public async Task AddAsync(Pet pet) =>
            await _context.Pets.AddAsync(pet);

        public Task UpdateAsync(Pet pet)
        {
            _context.Pets.Update(pet);
            return Task.CompletedTask;
        }

        public Task DeleteAsync(Pet pet)
        {
            _context.Pets.Remove(pet);
            return Task.CompletedTask;
        }

        public async Task<bool> ExistsAsync(int id) =>
            await _context.Pets.AnyAsync(p => p.Id == id);

        public async Task SaveChangesAsync() =>
            await _context.SaveChangesAsync();
    }
}
