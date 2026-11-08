namespace Deliverance.Model.SearchObjects
{
    public class OfficeSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public List<int>? Offices { get; set; }
        public bool IncludeDevices { get; set; }
    }
}
