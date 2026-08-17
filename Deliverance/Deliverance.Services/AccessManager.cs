using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services.Database;
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

        public AccessManager(IUserService userService, IConfiguration configuration, ICryptoService cryptoService, IRefreshTokenService refreshTokenService)
        {
            _userService = userService;
            _configuration = configuration;
            _cryptoService = cryptoService;
            _refreshTokenService = refreshTokenService;
        }

        public async Task<UserLoginResponse> LoginAsync(UserLoginRequest request)
        {


            var user = new UserSensitiveResponse();
            if (!string.IsNullOrWhiteSpace(request.Username))
            {
                user = await _userService.GetByUsernameAsync(request.Username);
            }
            else if(!string.IsNullOrWhiteSpace(request.Email))
            {
                user =  await _userService.GetByUsernameAsync(request.Email);
            }
            else
            {
                throw new ClientException("Username or email is requried");
            }

            if (user == null)
            {
                throw new ClientException($"User with {request.Username} doesn't exist");
            }

            var validPassword = _cryptoService.Verify(user.PasswordHash, user.PasswordSalt, request.Password);
            if (!validPassword)
            {
                throw new ClientException("Wrong credential");
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

        public async Task<UserLoginResponse> LoginWithRefreshTokenAsync(RefreshAccessTokenRequest request)
        {
            if (string.IsNullOrEmpty(request.RefreshToken))
            {
                throw new Exception("Refresh token is required");
            }

            var refreshToken = await _refreshTokenService.GetStoredTokenAsync(request.RefreshToken);

            if (refreshToken == null)
            {
                throw new Exception("Invalid refresh token");
            }

            if (refreshToken.ExpiresAt < DateTime.UtcNow)
            {
                throw new Exception("Refresh token has expired");
            }

            var user = await _userService.GetByUUID(refreshToken.UserUUID);

            if (user == null)
            {
                throw new Exception("User not found");
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
