using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Deliverance.Services
{
    public interface ICryptoService
    {
        string GenerateHash(string password, string salt);
        string GenerateSlat();
        bool Verify(string hash, string salt, string password);
    }
}
