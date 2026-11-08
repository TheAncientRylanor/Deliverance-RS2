using Deliverance.WebAPI.Middlewares;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services;
using Deliverance.Services.Configuration;
using Deliverance.Services.Database;
using Deliverance.Services.Messaging;
using Deliverance.Services.ReportStateMachine;
using Deliverance.Services.Validators;
using Deliverance.WebAPI.BackgroundServices;
using Deliverance.WebAPI.Hubs;
using DotNetEnv;
using FluentValidation;
using Mapster;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using RabbitMQ.Client;
using Scalar.AspNetCore;

Env.NoClobber().TraversePath().Load();
var builder = WebApplication.CreateBuilder(args);
var settings = DeliveranceSettings.Load(builder.Configuration);
builder.WebHost.UseUrls(settings.ApiUrl);
builder.Services.AddSingleton(settings.Auth);
builder.Services.AddSingleton(settings.RabbitMq);
builder.Services.AddSingleton(settings.Ollama);
builder.Services.AddSingleton(settings.DisplayTimeZone);
builder.Services.AddHttpContextAccessor();
builder.Services.AddMemoryCache();
builder.Services.AddDbContext<DeliveranceDbContext>(options =>
    options.UseSqlServer(settings.ConnectionString)
);
builder.Services.AddControllers(options =>
        options.SuppressImplicitRequiredAttributeForNonNullableReferenceTypes = true)
    .ConfigureApiBehaviorOptions(options =>
        options.InvalidModelStateResponseFactory = context =>
        {
            var errors = context.ModelState
                .Where(entry => entry.Value?.Errors.Count > 0)
                .ToDictionary(
                    entry => entry.Key.TrimStart('$', '.'),
                    entry => entry.Value!.Errors
                        .Select(error => error.Exception != null || error.ErrorMessage.Contains("JSON")
                            ? $"{(entry.Key.TrimStart('$', '.') is { Length: > 0 } field ? field : "The request")} has a value in the wrong format."
                            : error.ErrorMessage)
                        .ToList());
            return new BadRequestObjectResult(new ValidationErrorResponse
            {
                Message = errors.SelectMany(entry => entry.Value).Distinct().ToList(),
                Errors = errors,
            });
        });

builder.Services.AddScoped<ICryptoService, CryptoService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IDeviceService, DeviceService>();
builder.Services.AddScoped<IRefreshTokenService, RefreshTokenService>();
builder.Services.AddScoped<IAccessManager, AccessManager>();
builder.Services.AddScoped<IOfficeService, OfficeService>();
builder.Services.AddScoped<IContactsService, ContactsService>();
builder.Services.AddScoped<IReportService, ReportService>();
builder.Services.AddScoped<BaseReportState>();
builder.Services.AddScoped<DraftReportState>();
builder.Services.AddScoped<UnseenReportState>();
builder.Services.AddScoped<SeenReportState>();
builder.Services.AddScoped<ClearedReportState>();
builder.Services.AddScoped<IOccurrenceService, OccurrenceService>();
builder.Services.AddScoped<IExecutionCommandService, ExecutionCommandService>();
builder.Services.AddScoped<IReportStatisticsService, ReportStatisticsService>();
builder.Services.AddScoped<IDeviceRecommendationService, DeviceRecommendationService>();
builder.Services.AddScoped<IScoutEnrollmentService, ScoutEnrollmentService>();
builder.Services.AddScoped<IScoutAccessManager, ScoutAccessManager>();
builder.Services.AddScoped<IScoutService, ScoutService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IPdfReportService, PdfReportService>();
QuestPDF.Settings.License = QuestPDF.Infrastructure.LicenseType.Community;
builder.Services.AddHttpClient<IChatBotService, ChatBotService>(client =>
{
    client.BaseAddress = settings.Ollama.BaseUrl;
    client.Timeout = settings.Ollama.Timeout;
});
builder.Services.AddSingleton<IScoutEnrollmentNotifier, SignalRScoutEnrollmentNotifier>();
builder.Services.AddSingleton<IDeviceNotifier, SignalRDeviceNotifier>();
builder.Services.AddSingleton<IScoutNotifier, SignalRScoutNotifier>();
builder.Services.AddSingleton<INotificationNotifier, SignalRNotificationNotifier>();
builder.Services.AddSignalR();

builder.Services.AddSingleton<IConnection>(sp =>
{
    var factory = new ConnectionFactory
    {
        HostName = settings.RabbitMq.HostName,
        Port = settings.RabbitMq.Port,
        UserName = settings.RabbitMq.UserName,
        Password = settings.RabbitMq.Password,
        ClientProvidedName = "Deliverance.WebAPI",
    };
    var logger = sp.GetRequiredService<ILoggerFactory>().CreateLogger("RabbitMQ");
    return RabbitMqConnection.ConnectAsync(factory, logger).GetAwaiter().GetResult();
});
builder.Services.AddSingleton<ReportEventQueue>();
builder.Services.AddSingleton<IReportEventPublisher>(sp => sp.GetRequiredService<ReportEventQueue>());
builder.Services.AddSingleton<RabbitMqReportEventSender>();
builder.Services.AddHostedService<ReportEventPublisherWorker>();
builder.Services.AddHostedService<ReportStatisticsConsumer>();
builder.Services.AddScoped<IValidator<UserInsertRequest>, UserInsertValidator>();
builder.Services.AddScoped<IValidator<UserUpdateRequest>, UserUpdateValidator>();
builder.Services.AddScoped<IValidator<UserPasswordChangeRequest>, UserPasswordChangeValidator>();
builder.Services.AddScoped<IValidator<ContactsInsertRequest>, ContactsInsertValidator>();
builder.Services.AddScoped<IValidator<ContactsUpdateRequest>, ContactsUpdateValidator>();
builder.Services.AddScoped<IValidator<UserUpdateRequest>, UserUpdateValidator>();
builder.Services.AddScoped<IValidator<DeviceInsertRequest>, DeviceInsertValidator>();
builder.Services.AddScoped<IValidator<DeviceUpdateRequest>, DeviceUpdateValidator>();
builder.Services.AddScoped<IValidator<OfficeInsertRequest>, OfficeInsertValidator>();
builder.Services.AddScoped<IValidator<OfficeUpdateRequest>, OfficeUpdateValidator>();
builder.Services.AddScoped<IValidator<ReportInsertRequest>, ReportInsertValidator>();
builder.Services.AddScoped<IValidator<ReportUpdateRequest>, ReportUpdateValidator>();
builder.Services.AddScoped<IValidator<ReportClearRequest>, ReportClearValidator>();
builder.Services.AddScoped<IValidator<ScoutEnrollmentClaimRequest>, ScoutEnrollmentClaimValidator>();
builder.Services.AddScoped<IValidator<ScoutCommandInsertRequest>, ScoutCommandInsertValidator>();
builder.Services.AddScoped<IValidator<ScoutCommandResultRequest>, ScoutCommandResultValidator>();
builder.Services.AddScoped<IValidator<ScoutLogBatchRequest>, ScoutLogBatchValidator>();
builder.Services.AddScoped<IValidator<ChatBotMessageInsertRequest>, ChatBotMessageInsertValidator>();
builder.Services.AddScoped<IValidator<ChatBotMessageUpdateRequest>, ChatBotMessageUpdateValidator>();
builder.Services.AddOpenApi();
builder.Services.AddMapster();
TypeAdapterConfig<ReportOccurrence, ReportOccurrenceResponse>.NewConfig()
    .Map(dest => dest.Question, src => src.Occurrence != null ? src.Occurrence.Question : string.Empty);
TypeAdapterConfig<DeviceReport, DeviceReportsResponse>.NewConfig().
    Map(dest => dest.Name, src => src.Device != null ? src.Device.Name : string.Empty);
TypeAdapterConfig<Office, OfficeResponse>.NewConfig()
    .Ignore(dest => dest.Devices!)
    .AfterMapping((src, dest) => dest.Devices = src.Devices
        .Select(device => (DeviceReportSensitiveResponse)device.Adapt<DeviceResponse>())
        .ToList());
TypeAdapterConfig<User, UserResponse>.NewConfig()
    .Map(dest => dest.ImagePath, src => UserService.ProfileImageUrl(src));
TypeAdapterConfig<User, UserReportResponse>.NewConfig()
    .Map(dest => dest.ImagePath, src => UserService.ProfileImageUrl(src));
TypeAdapterConfig<OfficeReport, OfficeReportResponse>.NewConfig()
    .Map(dest => dest.Name, src => src.Office != null ? src.Office.Name : string.Empty);


TokenValidationParameters CreateTokenValidationParameters(string audience) => new()
{
    ValidIssuer = settings.Auth.Issuer,
    ValidAudience = audience,
    IssuerSigningKey = settings.Auth.SigningKey,
    ValidateIssuer = true,
    ValidateAudience = true,
    ValidateLifetime = true,
    ValidateIssuerSigningKey = true,
    RequireSignedTokens = true,
    RequireExpirationTime = true,
    ValidAlgorithms = [SecurityAlgorithms.HmacSha256],
    ClockSkew = TimeSpan.Zero
};
Task ReadHubAccessToken(MessageReceivedContext context)
{
    var accessToken = context.Request.Query["access_token"];
    if (!string.IsNullOrEmpty(accessToken) && context.Request.Path.StartsWithSegments("/hubs"))
    {
        context.Token = accessToken;
    }
    return Task.CompletedTask;
}
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.RequireHttpsMetadata = false;
        o.SaveToken = true;
        o.TokenValidationParameters = CreateTokenValidationParameters(settings.Auth.Audience);
        o.Events = new JwtBearerEvents
        {
            OnMessageReceived = ReadHubAccessToken,
            OnTokenValidated = async context =>
            {
                var userId = context.Principal!.FindUserId();
                var sessionId = context.Principal!.FindSessionId();
                if (userId is null || sessionId is null)
                {
                    context.Fail("The token has no session.");
                    return;
                }
                var dbContext = context.HttpContext.RequestServices.GetRequiredService<DeliveranceDbContext>();
                var now = DateTime.UtcNow;
                var isActive = await dbContext.RefreshTokens.AnyAsync(
                    t => t.Id == sessionId && t.UserUUID == userId && t.ExpiresAt > now);
                if (!isActive)
                {
                    context.Fail("This session has ended. Please sign in again.");
                }
            }
        };
    })
    .AddJwtBearer(ScoutAuthDefaults.Scheme, o =>
    {
        o.RequireHttpsMetadata = false;
        o.TokenValidationParameters = CreateTokenValidationParameters(ScoutAuthDefaults.Audience);
        o.Events = new JwtBearerEvents
        {
            OnMessageReceived = ReadHubAccessToken,
            OnTokenValidated = async context =>
            {
                var scoutId = context.Principal!.GetScoutId();
                var dbContext = context.HttpContext.RequestServices.GetRequiredService<DeliveranceDbContext>();
                var isActive = await dbContext.Scouts.AnyAsync(s => s.Id == scoutId && !s.IsDisabled);
                if (!isActive)
                {
                    context.Fail("This scout is disabled or no longer exists.");
                }
            }
        };
    });
builder.Services.AddAuthorization(options =>
    options.FallbackPolicy = new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build());


builder.Services.AddEndpointsApiExplorer();
var app = builder.Build();

if (args.Contains("--seed-test-data") && app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<DeliveranceDbContext>();
    var seeded = await dbContext.SeedTestDataAsync();
    if (seeded)
    {
        Console.WriteLine("Test data added.");
    }
    else
    {
        var filled = await dbContext.FillTestClearDetailsAsync();
        Console.WriteLine($"Test data already exists, nothing was added. Filled in clear details on {filled} seeded reports.");
    }
    return;
}

app.UseMiddleware<ExceptionHandlingMiddleware>();
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi().AllowAnonymous();
    app.MapScalarApiReference().AllowAnonymous();
}

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapHub<EnrollmentHub>("/hubs/enrollment");
app.MapHub<ScoutHub>("/hubs/scout");
app.MapHub<DeviceHub>("/hubs/device");
app.MapHub<NotificationHub>("/hubs/notification");

app.Run();
