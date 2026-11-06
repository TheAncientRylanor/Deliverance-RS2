using Deliverance.Model.Enums;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Deliverance.Services
{
    public class ScoutAccessManager : IScoutAccessManager
    {
        private readonly DeliveranceDbContext _dbContext;
        private readonly IConfiguration _configuration;

        public ScoutAccessManager(DeliveranceDbContext dbContext, IConfiguration configuration)
        {
            _dbContext = dbContext;
            _configuration = configuration;
        }

        public async Task<ScoutTokenResponse> CreateTokenAsync(ScoutTokenRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Secret))
            {
                throw new UnauthorizedAccessException("Scout secret is missing.");
            }

            var secretHash = ScoutSecrets.Hash(request.Secret.Trim());
            var enrollment = await _dbContext.ScoutEnrollments.AsNoTracking()
                .Where(x => x.SecretHash == secretHash)
                .Select(x => new { x.Status, x.ScoutId, IsDisabled = x.Scout != null && x.Scout.IsDisabled })
                .FirstOrDefaultAsync();

            if (enrollment?.Status == ScoutEnrollmentStatusEnum.Claimed)
            {
                return new ScoutTokenResponse { Status = ScoutTokenStatusEnum.PendingApproval };
            }
            // ScoutId is cleared when the device (and with it the Scout) is deleted,
            // which revokes the secret.
            if (enrollment?.Status != ScoutEnrollmentStatusEnum.Completed || enrollment.ScoutId is not int scoutId)
            {
                throw new UnauthorizedAccessException("Scout secret is invalid or was revoked.");
            }
            // The secret stays valid, so the scout can keep polling until it is enabled again.
            if (enrollment.IsDisabled)
            {
                return new ScoutTokenResponse { Status = ScoutTokenStatusEnum.Disabled };
            }

            var expiresAt = DateTime.UtcNow.Add(ScoutAuthDefaults.TokenLifetime);
            return new ScoutTokenResponse
            {
                Status = ScoutTokenStatusEnum.Active,
                AccessToken = GenerateToken(scoutId, expiresAt),
                ExpiresAt = expiresAt,
            };
        }

        private string GenerateToken(int scoutId, DateTime expiresAt)
        {
            // Same issuer and signing key as user tokens, but the scout audience,
            // which only the Scout scheme in Program.cs accepts.
            var secretKey = Encoding.UTF8.GetBytes(_configuration["JwtToken:SecretKey"] ?? string.Empty);
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ScoutAuthDefaults.ScoutIdClaim, scoutId.ToString()),
                    new Claim(ClaimTypes.Role, ((int)RoleEnum.Scout).ToString()),
                }),
                Expires = expiresAt,
                Issuer = _configuration["JwtToken:Issuer"],
                Audience = ScoutAuthDefaults.Audience,
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(secretKey), SecurityAlgorithms.HmacSha256Signature)
            };
            var tokenHandler = new JwtSecurityTokenHandler();
            return tokenHandler.WriteToken(tokenHandler.CreateToken(tokenDescriptor));
        }
    }
}
