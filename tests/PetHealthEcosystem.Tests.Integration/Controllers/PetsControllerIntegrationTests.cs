using System.Net;
using System.Net.Http.Json;
using PetHealthEcosystem.Api.Models;
using PetHealthEcosystem.Tests.Integration.Fixtures;
using Xunit;

namespace PetHealthEcosystem.Tests.Integration.Controllers
{
    /// <summary>
    /// Testes de integração: sobem a API completa em memória (WebApplicationFactory)
    /// e validam o fluxo real de requisições HTTP, incluindo respostas de sucesso
    /// e tratamento de erros, contra um banco InMemory isolado.
    /// </summary>
    [Collection("Pets API collection")]
    public class PetsControllerIntegrationTests
    {
        private readonly HttpClient _client;

        public PetsControllerIntegrationTests(CustomWebApplicationFactory factory)
        {
            _client = factory.CreateClient();
        }

        [Fact]
        public async Task PostPet_ComDadosValidos_DeveRetornarCreatedComLocationHeader()
        {
            // Arrange
            var novoPet = new Pet { Name = "Thor", Breed = "Golden Retriever", Age = 3, TutorName = "Marcos" };

            // Act
            var resposta = await _client.PostAsJsonAsync("/api/pets", novoPet);

            // Assert
            Assert.Equal(HttpStatusCode.Created, resposta.StatusCode);
            Assert.NotNull(resposta.Headers.Location);

            var petCriado = await resposta.Content.ReadFromJsonAsync<Pet>();
            Assert.NotNull(petCriado);
            Assert.Equal("Thor", petCriado!.Name);
        }

        [Fact]
        public async Task PostPet_ComNomeVazio_DeveRetornarBadRequest()
        {
            // Arrange
            var petInvalido = new Pet { Name = "", Breed = "SRD", Age = 1, TutorName = "Paula" };

            // Act
            var resposta = await _client.PostAsJsonAsync("/api/pets", petInvalido);

            // Assert
            Assert.Equal(HttpStatusCode.BadRequest, resposta.StatusCode);
        }

        [Fact]
        public async Task GetById_QuandoPetExiste_DeveRetornarOkComOPet()
        {
            // Arrange
            var novoPet = new Pet { Name = "Mel", Breed = "Beagle", Age = 2, TutorName = "Renata" };
            var criacao = await _client.PostAsJsonAsync("/api/pets", novoPet);
            var petCriado = await criacao.Content.ReadFromJsonAsync<Pet>();

            // Act
            var resposta = await _client.GetAsync($"/api/pets/{petCriado!.Id}");

            // Assert
            Assert.Equal(HttpStatusCode.OK, resposta.StatusCode);
            var petObtido = await resposta.Content.ReadFromJsonAsync<Pet>();
            Assert.Equal("Mel", petObtido!.Name);
        }

        [Fact]
        public async Task GetById_QuandoPetNaoExiste_DeveRetornarNotFound()
        {
            // Act
            var resposta = await _client.GetAsync("/api/pets/999999");

            // Assert
            Assert.Equal(HttpStatusCode.NotFound, resposta.StatusCode);
        }

        [Fact]
        public async Task PutPet_ComIdDivergente_DeveRetornarBadRequest()
        {
            // Arrange
            var petAtualizado = new Pet { Id = 123, Name = "Bidu", Breed = "SRD", Age = 3, TutorName = "Tiago" };

            // Act
            var resposta = await _client.PutAsJsonAsync("/api/pets/999", petAtualizado);

            // Assert
            Assert.Equal(HttpStatusCode.BadRequest, resposta.StatusCode);
        }

        [Fact]
        public async Task DeletePet_QuandoPetExiste_DeveRetornarNoContent()
        {
            // Arrange
            var novoPet = new Pet { Name = "Zeus", Breed = "Bulldog", Age = 4, TutorName = "Sandra" };
            var criacao = await _client.PostAsJsonAsync("/api/pets", novoPet);
            var petCriado = await criacao.Content.ReadFromJsonAsync<Pet>();

            // Act
            var resposta = await _client.DeleteAsync($"/api/pets/{petCriado!.Id}");

            // Assert
            Assert.Equal(HttpStatusCode.NoContent, resposta.StatusCode);
        }

        [Fact]
        public async Task DeletePet_QuandoPetNaoExiste_DeveRetornarNotFound()
        {
            // Act
            var resposta = await _client.DeleteAsync("/api/pets/999999");

            // Assert
            Assert.Equal(HttpStatusCode.NotFound, resposta.StatusCode);
        }

        [Fact]
        public async Task GetHealth_DeveResponderComStatusHttpValido()
        {
            // Act
            var resposta = await _client.GetAsync("/health");

            // Assert: em ambiente de teste não há Oracle real, então aceitamos
            // tanto Healthy (200) quanto Unhealthy (503) — o importante é que
            // o endpoint responda corretamente, sem lançar exceção não tratada.
            Assert.True(
                resposta.StatusCode == HttpStatusCode.OK ||
                resposta.StatusCode == HttpStatusCode.ServiceUnavailable);
        }
    }
}
