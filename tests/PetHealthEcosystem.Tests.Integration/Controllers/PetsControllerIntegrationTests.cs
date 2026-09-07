using System.Net;
using System.Net.Http.Json;
using PetHealthEcosystem.Api.Models;
using PetHealthEcosystem.Tests.Integration.Fixtures;
using Xunit;

namespace PetHealthEcosystem.Tests.Integration.Controllers
{
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
            var novoPet = new Pet { Name = "Thor", Breed = "Golden Retriever", Age = 3, TutorName = "Marcos" };

            var resposta = await _client.PostAsJsonAsync("/api/pets", novoPet);

            Assert.Equal(HttpStatusCode.Created, resposta.StatusCode);
            Assert.NotNull(resposta.Headers.Location);

            var petCriado = await resposta.Content.ReadFromJsonAsync<Pet>();
            Assert.NotNull(petCriado);
            Assert.Equal("Thor", petCriado!.Name);
        }

        [Fact]
        public async Task PostPet_ComNomeVazio_DeveRetornarBadRequest()
        {
            var petInvalido = new Pet { Name = "", Breed = "SRD", Age = 1, TutorName = "Paula" };

            var resposta = await _client.PostAsJsonAsync("/api/pets", petInvalido);

            Assert.Equal(HttpStatusCode.BadRequest, resposta.StatusCode);
        }

        [Fact]
        public async Task GetById_QuandoPetExiste_DeveRetornarOkComOPet()
        {
            var novoPet = new Pet { Name = "Mel", Breed = "Beagle", Age = 2, TutorName = "Renata" };
            var criacao = await _client.PostAsJsonAsync("/api/pets", novoPet);
            var petCriado = await criacao.Content.ReadFromJsonAsync<Pet>();

            var resposta = await _client.GetAsync($"/api/pets/{petCriado!.Id}");

            Assert.Equal(HttpStatusCode.OK, resposta.StatusCode);
            var petObtido = await resposta.Content.ReadFromJsonAsync<Pet>();
            Assert.Equal("Mel", petObtido!.Name);
        }

        [Fact]
        public async Task GetById_QuandoPetNaoExiste_DeveRetornarNotFound()
        {
            var resposta = await _client.GetAsync("/api/pets/999999");

            Assert.Equal(HttpStatusCode.NotFound, resposta.StatusCode);
        }

        [Fact]
        public async Task PutPet_ComIdDivergente_DeveRetornarBadRequest()
        {
            var petAtualizado = new Pet { Id = 123, Name = "Bidu", Breed = "SRD", Age = 3, TutorName = "Tiago" };

            var resposta = await _client.PutAsJsonAsync("/api/pets/999", petAtualizado);

            Assert.Equal(HttpStatusCode.BadRequest, resposta.StatusCode);
        }

        [Fact]
        public async Task DeletePet_QuandoPetExiste_DeveRetornarNoContent()
        {
            var novoPet = new Pet { Name = "Zeus", Breed = "Bulldog", Age = 4, TutorName = "Sandra" };
            var criacao = await _client.PostAsJsonAsync("/api/pets", novoPet);
            var petCriado = await criacao.Content.ReadFromJsonAsync<Pet>();

            var resposta = await _client.DeleteAsync($"/api/pets/{petCriado!.Id}");

            Assert.Equal(HttpStatusCode.NoContent, resposta.StatusCode);
        }

        [Fact]
        public async Task DeletePet_QuandoPetNaoExiste_DeveRetornarNotFound()
        {
            var resposta = await _client.DeleteAsync("/api/pets/999999");

            Assert.Equal(HttpStatusCode.NotFound, resposta.StatusCode);
        }

        [Fact]
        public async Task GetHealth_DeveResponderComStatusHttpValido()
        {
            var resposta = await _client.GetAsync("/health");

            Assert.True(
                resposta.StatusCode == HttpStatusCode.OK ||
                resposta.StatusCode == HttpStatusCode.ServiceUnavailable);
        }
    }
}
