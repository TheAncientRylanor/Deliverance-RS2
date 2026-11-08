using System.Buffers.Text;
using System.Security.Cryptography;
using System.Text;

namespace Deliverance.Services
{
    internal static class ScoutSecrets
    {
        public static string Generate()
            => Base64Url.EncodeToString(RandomNumberGenerator.GetBytes(32));

        public static string Hash(string value)
            => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value)));
    }
}
