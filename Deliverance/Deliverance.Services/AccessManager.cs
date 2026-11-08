using Deliverance.Model.Enums;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services.Configuration;
using Deliverance.Services.Database;
using Deliverance.Services.Validators;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;

namespace Deliverance.Services
{
    public class AccessManager : IAccessManager
    {
        private readonly IUserService _userService;
        private readonly AuthSettings _authSettings;
        private readonly ICryptoService _cryptoService;
        private readonly IRefreshTokenService _refreshTokenService;
        private readonly DeliveranceDbContext _dbContext;
        private readonly IValidator<UserPasswordChangeRequest> _passwordChangeValidator;

        public AccessManager(IUserService userService, AuthSettings authSettings, ICryptoService cryptoService,
            IRefreshTokenService refreshTokenService, DeliveranceDbContext dbContext,
            IValidator<UserPasswordChangeRequest> passwordChangeValidator)
        {
            _userService = userService;
            _authSettings = authSettings;
            _cryptoService = cryptoService;
            _refreshTokenService = refreshTokenService;
            _dbContext = dbContext;
            _passwordChangeValidator = passwordChangeValidator;
        }

        public async Task ChangePasswordAsync(UserPasswordChangeRequest request, Guid userId)
        {
            await _passwordChangeValidator.ValidateAndThrowAsync(request);

            var user = await _dbContext.Users.FirstOrDefaultAsync(x => x.UUID == userId);
            if (user is null)
            {
                throw new NotFoundException("Your account no longer exists. Please sign in again.");
            }

            var validPassword = _cryptoService.Verify(user.PasswordHash, user.PasswordSalt, request.OldPassword);
            if (!validPassword)
            {
                throw FieldRules.FieldError(nameof(request.OldPassword), "The current password is incorrect.");
            }

            (user.PasswordHash, user.PasswordSalt) = _cryptoService.HashPassword(request.NewPassword);
            await _refreshTokenService.RemoveAllForUserAsync(user.UUID);
            await _dbContext.SaveChangesAsync();
        }

        public async Task LogoutAsync(Guid userId, int sessionId)
        {
            await _refreshTokenService.RemoveAsync(sessionId, userId);
            await _dbContext.SaveChangesAsync();
        }

        public Task<UserLoginResponse> LoginAsync(UserLoginRequest request)
            => AuthenticateAsync(request, requireAdmin: false);

        public Task<UserLoginResponse> AdminLoginAsync(UserLoginRequest request)
            => AuthenticateAsync(request, requireAdmin: true);

        private async Task<UserLoginResponse> AuthenticateAsync(UserLoginRequest request, bool requireAdmin)
        {
            if (string.IsNullOrWhiteSpace(request.Username))
            {
                throw new BusinessException("Username is required");
            }
            var user = await _userService.GetByUsernameAsync(request.Username);

            if (user == null || !_cryptoService.Verify(user.PasswordHash, user.PasswordSalt, request.Password))
            {
                throw new BusinessException("Wrong username or password");
            }

            if (requireAdmin && user.RoleId != (int)RoleEnum.Admin)
            {
                throw new BusinessException("Only admin accounts can access this application.");
            }

            if (_cryptoService.NeedsRehash(user.PasswordHash))
            {
                var entity = await _dbContext.Users.FirstAsync(u => u.UUID == user.UUID);
                (entity.PasswordHash, entity.PasswordSalt) = _cryptoService.HashPassword(request.Password);
            }

            await _refreshTokenService.RemoveExpiredForUserAsync(user.UUID);
            var refreshTokenValue = GenerateRefreshToken();
            var session = _refreshTokenService.Add(user.UUID, refreshTokenValue,
                DateTime.UtcNow.Add(_authSettings.RefreshTokenLifetime));
            await _dbContext.SaveChangesAsync();

            return new UserLoginResponse
            {
                Accesstoken = GenerateToken(user, session.Id),
                Refreshtoken = refreshTokenValue
            };
        }

        public Task<UserLoginResponse> LoginWithRefreshTokenAsync(RefreshAccessTokenRequest request)
            => RefreshAsync(request, requireAdmin: false);

        public Task<UserLoginResponse> AdminLoginWithRefreshTokenAsync(RefreshAccessTokenRequest request)
            => RefreshAsync(request, requireAdmin: true);

        private async Task<UserLoginResponse> RefreshAsync(RefreshAccessTokenRequest request, bool requireAdmin)
        {
            if (string.IsNullOrEmpty(request.RefreshToken))
            {
                throw new BusinessException("Your session is missing. Please sign in again.");
            }

            var session = await _refreshTokenService.GetStoredTokenAsync(request.RefreshToken);

            if (session == null)
            {
                throw new BusinessException("Your session is no longer valid. Please sign in again.");
            }

            if (session.ExpiresAt < DateTime.UtcNow)
            {
                throw new BusinessException("Your session has expired. Please sign in again.");
            }

            var user = await _userService.GetByUUID(session.UserUUID);

            if (requireAdmin && user.RoleId != (int)RoleEnum.Admin)
            {
                throw new BusinessException("Only admin accounts can access this application.");
            }

            var refreshTokenValue = GenerateRefreshToken();
            _refreshTokenService.Rotate(session, refreshTokenValue, DateTime.UtcNow.Add(_authSettings.RefreshTokenLifetime));
            await _dbContext.SaveChangesAsync();

            return new UserLoginResponse
            {
                Accesstoken = GenerateToken(user, session.Id),
                Refreshtoken = refreshTokenValue
            };
        }

        private string GenerateToken(UserResponse user, int sessionId)
        {
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, user.UUID.ToString()),
                    new Claim(ClaimTypes.GivenName, user.FirstName ?? string.Empty),
                    new Claim(ClaimTypes.Surname, user.LastName ?? string.Empty),
                    new Claim(ClaimTypes.Email, user.Email ?? string.Empty),
                    new Claim(ClaimTypes.Role, user.RoleId.ToString() ?? "1"),
                    new Claim(ClaimsPrincipalExtensions.SessionIdClaim, sessionId.ToString()),
                }),
                Expires = DateTime.UtcNow.Add(_authSettings.AccessTokenLifetime),
                Issuer = _authSettings.Issuer,
                Audience = _authSettings.Audience,
                SigningCredentials = new SigningCredentials(_authSettings.SigningKey, SecurityAlgorithms.HmacSha256)
            };
            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);

            return tokenHandler.WriteToken(token);
        }

        private static string GenerateRefreshToken()
        {
            var randombytes = RandomNumberGenerator.GetBytes(64);
            return Convert.ToBase64String(randombytes);
        }
    }
}
