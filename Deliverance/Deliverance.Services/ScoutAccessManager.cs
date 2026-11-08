using Deliverance.Model.Enums;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services.Configuration;
using Deliverance.Services.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace Deliverance.Services
{
    public class ScoutAccessManager : IScoutAccessManager
    {
        private readonly DeliveranceDbContext _dbContext;
        private readonly AuthSettings _authSettings;

        public ScoutAccessManager(DeliveranceDbContext dbContext, AuthSettings authSettings)
        {
            _dbContext = dbContext;
            _authSettings = authSettings;
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
            if (enrollment?.Status != ScoutEnrollmentStatusEnum.Completed || enrollment.ScoutId is not int scoutId)
            {
                throw new UnauthorizedAccessException("Scout secret is invalid or was revoked.");
            }
            if (enrollment.IsDisabled)
            {
                return new ScoutTokenResponse { Status = ScoutTokenStatusEnum.Disabled };
            }

            var expiresAt = DateTime.UtcNow.Add(_authSettings.ScoutTokenLifetime);
            return new ScoutTokenResponse
            {
                Status = ScoutTokenStatusEnum.Active,
                AccessToken = GenerateToken(scoutId, expiresAt),
                ExpiresAt = expiresAt,
            };
        }

        private string GenerateToken(int scoutId, DateTime expiresAt)
        {
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ScoutAuthDefaults.ScoutIdClaim, scoutId.ToString()),
                    new Claim(ClaimTypes.Role, ((int)RoleEnum.Scout).ToString()),
                }),
                Expires = expiresAt,
                Issuer = _authSettings.Issuer,
                Audience = ScoutAuthDefaults.Audience,
                SigningCredentials = new SigningCredentials(_authSettings.SigningKey, SecurityAlgorithms.HmacSha256)
            };
            var tokenHandler = new JwtSecurityTokenHandler();
            return tokenHandler.WriteToken(tokenHandler.CreateToken(tokenDescriptor));
        }
    }
}
