FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

COPY ["src/PetHealthEcosystem.Api/PetHealthEcosystem.Api.csproj", "src/PetHealthEcosystem.Api/"]
RUN dotnet restore "src/PetHealthEcosystem.Api/PetHealthEcosystem.Api.csproj"

COPY . .
WORKDIR "/app/src/PetHealthEcosystem.Api"
RUN dotnet publish "PetHealthEcosystem.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080

COPY --from=build /app/publish .

USER $APP_UID

ENTRYPOINT ["dotnet", "PetHealthEcosystem.Api.dll"]
