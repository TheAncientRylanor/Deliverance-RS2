using Deliverance.Model.Enums;

namespace Deliverance.Model.SearchObjects
{
    public class ReportSearchObject : BaseSearchObject
    {
        public string? ReportName { get; set; }
        public int? DeviceId {get;set;}
        public int? OfficeId {get;set;  }
        public string? UserId {get;set;}
        public ReportStatusFilter? Status { get; set; }
    }
}
