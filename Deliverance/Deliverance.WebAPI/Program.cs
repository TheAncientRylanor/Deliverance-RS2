using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services;
using Deliverance.Services.Database;
using Deliverance.Services.Messaging;
using Deliverance.Services.ServiceStateMachine;
using Deliverance.Services.Validators;
using Deliverance.WebAPI.BackgroundServices;
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
builder.Services.AddScoped<IDeviceService,DeviceService>();
builder.Services.AddScoped<IRefreshTokenService, RefreshTokenService>();
builder.Services.AddScoped<IAccessManager, AccessManager>();
builder.Services.AddScoped<IOfficeService, OfficeService>();
builder.Services.AddScoped<IContactsService,ContactsService>();
builder.Services.AddScoped<IReportService,ReportService>();
builder.Services.AddScoped<BaseReportState>();
builder.Services.AddScoped<DraftReportState>();
builder.Services.AddScoped<UnseenReportState>();
builder.Services.AddScoped<SeenReportState>();
builder.Services.AddScoped<ClearedReportState>();
builder.Services.AddScoped<IOccuranceService,OccuranceService>();
builder.Services.AddScoped<IReportStatisticsService, ReportStatisticsService>();

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
builder.Services.AddOpenApi();
builder.Services.AddMapster();
TypeAdapterConfig<ReportOccurance, ReportOccuranceResponse>.NewConfig()
    .Map(dest => dest.Question, src => src.Occurance != null ? src.Occurance.Question : string.Empty);
TypeAdapterConfig<DeviceReport,DeviceReportsResponse>.NewConfig().
    Map(dest=> dest.Name, src=>src.Device != null ? src.Device.Name : string.Empty);
TypeAdapterConfig<OfficeReport, OfficeReportResponse>.NewConfig()
    .Map(dest => dest.Name, src => src.Office != null ? src.Office.Name : string.Empty);
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.RequireHttpsMetadata = false;
        o.SaveToken = true;
        o.TokenValidationParameters = new TokenValidationParameters
        {
            ValidIssuer = builder.Configuration["JwtToken:Issuer"],
            ValidAudience = builder.Configuration["JwtToken:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["JwtToken:SecretKey"] ?? string.Empty)),
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ClockSkew = TimeSpan.Zero
        };
    });
builder.Services.AddAuthorization();


builder.Services.AddEndpointsApiExplorer();
var app = builder.Build();
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

app.Run();
