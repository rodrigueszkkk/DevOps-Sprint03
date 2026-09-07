# =====================================================================
# DOCKERFILE MULTI-STAGE (.NET 8 - C#)
# Aderente aos requisitos da 3ª Sprint de DevOps Tools & Cloud Computing
# REQUISITO OBRIGATÓRIO 8.2: O container do App NÃO pode rodar como root ou admin
# =====================================================================

# ---------------------------------------------------------------------
# Estágio 1: Compilação e Publicação (Build Stage)
# ---------------------------------------------------------------------
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copia arquivo do projeto e restaura dependências
COPY ["src/PetHealthEcosystem.Api/PetHealthEcosystem.Api.csproj", "src/PetHealthEcosystem.Api/"]
RUN dotnet restore "src/PetHealthEcosystem.Api/PetHealthEcosystem.Api.csproj"

# Copia todo o código-fonte restante
COPY . .
WORKDIR "/app/src/PetHealthEcosystem.Api"

# Publica os binários otimizados de release
RUN dotnet publish "PetHealthEcosystem.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# ---------------------------------------------------------------------
# Estágio 2: Ambiente de Execução Seguro (Runtime Stage)
# ---------------------------------------------------------------------
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# Configuração da porta de escuta HTTP não-privilegiada padrão do .NET 8
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080

# Copia os artefatos compilados do estágio anterior
COPY --from=build /app/publish .

# REQUISITO SPRINT 8.2: Usuário não-root / sem privilégios administrativos
# A imagem base aspnet:8.0 já fornece o usuário sem privilégios '$APP_UID' (UID 1654 / app)
USER $APP_UID

# Ponto de entrada da aplicação
ENTRYPOINT ["dotnet", "PetHealthEcosystem.Api.dll"]
