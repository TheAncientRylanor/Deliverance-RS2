using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services;
using Deliverance.Services.Database;
using Deliverance.Services.Messaging;
using Deliverance.Services.ServiceStateMachine;
using Deliverance.Services.Validators;
using Deliverance.WebAPI.BackgroundServices;
using Deliverance.WebAPI.Hubs;
using FluentValidation;
using Mapster;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using RabbitMQ.Client;
using Scalar.AspNetCore;
using System;
using System.Text;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddHttpContextAccessor();
// Add services to the container.
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<DeliveranceDbContext>(options =>
    options.UseSqlServer(connectionString)
);
builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi7

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
builder.Services.AddScoped<IOccuranceService, OccuranceService>();
builder.Services.AddScoped<IExecutionCommandService, ExecutionCommandService>();
builder.Services.AddScoped<IReportStatisticsService, ReportStatisticsService>();
builder.Services.AddScoped<IDeviceRecommendationService, DeviceRecommendationService>();
builder.Services.AddScoped<IScoutEnrollmentService, ScoutEnrollmentService>();
builder.Services.AddScoped<IScoutAccessManager, ScoutAccessManager>();
builder.Services.AddScoped<IScoutService, ScoutService>();
// Registers ChatBotService with an HttpClient pointed at Ollama.
builder.Services.AddHttpClient<IChatBotService, ChatBotService>(client =>
{
    client.BaseAddress = new Uri(builder.Configuration["Ollama:BaseUrl"] ?? "http://localhost:11434/");
    // A local model on the CPU can take well over the default 100 seconds to answer.
    client.Timeout = TimeSpan.FromMinutes(3);
});
builder.Services.AddSingleton<IScoutEnrollmentNotifier, SignalRScoutEnrollmentNotifier>();
builder.Services.AddSingleton<IDeviceNotifier, SinalRDeviceNotifier>();
builder.Services.AddSingleton<IScoutNotifier, SignalRScoutNotifier>();
builder.Services.AddSignalR();

builder.Services.AddSingleton<IConnection>(sp =>
{
    var configuration = sp.GetRequiredService<IConfiguration>();
    var factory = new ConnectionFactory
    {
        HostName = configuration["RabbitMq:HostName"] ?? "localhost",
        Port = int.Parse(configuration["RabbitMq:Port"] ?? "5672"),
        UserName = configuration["RabbitMq:UserName"] ?? "guest",
        Password = configuration["RabbitMq:Password"] ?? "guest"
    };
    return factory.CreateConnectionAsync().GetAwaiter().GetResult();
});
builder.Services.AddSingleton<IReportEventPublisher, RabbitMqReportEventPublisher>();
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
TypeAdapterConfig<ReportOccurance, ReportOccuranceResponse>.NewConfig()
    .Map(dest => dest.Question, src => src.Occurance != null ? src.Occurance.Question : string.Empty);
TypeAdapterConfig<DeviceReport, DeviceReportsResponse>.NewConfig().
    Map(dest => dest.Name, src => src.Device != null ? src.Device.Name : string.Empty);
// Devices are declared as the slim DeviceReportSensitiveResponse, but filled with
// full DeviceResponse objects for admins (OfficeService slims them for regular users).
// Done in AfterMapping because Mapster would otherwise copy them back to the declared type.
TypeAdapterConfig<Office, OfficeResponse>.NewConfig()
    .Ignore(dest => dest.Devices!)
    .AfterMapping((src, dest) => dest.Devices = src.Devices
        .Select(device => (DeviceReportSensitiveResponse)device.Adapt<DeviceResponse>())
        .ToList());
TypeAdapterConfig<OfficeReport, OfficeReportResponse>.NewConfig()
    .Map(dest => dest.Name, src => src.Office != null ? src.Office.Name : string.Empty);


// User and scout tokens share issuer and signing key and differ only in audience.
TokenValidationParameters CreateTokenValidationParameters(string? audience) => new()
{
    ValidIssuer = builder.Configuration["JwtToken:Issuer"],
    ValidAudience = audience,
    IssuerSigningKey = new SymmetricSecurityKey(
        Encoding.UTF8.GetBytes(builder.Configuration["JwtToken:SecretKey"] ?? string.Empty)),
    ValidateIssuer = true,
    ValidateAudience = true,
    ValidateLifetime = true,
    ValidateIssuerSigningKey = true,
    ClockSkew = TimeSpan.Zero
};
// WebSockets can't carry an Authorization header, so SignalR clients send the
// token as ?access_token=... Only accept it there for hub requests.
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
    // Default scheme: users. Every plain [Authorize] uses it, so scout tokens get 401 there.
    .AddJwtBearer(o =>
    {
        o.RequireHttpsMetadata = false;
        o.SaveToken = true;
        o.TokenValidationParameters = CreateTokenValidationParameters(builder.Configuration["JwtToken:Audience"]);
        o.Events = new JwtBearerEvents
        {
            OnMessageReceived = ReadHubAccessToken
        };
    })
    // Scout scheme: only endpoints that ask for it with [Authorize(AuthenticationSchemes = ...)].
    .AddJwtBearer(ScoutAuthDefaults.Scheme, o =>
    {
        o.RequireHttpsMetadata = false;
        o.TokenValidationParameters = CreateTokenValidationParameters(ScoutAuthDefaults.Audience);
        o.Events = new JwtBearerEvents
        {
            OnMessageReceived = ReadHubAccessToken,
            // Scout tokens live for TokenLifetime, so a token issued before the scout was
            // disabled (or its device deleted) would keep working. Reject it right away.
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
builder.Services.AddAuthorization();


builder.Services.AddEndpointsApiExplorer();
var app = builder.Build();

// Dev only, and exits instead of starting the API:
// dotnet run --project Deliverance.WebAPI -- --seed-test-data
if (args.Contains("--seed-test-data") && app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<DeliveranceDbContext>();
    var seeded = await dbContext.SeedTestDataAsync();
    Console.WriteLine(seeded ? "Test data added." : "Test data already exists, nothing was added.");
    return;
}

app.UseMiddleware<ExceptionHandlingMiddleware>();
// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();

}

app.UseStaticFiles();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapHub<EnrollmentHub>("/hubs/enrollment");
app.MapHub<ScoutHub>("/hubs/scout");
app.MapHub<DeviceHub>("/hubs/device");

app.Run();
