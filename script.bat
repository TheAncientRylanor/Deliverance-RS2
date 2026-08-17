@echo off
setlocal enabledelayedexpansion

set SOLUTION_NAME=Deliverance 

echo Creating solution folder...
mkdir %SOLUTION_NAME%
cd %SOLUTION_NAME%

echo Creating solution...
dotnet new sln -n %SOLUTION_NAME%

echo Creating projects...
:: Web API
dotnet new webapi -n Deliverance.WebAPI --use-controllers
:: Services layer
dotnet new classlib -n Deliverance.Services
:: Model layer
dotnet new classlib -n Deliverance.Model

echo Adding projects to solution...
dotnet sln add Deliverance.WebAPI\Deliverance.WebAPI.csproj
dotnet sln add Deliverance.Services\Deliverance.Services.csproj
dotnet sln add Deliverance.Model\Deliverance.Model.csproj

echo Adding project references...
:: WebAPI -> Services
dotnet add Deliverance.WebAPI reference Deliverance.Services
:: Services -> Model
dotnet add Deliverance.Services reference Deliverance.Model

echo Adding EF Core packages...
:: EF Core in Services (DbContext lives here)
dotnet add Deliverance.Services package Microsoft.EntityFrameworkCore
dotnet add Deliverance.Services package Microsoft.EntityFrameworkCore.SqlServer
:: EF Core Design tools in WebAPI (for migrations)
dotnet add Deliverance.WebAPI package Microsoft.EntityFrameworkCore.Design

echo Adding Scalar (OpenAPI UI) to WebAPI...
dotnet add Deliverance.WebAPI package Scalar.AspNetCore

echo Creating recommended folders...
mkdir Deliverance.WebAPI\Controllers 2>nul
mkdir Deliverance.WebAPI\Middlewares 2>nul
mkdir Deliverance.WebAPI\Extensions 2>nul

mkdir Deliverance.Services\Interfaces 2>nul
mkdir Deliverance.Services\Implementations 2>nul
mkdir Deliverance.Services\Database 2>nul

mkdir Deliverance.Model\Responses 2>nul
mkdir Deliverance.Model\Requests 2>nul
mkdir Deliverance.Model\SearchObjects 2>nul
mkdir Deliverance.Model\Enums 2>nul

echo Done!
echo Next steps:
echo 1) Add DbContext in Deliverance.Services\Database
echo 2) Register DbContext in WebAPI Program.cs
echo 3) Configure Scalar in WebAPI

echo Open %SOLUTION_NAME%.sln in your IDE.
pause