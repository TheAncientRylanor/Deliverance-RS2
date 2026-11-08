# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Deliverance is a 3-tier system:

- **Deliverance.WebAPI** — ASP.NET Core 9 Web API (backend, URL from `API_URL` in `.env`, default dev DB via `docker-compose.yml`)
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

Local SQL Server, RabbitMQ and Ollama for development (passwords and ports come from `.env`):

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

The API base URL is injected via a Dart compile-time define named `API_BASE_URL` (see `ApiConstants` in each app's `utils/api_constants.dart`), e.g.:

```
flutter run --dart-define=API_BASE_URL=http://localhost:5095/
```

Default fallback is `http://10.0.2.2:5095/` on mobile (Android emulator loopback to host) and `http://localhost:5095/` on desktop and scout.

## Backend architecture

### Generic CRUD pipeline

Almost every resource (Users, Devices, Offices, Contacts, ...) follows the same generic base-class pipeline instead of bespoke controllers/services:

- `BaseReadController<TResponse, TSearch, TService>` / `BaseCRUDController<TResponse, TSearch, TInsertRequest, TUpdateRequest, TService>` (`Deliverance.WebAPI/Controllers`) — generic `GET`/`GET {id}`/`POST`/`PUT {id}`/`DELETE {id}` endpoints. Concrete controllers (e.g. `UserController`, `DeviceController`) subclass these and only add resource-specific endpoints.
- `BaseReadService<TEntity, TResponse, TSearch>` / `BaseCRUDService<TEntity, TResponse, TSearch, TInsertRequest, TUpdateRequest>` (`Deliverance.Services`) — generic paging/sorting/filtering (`GetAllAsync`), `GetByIdAsync`, `InsertAsync`, `UpdateAsync`, `DeleteAsync`. Concrete services override `ApplyFilters` for resource-specific search logic and can override `MapInsertRequestToEntity`/`MapUpdateRequestToEntity` for custom mapping.
- Entity <-> DTO mapping is handled by **Mapster** using its default conventions (property-name matching) — there are no explicit `IRegister`/`TypeAdapterConfig` classes; adding a new field just requires matching property names on entity and DTO.
- `CreatedAt`/`UpdatedAt` timestamps are set automatically via reflection in the base service if the entity exposes writable properties with those names — no need to set them manually in overrides.
- Ownership checks: entities that implement `IUserOwnedEntity` (`Deliverance.Services/Database/IUserOwnedEntity.cs`) are automatically checked against the caller's `userId` in `GetByIdAsync`/`UpdateAsync`/`DeleteAsync`; a mismatch throws `ForbiddenException` (mapped to 403).
- Register new resources by wiring `I<X>Service`/`<X>Service` and the FluentValidation validators for insert/update requests in `Program.cs` — there is no assembly scanning.

### Configuration

- Every setting lives in `.env` in the repo root: connection string, RabbitMQ, JWT, token lifetimes, Ollama, `API_URL`. Nothing goes in `appsettings*.json` (only logging) or in code.
- `docker-compose` reads `.env` by itself. The API loads it at the top of `Program.cs` with `DotNetEnv` (`NoClobber`, so real environment variables win; `TraversePath`, so it works from the project or bin folder).
- `DeliveranceSettings.Load` (`Deliverance.Services/Configuration`) is the only code that reads configuration. It reads every key once at startup and throws with the key's name if one is missing or invalid. `AuthSettings`, `RabbitMqSettings` and `OllamaSettings` are registered as singletons; services take them in their constructor instead of `IConfiguration`.
- A new setting means: add it to `.env`, read it in `DeliveranceSettings.Load`, inject the settings class where it is used.

### Errors and validation

- `ExceptionHandlingMiddleware` (`Deliverance.WebAPI/Middlewares`) is the single place exceptions become HTTP responses, with a typed body (`ErrorResponse` / `ValidationErrorResponse`): FluentValidation `ValidationException` -> 400 with per-field errors, `BusinessException` (a broken business rule) -> 400, `UnauthorizedAccessException` -> 401, `ForbiddenException` -> 403, `NotFoundException` -> 404, anything else -> 500 with a generic message (and logged). The custom exceptions live in `Deliverance.Model/Exceptions`; their message is shown to the user. Don't catch-and-format exceptions in controllers/services; throw and let the middleware handle it.

### Saving and transactions

- Services share one scoped `DeliveranceDbContext` per request. A service called by another service (`NotificationService.AddFor...`, `RefreshTokenService.Add`/`RemoveAllForUserAsync`) only changes the context; the calling service does the single `SaveChangesAsync`.
- When an operation really needs more than one save (e.g. the report state machine saves, then notifications that need the report id), wrap it in `_dbContext.InTransactionAsync(...)` so all saves are kept or none.
- SignalR pushes (`NotificationService.PushAsync`) and RabbitMQ publishes happen after the save/commit succeeded.

### Dates

- Every `DateTime` is UTC: use `DateTime.UtcNow`, never `DateTime.Now`. `UtcDateTimeConverter` (applied to all DateTime columns in `ConfigureConventions`) stores UTC and marks values read back as UTC, so JSON ends in `Z`. Incoming times without a zone are treated as UTC (`DateTimeExtensions.AsUtc`).
- Only where the server itself shows a time or picks a calendar day/month (PDFs, statistics per day) is it converted, with the `DisplayTimeZone` singleton (`DISPLAY_TIME_ZONE` in `.env`).
- The Flutter apps convert at the model boundary: `utils/date_json.dart` (`dateFromJson` -> local, `dateToJson` -> UTC) via `@JsonKey(fromJson:, toJson:)`, and query-string dates are sent with `.toUtc()`.
- Insert/Update requests are validated with FluentValidation validators in `Deliverance.Services/Validators`, registered per-request-type in `Program.cs`.

### Auth

- JWT bearer auth (`Microsoft.AspNetCore.Authentication.JwtBearer`), configured from the `JWT_*` and `*_TOKEN_DURATION_*` values in `.env` (exposed as `AuthSettings`).
- `AccessManager`/`IAccessManager` handles login and refresh-token issuance; `RefreshTokenService` persists refresh tokens (`RefreshTokens` entity).
- `ClaimsPrincipalExtensions` (`Deliverance.Services/Autorization`) provides `User.GetUserId()`, used by controllers to pass the current user's `Guid` into services for ownership checks.
- All CRUD controllers are `[Authorize]` by default (set on `BaseCRUDController`/`BaseReadController`).

### Data layer

- `DeliveranceDbContext` (`Deliverance.Services/Database`) is the single EF Core context; entities live flat in that folder (no per-feature subfolders).
- `DeliveranceSeed` seeds initial data.
- Migrations live in `Deliverance.Services/Migrations` and target `DB_CONNECTION_STRING` from `.env`.

Note: despite their names, `Deliverance.Services/Implementations` and `Deliverance.Services/Interfaces` are currently empty — actual services and their interfaces live directly under `Deliverance.Services/` (e.g. `UserService.cs` + `IUserService.cs`), and `Deliverance.Services/Mapping` is empty since mapping is convention-based.

## Flutter app architecture

Both `deliverance_mobile` and `deliverance_desktop` follow the same layered pattern:

- `providers/` — `ChangeNotifier`-based state, one per resource, extending `BaseProvider<T>` (`providers/base_provider.dart`). `BaseProvider` implements the generic HTTP verbs (`get`/`getById`/`insert`/`update`/`remove`), auth headers, query-string building for search filters, and 401 handling via `sendWithRetry`, which calls `AuthProvider.instance.refreshToken()` and retries once before surfacing an error.
- `models/` — plain Dart models with hand-written or generated (`*.g.dart`, via `json_annotation`) `fromJson`/`toJson`; `*.multipart.dart` variants exist for endpoints that accept multipart form data (e.g. image upload on user insert/update).
- `screens/` — UI screens, registered with `MultiProvider` in `main.dart`.
- `layouts/`, `widgets/`, `themes/`, `utils/` — shared chrome, reusable widgets, theming, and small helpers (e.g. API error parsing in `utils/api_client_exception.dart`).
- API base URL and other environment-specific values are passed via `--dart-define`, not hardcoded per-environment config files.

When adding a new resource end-to-end, the usual path is: add entity to `DeliveranceDbContext` + migration -> add Request/Response DTOs in `Deliverance.Model` -> add `I<X>Service`/`<X>Service` extending the base services + validators -> add controller extending `BaseCRUDController`/`BaseReadController` -> wire DI registrations in `Program.cs` -> add matching Dart model + provider (extending `BaseProvider`) + screen in each Flutter app that needs it.
