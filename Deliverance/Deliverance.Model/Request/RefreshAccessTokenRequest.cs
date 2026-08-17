using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Deliverance.Model.Request
{
    public class RefreshAccessTokenRequest
    {
        public string RefreshToken { get; set; } = string.Empty;
    }
}
