using Microsoft.Extensions.Logging;
using Moq;
using PetHealthEcosystem.Api.Application.Services;
using PetHealthEcosystem.Api.Domain.Interfaces;
using PetHealthEcosystem.Api.Models;
using Xunit;

namespace PetHealthEcosystem.Tests.Unit.Services
{
    /// <summary>
    /// Testes unitários da camada de Aplicação (PetService), com o repositório
    /// (camada de Domínio/Infraestrutura) mockado via Moq.
    /// Convenção de nomes: MetodoTestado_Cenario_ResultadoEsperado.
    /// </summary>
    public class PetServiceTests
    {
        private readonly Mock<IPetRepository> _repositoryMock;
        private readonly PetService _sut; // system under test

        public PetServiceTests()
        {
            _repositoryMock = new Mock<IPetRepository>();
            var loggerMock = new Mock<ILogger<PetService>>();
            _sut = new PetService(_repositoryMock.Object, loggerMock.Object);
        }

        [Fact]
        public async Task GetAllAsync_QuandoExistemPets_DeveRetornarTodosOsPets()
        {
            // Arrange
            var petsEsperados = new List<Pet>
            {
                new Pet { Id = 1, Name = "Rex", Breed = "Labrador", Age = 3, TutorName = "Ana" },
                new Pet { Id = 2, Name = "Mia", Breed = "Siamês", Age = 2, TutorName = "Bruno" }
            };
            _repositoryMock.Setup(r => r.GetAllAsync()).ReturnsAsync(petsEsperados);

            // Act
            var resultado = await _sut.GetAllAsync();

            // Assert
            Assert.Equal(2, resultado.Count());
            _repositoryMock.Verify(r => r.GetAllAsync(), Times.Once);
        }

        [Fact]
        public async Task GetByIdAsync_QuandoPetNaoExiste_DeveRetornarNulo()
        {
            // Arrange
            _repositoryMock.Setup(r => r.GetByIdAsync(It.IsAny<int>())).ReturnsAsync((Pet?)null);

            // Act
            var resultado = await _sut.GetByIdAsync(99);

            // Assert
            Assert.Null(resultado);
        }

        [Fact]
        public async Task CreateAsync_ComNomeVazio_DeveRetornarFalhaDeValidacaoSemPersistir()
        {
            // Arrange
            var petInvalido = new Pet { Name = "", Breed = "Vira-lata", Age = 1, TutorName = "Carla" };

            // Act
            var (sucesso, erro, petCriado) = await _sut.CreateAsync(petInvalido);

            // Assert
            Assert.False(sucesso);
            Assert.Equal("O nome do pet é obrigatório.", erro);
            Assert.Null(petCriado);
            _repositoryMock.Verify(r => r.AddAsync(It.IsAny<Pet>()), Times.Never);
        }

        [Fact]
        public async Task CreateAsync_ComIdadeNegativa_DeveRetornarFalhaDeValidacao()
        {
            // Arrange
            var petInvalido = new Pet { Name = "Thor", Breed = "Pastor Alemão", Age = -1, TutorName = "Diego" };

            // Act
            var (sucesso, erro, _) = await _sut.CreateAsync(petInvalido);

            // Assert
            Assert.False(sucesso);
            Assert.Equal("A idade do pet não pode ser negativa.", erro);
        }

        [Fact]
        public async Task CreateAsync_SemNomeDoTutor_DeveRetornarFalhaDeValidacao()
        {
            // Arrange
            var petInvalido = new Pet { Name = "Amora", Breed = "SRD", Age = 2, TutorName = "" };

            // Act
            var (sucesso, erro, _) = await _sut.CreateAsync(petInvalido);

            // Assert
            Assert.False(sucesso);
            Assert.Equal("O nome do tutor é obrigatório.", erro);
        }

        [Fact]
        public async Task CreateAsync_ComDadosValidos_DevePersistirERetornarSucesso()
        {
            // Arrange
            var petValido = new Pet { Name = "Nina", Breed = "Poodle", Age = 4, TutorName = "Elisa" };
            _repositoryMock.Setup(r => r.AddAsync(petValido)).Returns(Task.CompletedTask);
            _repositoryMock.Setup(r => r.SaveChangesAsync()).Returns(Task.CompletedTask);

            // Act
            var (sucesso, erro, petCriado) = await _sut.CreateAsync(petValido);

            // Assert
            Assert.True(sucesso);
            Assert.Null(erro);
            Assert.Equal(petValido, petCriado);
            _repositoryMock.Verify(r => r.AddAsync(petValido), Times.Once);
            _repositoryMock.Verify(r => r.SaveChangesAsync(), Times.Once);
        }

        [Fact]
        public async Task UpdateAsync_ComIdDivergenteDoCorpo_DeveRetornarFalha()
        {
            // Arrange
            var pet = new Pet { Id = 5, Name = "Bob", Breed = "Vira-lata", Age = 2, TutorName = "Fábio" };

            // Act
            var (sucesso, erro) = await _sut.UpdateAsync(1, pet);

            // Assert
            Assert.False(sucesso);
            Assert.Equal("ID incompatível.", erro);
        }

        [Fact]
        public async Task UpdateAsync_QuandoPetNaoExiste_DeveRetornarFalha()
        {
            // Arrange
            var pet = new Pet { Id = 10, Name = "Bob", Breed = "Vira-lata", Age = 2, TutorName = "Fábio" };
            _repositoryMock.Setup(r => r.GetByIdAsync(10)).ReturnsAsync((Pet?)null);

            // Act
            var (sucesso, erro) = await _sut.UpdateAsync(10, pet);

            // Assert
            Assert.False(sucesso);
            Assert.Equal("Pet não encontrado.", erro);
        }

        [Fact]
        public async Task UpdateAsync_ComDadosValidos_DeveAtualizarCamposERetornarSucesso()
        {
            // Arrange
            var existente = new Pet { Id = 7, Name = "Old", Breed = "SRD", Age = 1, TutorName = "Gil" };
            var atualizado = new Pet { Id = 7, Name = "New", Breed = "SRD", Age = 2, TutorName = "Gil", NeedsPostOpCare = true };
            _repositoryMock.Setup(r => r.GetByIdAsync(7)).ReturnsAsync(existente);

            // Act
            var (sucesso, erro) = await _sut.UpdateAsync(7, atualizado);

            // Assert
            Assert.True(sucesso);
            Assert.Null(erro);
            Assert.Equal("New", existente.Name);
            Assert.True(existente.NeedsPostOpCare);
            _repositoryMock.Verify(r => r.UpdateAsync(existente), Times.Once);
            _repositoryMock.Verify(r => r.SaveChangesAsync(), Times.Once);
        }

        [Fact]
        public async Task DeleteAsync_QuandoPetExiste_DeveRemoverERetornarTrue()
        {
            // Arrange
            var pet = new Pet { Id = 3, Name = "Luna", Breed = "SRD", Age = 5, TutorName = "Helena" };
            _repositoryMock.Setup(r => r.GetByIdAsync(3)).ReturnsAsync(pet);

            // Act
            var resultado = await _sut.DeleteAsync(3);

            // Assert
            Assert.True(resultado);
            _repositoryMock.Verify(r => r.DeleteAsync(pet), Times.Once);
            _repositoryMock.Verify(r => r.SaveChangesAsync(), Times.Once);
        }

        [Fact]
        public async Task DeleteAsync_QuandoPetNaoExiste_DeveRetornarFalseSemRemover()
        {
            // Arrange
            _repositoryMock.Setup(r => r.GetByIdAsync(It.IsAny<int>())).ReturnsAsync((Pet?)null);

            // Act
            var resultado = await _sut.DeleteAsync(999);

            // Assert
            Assert.False(resultado);
            _repositoryMock.Verify(r => r.DeleteAsync(It.IsAny<Pet>()), Times.Never);
        }
    }
}
