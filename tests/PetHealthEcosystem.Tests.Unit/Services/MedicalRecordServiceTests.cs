using Moq;
using PetHealthEcosystem.Api.Application.Services;
using PetHealthEcosystem.Api.Domain.Interfaces;
using PetHealthEcosystem.Api.Models;
using Xunit;

namespace PetHealthEcosystem.Tests.Unit.Services
{
    /// <summary>
    /// Testes unitários para MedicalRecordService (CRUD da segunda tabela core).
    /// Padrão AAA (Arrange, Act, Assert).
    /// </summary>
    public class MedicalRecordServiceTests
    {
        private readonly Mock<IMedicalRecordRepository> _recordRepoMock;
        private readonly Mock<IPetRepository> _petRepoMock;
        private readonly MedicalRecordService _sut;

        public MedicalRecordServiceTests()
        {
            _recordRepoMock = new Mock<IMedicalRecordRepository>();
            _petRepoMock = new Mock<IPetRepository>();
            _sut = new MedicalRecordService(_recordRepoMock.Object, _petRepoMock.Object);
        }

        [Fact]
        public async Task GetAllAsync_QuandoExistemRegistros_DeveRetornarTodos()
        {
            // Arrange
            var registros = new List<MedicalRecord>
            {
                new MedicalRecord { Id = 1, PetId = 1, Description = "Vacinação V10", VeterinarianName = "Dra. Ana" },
                new MedicalRecord { Id = 2, PetId = 1, Description = "Consulta Ortopédica", VeterinarianName = "Dr. Pedro" }
            };
            _recordRepoMock.Setup(r => r.GetAllAsync()).ReturnsAsync(registros);

            // Act
            var resultado = await _sut.GetAllAsync();

            // Assert
            Assert.Equal(2, resultado.Count());
            _recordRepoMock.Verify(r => r.GetAllAsync(), Times.Once);
        }

        [Fact]
        public async Task CreateAsync_QuandoPetNaoExiste_DeveRetornarFalha()
        {
            // Arrange
            _petRepoMock.Setup(p => p.GetByIdAsync(99)).ReturnsAsync((Pet?)null);
            var record = new MedicalRecord
            {
                PetId = 99,
                Description = "Check-up",
                VeterinarianName = "Dr. Silva"
            };

            // Act
            var (sucesso, erro, criado) = await _sut.CreateAsync(record);

            // Assert
            Assert.False(sucesso);
            Assert.Contains("não foi encontrado", erro);
            Assert.Null(criado);
            _recordRepoMock.Verify(r => r.AddAsync(It.IsAny<MedicalRecord>()), Times.Never);
        }

        [Fact]
        public async Task CreateAsync_SemDescricao_DeveRetornarFalha()
        {
            // Arrange
            _petRepoMock.Setup(p => p.GetByIdAsync(1)).ReturnsAsync(new Pet { Id = 1, Name = "Rex" });
            var record = new MedicalRecord
            {
                PetId = 1,
                Description = "",
                VeterinarianName = "Dr. Silva"
            };

            // Act
            var (sucesso, erro, _) = await _sut.CreateAsync(record);

            // Assert
            Assert.False(sucesso);
            Assert.Equal("A descrição do procedimento/consulta é obrigatória.", erro);
        }

        [Fact]
        public async Task CreateAsync_ComDadosValidos_DeveSalvarERetornarSucesso()
        {
            // Arrange
            var pet = new Pet { Id = 1, Name = "Rex" };
            var record = new MedicalRecord
            {
                PetId = 1,
                Description = "Exame de sangue completo",
                Diagnosis = "Normal",
                Treatment = "Nenhum",
                VeterinarianName = "Dr. Carlos"
            };
            _petRepoMock.Setup(p => p.GetByIdAsync(1)).ReturnsAsync(pet);
            _recordRepoMock.Setup(r => r.AddAsync(record)).ReturnsAsync(record);

            // Act
            var (sucesso, erro, criado) = await _sut.CreateAsync(record);

            // Assert
            Assert.True(sucesso);
            Assert.Null(erro);
            Assert.NotNull(criado);
            _recordRepoMock.Verify(r => r.AddAsync(record), Times.Once);
        }

        [Fact]
        public async Task UpdateAsync_QuandoNaoExiste_DeveRetornarFalha()
        {
            // Arrange
            _recordRepoMock.Setup(r => r.GetByIdAsync(50)).ReturnsAsync((MedicalRecord?)null);

            // Act
            var (sucesso, erro) = await _sut.UpdateAsync(50, new MedicalRecord { Description = "Teste", VeterinarianName = "Vet" });

            // Assert
            Assert.False(sucesso);
            Assert.Equal("Registro médico não encontrado.", erro);
        }

        [Fact]
        public async Task DeleteAsync_QuandoExiste_DeveDeletarERetornarTrue()
        {
            // Arrange
            var existente = new MedicalRecord { Id = 10, PetId = 1, Description = "Limpeza" };
            _recordRepoMock.Setup(r => r.GetByIdAsync(10)).ReturnsAsync(existente);
            _recordRepoMock.Setup(r => r.DeleteAsync(existente)).Returns(Task.CompletedTask);

            // Act
            var resultado = await _sut.DeleteAsync(10);

            // Assert
            Assert.True(resultado);
            _recordRepoMock.Verify(r => r.DeleteAsync(existente), Times.Once);
        }
    }
}
