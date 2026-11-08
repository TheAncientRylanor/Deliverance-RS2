using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.Text;

namespace Deliverance.Services.Configuration
{
    public sealed class DeliveranceSettings
    {
        public required string ApiUrl { get; init; }
        public required string ConnectionString { get; init; }
        public required AuthSettings Auth { get; init; }
        public required RabbitMqSettings RabbitMq { get; init; }
        public required OllamaSettings Ollama { get; init; }
        public required DisplayTimeZone DisplayTimeZone { get; init; }

        public static DeliveranceSettings Load(IConfiguration configuration) => new()
        {
            ApiUrl = configuration.GetRequired("API_URL"),
            ConnectionString = configuration.GetRequired("DB_CONNECTION_STRING"),
            Auth = new AuthSettings
            {
                Issuer = configuration.GetRequired("JWT_ISSUER"),
                Audience = configuration.GetRequired("JWT_AUDIENCE"),
                SigningKey = new SymmetricSecurityKey(configuration.GetSigningKeyBytes()),
                AccessTokenLifetime = TimeSpan.FromMinutes(configuration.GetRequiredInt("JWT_DURATION_MINUTES")),
                RefreshTokenLifetime = TimeSpan.FromDays(configuration.GetRequiredInt("REFRESH_TOKEN_DURATION_DAYS")),
                ScoutTokenLifetime = TimeSpan.FromMinutes(configuration.GetRequiredInt("SCOUT_TOKEN_DURATION_MINUTES")),
                ScoutEnrollmentTokenLifetime = TimeSpan.FromMinutes(configuration.GetRequiredInt("SCOUT_ENROLLMENT_TOKEN_DURATION_MINUTES")),
            },
            RabbitMq = new RabbitMqSettings
            {
                HostName = configuration.GetRequired("RABBITMQ_HOST"),
                Port = configuration.GetRequiredInt("RABBITMQ_PORT"),
                UserName = configuration.GetRequired("RABBITMQ_USERNAME"),
                Password = configuration.GetRequired("RABBITMQ_PASSWORD"),
            },
            Ollama = new OllamaSettings
            {
                BaseUrl = configuration.GetRequiredUri("OLLAMA_BASE_URL"),
                Model = configuration.GetRequired("OLLAMA_MODEL"),
                Timeout = TimeSpan.FromMinutes(configuration.GetRequiredInt("OLLAMA_TIMEOUT_MINUTES")),
            },
            DisplayTimeZone = new DisplayTimeZone(configuration.GetRequiredTimeZone("DISPLAY_TIME_ZONE")),
        };
    }

    public sealed class AuthSettings
    {
        public required string Issuer { get; init; }
        public required string Audience { get; init; }
        public required SymmetricSecurityKey SigningKey { get; init; }
        public required TimeSpan AccessTokenLifetime { get; init; }
        public required TimeSpan RefreshTokenLifetime { get; init; }
        public required TimeSpan ScoutTokenLifetime { get; init; }
        public required TimeSpan ScoutEnrollmentTokenLifetime { get; init; }
    }

    public sealed class RabbitMqSettings
    {
        public required string HostName { get; init; }
        public required int Port { get; init; }
        public required string UserName { get; init; }
        public required string Password { get; init; }
    }

    public sealed class OllamaSettings
    {
        public required Uri BaseUrl { get; init; }
        public required string Model { get; init; }
        public required TimeSpan Timeout { get; init; }
    }

    internal static class ConfigurationExtensions
    {
        public static byte[] GetSigningKeyBytes(this IConfiguration configuration)
        {
            var bytes = Encoding.UTF8.GetBytes(configuration.GetRequired("JWT_SECRET_KEY"));
            if (bytes.Length < 32)
            {
                throw new InvalidOperationException("JWT_SECRET_KEY must be at least 32 characters long. Use a long random value in the .env file.");
            }
            return bytes;
        }

        public static string GetRequired(this IConfiguration configuration, string key)
        {
            var value = configuration[key];
            if (string.IsNullOrWhiteSpace(value))
            {
                throw new InvalidOperationException($"{key} is missing. Add it to the .env file in the repository root.");
            }
            return value;
        }

        public static int GetRequiredInt(this IConfiguration configuration, string key)
        {
            var value = configuration.GetRequired(key);
            if (!int.TryParse(value, out var number) || number <= 0)
            {
                throw new InvalidOperationException($"{key} in .env must be a whole number above 0, but it is '{value}'.");
            }
            return number;
        }

        public static TimeZoneInfo GetRequiredTimeZone(this IConfiguration configuration, string key)
        {
            var value = configuration.GetRequired(key);
            if (!TimeZoneInfo.TryFindSystemTimeZoneById(value, out var zone))
            {
                throw new InvalidOperationException($"{key} in .env must be a time zone such as Europe/Sarajevo, but it is '{value}'.");
            }
            return zone;
        }

        public static Uri GetRequiredUri(this IConfiguration configuration, string key)
        {
            var value = configuration.GetRequired(key);
            if (!Uri.TryCreate(value, UriKind.Absolute, out var uri))
            {
                throw new InvalidOperationException($"{key} in .env must be a full URL such as http://localhost:11434/, but it is '{value}'.");
            }
            return uri;
        }
    }
}
