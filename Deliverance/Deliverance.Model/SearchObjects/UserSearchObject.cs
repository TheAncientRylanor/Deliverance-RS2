using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Deliverance.Model.SearchObjects
{
    public class UserSearchObject : BaseSearchObject
    {
        public string? Email { get; set; }

        public string? Username { get; set; }

        public string? Name { get; set; }

    }
}
