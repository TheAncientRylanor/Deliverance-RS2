# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Deliverance is a 3-tier system:

- **Deliverance.WebAPI** — ASP.NET Core 9 Web API (backend, port from `launchSettings.json`, default dev DB via `docker-compose.yml`)
- **Deliverance.Services** — business logic, EF Core `DbContext`, generic CRUD services
- **Deliverance.Model** — DTOs (Request/Responses), search objects, enums, exceptions — no logic
- **UI/deliverance_mobile** — Flutter mobile client
- **UI/deliverance_desktop** — Flutter desktop client (Windows)

The two Flutter apps are independent Flutter projects (separate `pubspec.yaml`) that both talk to the same WebAPI and largely mirror each other's provider/model structure.

## Common commands

### Backend (.NET)

Run from the repo root (`Deliverance.sln`):

```
dotnet build Deliverance.sln
dotnet run --project Deliverance.WebAPI
```

Local SQL Server for development (SA password `qweasd123!`, host port `1435`):

```
docker-compose up -d
```

EF Core migrations (run from repo root, or `cd Deliverance.Services` and drop `--project`):

```
dotnet ef migrations add <Name> --project Deliverance.Services --startup-project Deliverance.WebAPI
dotnet ef database update --project Deliverance.Services --startup-project Deliverance.WebAPI
```

In development, Scalar's OpenAPI UI is mapped automatically (`app.MapScalarApiReference()`), so no separate Swagger setup is needed.

There are no automated test projects in the solution currently.

### Flutter apps

From `UI/deliverance_mobile` or `UI/deliverance_desktop`:

```
flutter pub get
flutter run
flutter analyze
```

The API base URL is injected via a Dart compile-time define named `baseUrl` (see `BaseProvider` in each app), e.g.:

```
flutter run --dart-define=baseUrl=http://localhost:5095/
```

Default fallback is `http://10.0.2.2:5095/` (Android emulator loopback to host).

## Backend architecture

### Generic CRUD pipeline

Almost every resource (Users, Devices, Offices, Contacts, ...) follows the same generic base-class pipeline instead of bespoke controllers/services:

- `BaseReadController<TResponse, TSearch, TService>` / `BaseCRUDController<TResponse, TSearch, TInsertRequest, TUpdateRequest, TService>` (`Deliverance.WebAPI/Controllers`) — generic `GET`/`GET {id}`/`POST`/`PUT {id}`/`DELETE {id}` endpoints. Concrete controllers (e.g. `UserController`, `DeviceController`) subclass these and only add resource-specific endpoints.
- `BaseReadService<TEntity, TResponse, TSearch>` / `BaseCRUDService<TEntity, TResponse, TSearch, TInsertRequest, TUpdateRequest>` (`Deliverance.Services`) — generic paging/sorting/filtering (`GetAllAsync`), `GetByIdAsync`, `InsertAsync`, `UpdateAsync`, `DeleteAsync`. Concrete services override `ApplyFilters` for resource-specific search logic and can override `MapInsertRequestToEntity`/`MapUpdateRequestToEntity` for custom mapping.
- Entity <-> DTO mapping is handled by **Mapster** using its default conventions (property-name matching) — there are no explicit `IRegister`/`TypeAdapterConfig` classes; adding a new field just requires matching property names on entity and DTO.
- `CreatedAt`/`UpdatedAt` timestamps are set automatically via reflection in the base service if the entity exposes writable properties with those names — no need to set them manually in overrides.
- Ownership checks: entities that implement `IUserOwnedEntity` (`Deliverance.Services/Database/IUserOwnedEntity.cs`) are automatically checked against the caller's `userId` in `GetByIdAsync`/`UpdateAsync`/`DeleteAsync`; a mismatch throws `ClientException` (mapped to 400) rather than a generic 403/500.
- Register new resources by wiring `I<X>Service`/`<X>Service` and the FluentValidation validators for insert/update requests in `Program.cs` — there is no assembly scanning.

### Errors and validation

- `ExceptionHandlingMiddleware` (`Deliverance.WebAPI/Middlewares`) is the single place exceptions become HTTP responses: FluentValidation `ValidationException` -> 400 with per-field errors, `ClientException` (`Deliverance.Model/Exceptions`) -> 400 with a message, anything else -> 500 with a generic message. Don't catch-and-format exceptions in controllers/services; throw and let the middleware handle it.
- Insert/Update requests are validated with FluentValidation validators in `Deliverance.Services/Validators`, registered per-request-type in `Program.cs`.

### Auth

- JWT bearer auth (`Microsoft.AspNetCore.Authentication.JwtBearer`), configured from `JwtToken:Issuer/Audience/SecretKey/DurationInMinutes` in `appsettings.json`.
- `AccessManager`/`IAccessManager` handles login and refresh-token issuance; `RefreshTokenService` persists refresh tokens (`RefreshTokens` entity).
- `ClaimsPrincipalExtensions` (`Deliverance.Services/Autorization`) provides `User.GetUserId()`, used by controllers to pass the current user's `Guid` into services for ownership checks.
- All CRUD controllers are `[Authorize]` by default (set on `BaseCRUDController`/`BaseReadController`).

### Data layer

- `DeliveranceDbContext` (`Deliverance.Services/Database`) is the single EF Core context; entities live flat in that folder (no per-feature subfolders).
- `DeliveranceSeed` seeds initial data.
- Migrations live in `Deliverance.Services/Migrations` and target the `DefaultConnection` connection string from `appsettings.json`/`appsettings.Development.json`.

Note: despite their names, `Deliverance.Services/Implementations` and `Deliverance.Services/Interfaces` are currently empty — actual services and their interfaces live directly under `Deliverance.Services/` (e.g. `UserService.cs` + `IUserService.cs`), and `Deliverance.Services/Mapping` is empty since mapping is convention-based.

## Flutter app architecture

Both `deliverance_mobile` and `deliverance_desktop` follow the same layered pattern:

- `providers/` — `ChangeNotifier`-based state, one per resource, extending `BaseProvider<T>` (`providers/base_provider.dart`). `BaseProvider` implements the generic HTTP verbs (`get`/`getById`/`insert`/`update`/`remove`), auth headers, query-string building for search filters, and 401 handling via `sendWithRetry`, which calls `AuthProvider.instance.refreshToken()` and retries once before surfacing an error.
- `models/` — plain Dart models with hand-written or generated (`*.g.dart`, via `json_annotation`) `fromJson`/`toJson`; `*.multipart.dart` variants exist for endpoints that accept multipart form data (e.g. image upload on user insert/update).
- `screens/` — UI screens, registered with `MultiProvider` in `main.dart`.
- `layouts/`, `widgets/`, `themes/`, `utils/` — shared chrome, reusable widgets, theming, and small helpers (e.g. API error parsing in `utils/api_client_exception.dart`).
- API base URL and other environment-specific values are passed via `--dart-define`, not hardcoded per-environment config files.

When adding a new resource end-to-end, the usual path is: add entity to `DeliveranceDbContext` + migration -> add Request/Response DTOs in `Deliverance.Model` -> add `I<X>Service`/`<X>Service` extending the base services + validators -> add controller extending `BaseCRUDController`/`BaseReadController` -> wire DI registrations in `Program.cs` -> add matching Dart model + provider (extending `BaseProvider`) + screen in each Flutter app that needs it.
