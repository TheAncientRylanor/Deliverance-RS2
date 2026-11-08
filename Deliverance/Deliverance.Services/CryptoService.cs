using System.Security.Cryptography;
using System.Text;

namespace Deliverance.Services
{
    public class CryptoService : ICryptoService
    {
        private const int Iterations = 600_000;
        private const int SaltSize = 16;
        private const int HashSize = 32;
        private const string Prefix = "pbkdf2-sha256";

        private const int LegacyIterations = 10_000;
        private const int LegacyHashSize = 20;

        public (string Hash, string Salt) HashPassword(string password)
        {
            var salt = RandomNumberGenerator.GetBytes(SaltSize);
            var hash = Rfc2898DeriveBytes.Pbkdf2(password, salt, Iterations, HashAlgorithmName.SHA256, HashSize);
            return ($"{Prefix}${Iterations}${Convert.ToBase64String(hash)}", Convert.ToBase64String(salt));
        }

        public bool Verify(string hash, string salt, string password)
        {
            if (string.IsNullOrEmpty(hash) || string.IsNullOrEmpty(salt) || password is null)
            {
                return false;
            }

            byte[] expected;
            byte[] actual;
            if (TryParse(hash, out var iterations, out var storedHash))
            {
                expected = storedHash;
                actual = Rfc2898DeriveBytes.Pbkdf2(password, Convert.FromBase64String(salt), iterations,
                    HashAlgorithmName.SHA256, storedHash.Length);
            }
            else
            {
                expected = FromBase64OrEmpty(hash);
                actual = Rfc2898DeriveBytes.Pbkdf2(password, Encoding.UTF8.GetBytes(salt), LegacyIterations,
                    HashAlgorithmName.SHA256, LegacyHashSize);
            }

            return CryptographicOperations.FixedTimeEquals(expected, actual);
        }

        public bool NeedsRehash(string hash)
            => !TryParse(hash, out var iterations, out var storedHash)
               || iterations < Iterations
               || storedHash.Length < HashSize;

        private static bool TryParse(string hash, out int iterations, out byte[] storedHash)
        {
            iterations = 0;
            storedHash = [];
            var parts = hash.Split('$');
            if (parts.Length != 3 || parts[0] != Prefix || !int.TryParse(parts[1], out iterations) || iterations <= 0)
            {
                return false;
            }
            storedHash = FromBase64OrEmpty(parts[2]);
            return storedHash.Length > 0;
        }

        private static byte[] FromBase64OrEmpty(string value)
        {
            try
            {
                return Convert.FromBase64String(value);
            }
            catch (FormatException)
            {
                return [];
            }
        }
    }
}
