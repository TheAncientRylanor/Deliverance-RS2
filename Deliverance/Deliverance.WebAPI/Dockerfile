FROM mcr.microsoft.com/dotnet/sdk:9.0.306 AS build
WORKDIR /src
COPY Deliverance.Model/Deliverance.Model.csproj Deliverance.Model/
COPY Deliverance.Services/Deliverance.Services.csproj Deliverance.Services/
COPY Deliverance.WebAPI/Deliverance.WebAPI.csproj Deliverance.WebAPI/
RUN dotnet restore Deliverance.WebAPI/Deliverance.WebAPI.csproj
COPY Deliverance.Model/ Deliverance.Model/
COPY Deliverance.Services/ Deliverance.Services/
COPY Deliverance.WebAPI/ Deliverance.WebAPI/
RUN dotnet publish Deliverance.WebAPI/Deliverance.WebAPI.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:9.0.10
RUN apt-get update \
    && apt-get install -y --no-install-recommends iputils-ping libfontconfig1 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app .
EXPOSE 5095
ENTRYPOINT ["dotnet", "Deliverance.WebAPI.dll"]
