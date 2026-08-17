using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Deliverance.Model.SearchObjects
{
    public class BaseSearchObject
    {
        public int? Page { get; set; } = 1;

        public int? PageSize { get; set; } = 10;

        public bool? IncludeTotalCount { get; set; } = false;
        public string? SortBy { get; set; }
        public bool Descending { get; set; } = false;
    }
}
