using Xunit;

namespace PetHealthEcosystem.Tests.Integration.Fixtures
{
    /// <summary>
    /// Collection Fixture: garante que todas as classes marcadas com
    /// [Collection("Pets API collection")] compartilhem a mesma instância
    /// de CustomWebApplicationFactory (evita subir a aplicação várias vezes).
    /// </summary>
    [CollectionDefinition("Pets API collection")]
    public class PetsApiCollection : ICollectionFixture<CustomWebApplicationFactory>
    {
    }
}
