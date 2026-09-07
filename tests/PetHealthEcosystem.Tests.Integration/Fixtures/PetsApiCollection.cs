using Xunit;

namespace PetHealthEcosystem.Tests.Integration.Fixtures
{
    [CollectionDefinition("Pets API collection")]
    public class PetsApiCollection : ICollectionFixture<CustomWebApplicationFactory>
    {
    }
}
