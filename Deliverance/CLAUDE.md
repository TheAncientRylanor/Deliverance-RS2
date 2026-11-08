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

- `BaseReadController<TResponse, TSearch, TService>` / `BaseCRUDController<TResponse, TSearch, TInsertRequest, TUpdateRequest, TService>` (`Deliverance.WebAPI/Controllers`) — generic `GET`/`GET {id}`/`POST`/`PUT {id}`/`DELETE {id}` endpoints. Concrete controllers (e.g. `DeviceController`, `ReportController`) subclass these and only add resource-specific endpoints. A resource that doesn't fit the generic endpoints (e.g. `UserController`, keyed by UUID) is a plain `ControllerBase` with only the endpoints it has, never inherited endpoints switched off with `NotSupportedException`.
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

### Validation

- Limits and messages live in `Deliverance.Services/Validators/FieldRules.cs` (e.g. `.PersonName()`, `.Email()`, `.Password()`, `.OfficeName()`); insert and update validators use the same rules. Messages state the expected format and limits, and limits match the database columns.
- A check that needs the database (email/username/office name taken, wrong current password) throws `FieldRules.FieldError(property, message)`, a `ValidationException` with the property name, so the apps show it below that field.
- ASP.NET's implicit `[Required]` is off (FluentValidation does it), and unreadable request bodies return the same `ValidationErrorResponse` shape (see `AddControllers` in `Program.cs`).
- Flutter: `utils/form_validators.dart` mirrors `FieldRules` (keep both in sync), `ServerFieldErrors` (`utils/server_field_errors.dart`) puts the API's field errors below the fields, and `ApiClientException.fieldErrors` carries them. Validation messages go below controls, never in dialogs; dialogs are for errors that aren't about a field. Success toasts name what was saved.

### Business rules (server-side, never only in the apps)

- Contact availability: slots on the same weekday can't overlap or repeat (touching is fine), and a break must fall inside its slot — `CollectionRules.NoOverlappingSlots` and `AvailabilityRules` in `FieldRules.cs`. A contact's emails and phone numbers can't repeat.
- Reports: `ReportService.EnsureReportCanBeSavedAsync` runs on insert and on editing a draft or unseen report. It checks that every office, device and answered question exists and that each device is in the office it is reported under. When sending (not a draft), a user can't have a second open (unseen or seen) report about the same device.
- No duplicates inside a report (an office once, a device once per office, a question once): the validators give the message, and unique indexes on `OfficeReports(ReportId, OfficeId)`, `DeviceReports(OfficeReportId, DeviceId)`, `ReportOccurrences(ReportId, OccurrenceId)` and `Availabilities(ContactId, Day, FromTime)` guarantee it. A unique-index violation (two requests racing) becomes 409 in `ExceptionHandlingMiddleware`.
- Values the server can work out itself are not taken from the app (e.g. `OfficeReport.NumReportedDevices` is the number of device rows).

### Saving and transactions

- Services share one scoped `DeliveranceDbContext` per request. A service called by another service (`NotificationService.AddFor...`, `RefreshTokenService.Add`/`RemoveAllForUserAsync`) only changes the context; the calling service does the single `SaveChangesAsync`.
- When an operation really needs more than one save (e.g. the report state machine saves, then notifications that need the report id), wrap it in `_dbContext.InTransactionAsync(...)` so all saves are kept or none.
- SignalR pushes (`NotificationService.PushAsync`) and RabbitMQ publishes happen after the save/commit succeeded.
- Report events go through `ReportEventQueue` (what `IReportEventPublisher` resolves to); the hosted `ReportEventPublisherWorker` sends them to RabbitMQ with retries. Don't use fire-and-forget `Task.Run` for background work; add a `BackgroundService`.

### Performance

- Every list endpoint is paged: `Paging.Normalize` gives page size 10 by default and caps it at `Paging.MaxPageSize` (100). New custom list endpoints return `PageResult<T>` and use `Paging` too.
- Data that every request needs and that rarely changes goes in `IMemoryCache` inside the service (the recommendation model, the occurrence questions), not in static fields or dictionaries.
- Aggregations are done in grouped queries in the database (see `ReportStatisticsService.GetStatistics`: two queries in total).

### Dates

- Every `DateTime` is UTC: use `DateTime.UtcNow`, never `DateTime.Now`. `UtcDateTimeConverter` (applied to all DateTime columns in `ConfigureConventions`) stores UTC and marks values read back as UTC, so JSON ends in `Z`. Incoming times without a zone are treated as UTC (`DateTimeExtensions.AsUtc`).
- Only where the server itself shows a time or picks a calendar day/month (PDFs, statistics per day) is it converted, with the `DisplayTimeZone` singleton (`DISPLAY_TIME_ZONE` in `.env`).
- The Flutter apps convert at the model boundary: `utils/date_json.dart` (`dateFromJson` -> local, `dateToJson` -> UTC) via `@JsonKey(fromJson:, toJson:)`, and query-string dates are sent with `.toUtc()`.
- Insert/Update requests are validated with FluentValidation validators in `Deliverance.Services/Validators`, registered per-request-type in `Program.cs`.

### Auth

- JWT bearer auth (`Microsoft.AspNetCore.Authentication.JwtBearer`), configured from the `JWT_*` and `*_TOKEN_DURATION_*` values in `.env` (exposed as `AuthSettings`).
- `AccessManager`/`IAccessManager` handles login, refresh, logout and password change; `RefreshTokenService` persists refresh tokens (`RefreshTokens` entity, SHA-256 hashes only).
- A `RefreshTokens` row is a session. Access tokens carry its id (`session_id` claim) and `OnTokenValidated` in `Program.cs` rejects a token whose session is gone, so `Access/Logout`, a password change or a deleted user signs out on the server immediately. Refresh rotates only that session's token.
- Tokens are HS256 only (`ValidAlgorithms`), signed with `JWT_SECRET_KEY` (at least 32 characters, checked at startup).
- Passwords: `CryptoService`, PBKDF2-HMAC-SHA256, 600 000 iterations, random salt, constant-time compare. Hashes are versioned (`pbkdf2-sha256$iter$hash`); older hashes are upgraded at the next login.
- `ClaimsPrincipalExtensions` (`Deliverance.Services/Authorization`) provides `User.GetUserId()`, used by controllers to pass the current user's `Guid` into services for ownership checks.
- A fallback authorization policy requires a signed-in user on every endpoint without `[Authorize]`/`[AllowAnonymous]`. `[AllowAnonymous]` is only on login/refresh/register in `AccessController` and the scout's claim/token in `ScoutController`; keep it that way.
- Admin-only rules are enforced in the services (`isAdmin` → `ForbiddenException`), including for insert/update, not only delete.

### Uploaded files

- Uploads live in `Deliverance.WebAPI/Uploads/` (not `wwwroot`; there is no `UseStaticFiles`) and are served only by endpoints that check access, e.g. `GET User/{id}/ProfileImage` (self or admin).
- `ImageService` checks size (5 MB), extension, declared MIME type and magic bytes, which must all agree, and names the file from the id and detected format.
- Clients get `UserResponse.ImagePath` as that endpoint's URL (Mapster config in `Program.cs`) and send the bearer token when loading it (`widgets/image_holder.dart`).

### Data layer

- `DeliveranceDbContext` (`Deliverance.Services/Database`) is the single EF Core context; entities live flat in that folder (no per-feature subfolders).
- `DeliveranceSeed` seeds initial data.
- Migrations live in `Deliverance.Services/Migrations` and target `DB_CONNECTION_STRING` from `.env`.

Services and their interfaces live directly under `Deliverance.Services/` (e.g. `UserService.cs` + `IUserService.cs`). Every file declares the namespace that matches its folder (`Deliverance.Services.Database`, `Deliverance.Services.ReportStateMachine`, ...).

- Child collections in update requests are merged with `CollectionSync.Sync` (one shared helper; don't copy it).
- Report edits go through the state machine: `BaseReportState.ApplyUpdateAsync` holds the update logic once, `DraftReportState`/`UnseenReportState` only choose the resulting status, and `LoadReportAsync` is the one query that loads a report with its parts.

## Code style

- No comments in the source (C#, Dart, YAML): names should explain the code; explanations go in this file. Analyzer directives are the only exception, and `// ignore:` is used only when there is no clean fix.
- No dead code, template leftovers, `NotImplementedException`/`NotSupportedException` stubs or duplicated helpers. Dart files are `snake_case`.
- Flutter: independent requests run in parallel with `Future.wait`; images load from URLs, never base64 decoded in `build()`.

## Flutter app architecture

Both `deliverance_mobile` and `deliverance_desktop` follow the same layered pattern:

- `providers/` — `ChangeNotifier`-based state, one per resource, extending `BaseProvider<T>` (`providers/base_provider.dart`). `ApiProvider` (same file) holds the HTTP plumbing: auth headers, query-string building for search filters, error parsing, and 401 handling via `sendWithRetry`, which calls `AuthProvider.instance.refreshToken()` and retries once before sending the user to the login screen. `BaseProvider<T>` extends it with the generic verbs (`get`/`getById`/`insert`/`update`/`remove`) and an abstract `fromJson`. A provider that doesn't return JSON models (e.g. `PdfReportProvider`) extends `ApiProvider` directly.
- `models/` — plain Dart models with hand-written or generated (`*.g.dart`, via `json_annotation`) `fromJson`/`toJson`; `*.multipart.dart` variants exist for endpoints that accept multipart form data (e.g. image upload on user insert/update).
- `screens/` — UI screens, registered with `MultiProvider` in `main.dart`.
- `layouts/`, `widgets/`, `themes/`, `utils/` — shared chrome, reusable widgets, theming, and small helpers (e.g. API error parsing in `utils/api_client_exception.dart`).
- API base URL and other environment-specific values are passed via `--dart-define`, not hardcoded per-environment config files.

When adding a new resource end-to-end, the usual path is: add entity to `DeliveranceDbContext` + migration -> add Request/Response DTOs in `Deliverance.Model` -> add `I<X>Service`/`<X>Service` extending the base services + validators -> add controller extending `BaseCRUDController`/`BaseReadController` -> wire DI registrations in `Program.cs` -> add matching Dart model + provider (extending `BaseProvider`) + screen in each Flutter app that needs it.
