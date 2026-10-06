using Deliverance.Model.Enums;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services.Database;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
namespace Deliverance.Services
{
    public class AccessManager : IAccessManager
    {
        private readonly IUserService _userService;
        private readonly IConfiguration _configuration;
        private readonly ICryptoService _cryptoService;
        private readonly IRefreshTokenService _refreshTokenService;
        private readonly DeliveranceDbContext _dbContext;
        private readonly IValidator<UserPasswordChangeRequest> _passwordChangeValidator;

        public AccessManager(IUserService userService, IConfiguration configuration, ICryptoService cryptoService,
            IRefreshTokenService refreshTokenService, DeliveranceDbContext dbContext,
            IValidator<UserPasswordChangeRequest> passwordChangeValidator)
        {
            _userService = userService;
            _configuration = configuration;
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
                throw new ClientException("User does not exist inside the database");
            }

            var validPassword = _cryptoService.Verify(user.PasswordHash, user.PasswordSalt, request.OldPassword);
            if (!validPassword)
            {
                throw new ClientException("Incorrect current password");
            }

            var salt = _cryptoService.GenerateSlat();
            user.PasswordSalt = salt;
            user.PasswordHash = _cryptoService.GenerateHash(request.NewPassword, salt);
            await _dbContext.SaveChangesAsync();

            await _refreshTokenService.DeleteAllUserRefreshTokensAsync(user.UUID);
        }

        public Task<UserLoginResponse> LoginAsync(UserLoginRequest request)
            => AuthenticateAsync(request, requireAdmin: false);

        public Task<UserLoginResponse> AdminLoginAsync(UserLoginRequest request)
            => AuthenticateAsync(request, requireAdmin: true);

        private async Task<UserLoginResponse> AuthenticateAsync(UserLoginRequest request, bool requireAdmin)
        {
            if (string.IsNullOrWhiteSpace(request.Username))
            {
                throw new ClientException("Username is required");
            }
            var user = await _userService.GetByUsernameAsync(request.Username);

            // Same message for an unknown user and a wrong password, so the
            // response doesn't reveal which usernames exist.
            if (user == null || !_cryptoService.Verify(user.PasswordHash, user.PasswordSalt, request.Password))
            {
                throw new ClientException("Wrong username or password");
            }

            if (requireAdmin && user.RoleId != (int)RoleEnum.Admin)
            {
                throw new ClientException("Only admin accounts can access this application.");
            }

            var accessToken = GenerateToken(user);
            var refreshTokenValue = GenerateRefreshToken();

            var refreshToken = new RefreshTokens
            {
                UserUUID = user.UUID,
                Token = refreshTokenValue,
                ExpiresAt = DateTime.UtcNow.AddDays(7)
            };

            await _refreshTokenService.InsertAsync(refreshToken);

            return new UserLoginResponse
            {
                Accesstoken = accessToken,
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
                throw new ClientException("Refresh token is required");
            }

            var refreshToken = await _refreshTokenService.GetStoredTokenAsync(request.RefreshToken);

            if (refreshToken == null)
            {
                throw new ClientException("Invalid refresh token");
            }

            if (refreshToken.ExpiresAt < DateTime.UtcNow)
            {
                throw new ClientException("Refresh token has expired");
            }

            var user = await _userService.GetByUUID(refreshToken.UserUUID);

            if (requireAdmin && user.RoleId != (int)RoleEnum.Admin)
            {
                throw new ClientException("Only admin accounts can access this application.");
            }

            await _refreshTokenService.DeleteAllUserRefreshTokensAsync(user.UUID);

            var accessToken = GenerateToken(user);
            var refreshTokenValue = GenerateRefreshToken();

            var token = new RefreshTokens
            {
                UserUUID = user.UUID,
                Token = refreshTokenValue,
                ExpiresAt = DateTime.UtcNow.AddDays(7)
            };

            await _refreshTokenService.InsertAsync(token);

            return new UserLoginResponse
            {
                Accesstoken = accessToken,
                Refreshtoken = refreshTokenValue
            };

        }

        private string GenerateToken(UserResponse user)
        {
            string secretKeyString = _configuration["JwtToken:SecretKey"] ?? string.Empty;
            var issuer = _configuration["JwtToken:Issuer"];
            var audience = _configuration["JwtToken:Audience"];
            var durationInMinutes = int.Parse(_configuration["JwtToken:DurationInMinutes"] ?? "1");

            var secretKey = Encoding.ASCII.GetBytes(secretKeyString);

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, user.UUID.ToString()),
                    new Claim(ClaimTypes.GivenName, user.FirstName ?? string.Empty),
                    new Claim(ClaimTypes.Surname, user.LastName ?? string.Empty),
                    new Claim(ClaimTypes.Email, user.Email ?? string.Empty),
                    new Claim(ClaimTypes.Role, user.RoleId.ToString() ?? "1"),
                }),
                Expires = DateTime.UtcNow.AddMinutes(durationInMinutes),
                Issuer = issuer,
                Audience = audience,
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(secretKey), SecurityAlgorithms.HmacSha256Signature)
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
