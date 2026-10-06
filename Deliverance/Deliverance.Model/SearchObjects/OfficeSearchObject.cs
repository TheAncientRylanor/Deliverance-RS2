using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Deliverance.Model.SearchObjects
{
    public class OfficeSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public List<int>? Offices {get;set; }
        /// <summary>Include each office's devices in list results.</summary>
        public bool IncludeDevices { get; set; }
    }
}
