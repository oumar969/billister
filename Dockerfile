# Build stage
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src

COPY ["Billister/Billister.csproj", "Billister/"]
RUN dotnet restore "Billister/Billister.csproj"

COPY . .
WORKDIR "/src/Billister"
RUN dotnet build "Billister.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "Billister.csproj" -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app
COPY --from=publish /app/publish .

EXPOSE 5012

ENV ASPNETCORE_URLS=http://+:5012
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "Billister.dll"]
