using System.Buffers.Text;
using System.Security.Cryptography;
using System.Text;

namespace Deliverance.Services
{
    /// <summary>Enrollment tokens and scout secrets: random values stored only as hashes.</summary>
    internal static class ScoutSecrets
    {
        public static string Generate()
            => Base64Url.EncodeToString(RandomNumberGenerator.GetBytes(32));

        // The values are 256 bits of randomness, so a plain SHA-256 is enough (no salt
        // or slow hash needed, unlike passwords) and keeps the lookup an index seek.
        public static string Hash(string value)
            => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value)));
    }
}
