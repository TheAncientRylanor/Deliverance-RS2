namespace Deliverance.Services
{
    public interface ICryptoService
    {
        (string Hash, string Salt) HashPassword(string password);
        bool Verify(string hash, string salt, string password);
        bool NeedsRehash(string hash);
    }
}
