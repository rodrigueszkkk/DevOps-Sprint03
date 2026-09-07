using Microsoft.EntityFrameworkCore;
using PetHealthEcosystem.Api.Models;

namespace PetHealthEcosystem.Api.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Pet> Pets { get; set; }
        public DbSet<MedicalRecord> MedicalRecords { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Mapeamento da entidade PETS
            modelBuilder.Entity<Pet>(entity =>
            {
                entity.ToTable("PETS");
                entity.HasKey(p => p.Id);
                entity.Property(p => p.Name).IsRequired().HasMaxLength(100);
                entity.Property(p => p.Breed).HasMaxLength(50);
                entity.Property(p => p.TutorName).HasMaxLength(100);
            });

            // Mapeamento da entidade MEDICAL_RECORDS (2ª tabela core relacionada)
            modelBuilder.Entity<MedicalRecord>(entity =>
            {
                entity.ToTable("MEDICAL_RECORDS");
                entity.HasKey(m => m.Id);
                entity.Property(m => m.Description).IsRequired().HasMaxLength(255);
                entity.Property(m => m.Diagnosis).HasMaxLength(255);
                entity.Property(m => m.Treatment).HasMaxLength(255);
                entity.Property(m => m.VeterinarianName).IsRequired().HasMaxLength(100);
                entity.Property(m => m.RecordDate).IsRequired();

                entity.HasOne(m => m.Pet)
                      .WithMany(p => p.MedicalRecords)
                      .HasForeignKey(m => m.PetId)
                      .OnDelete(DeleteBehavior.Cascade);
            });
        }
    }
}
