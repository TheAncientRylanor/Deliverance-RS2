namespace Deliverance.Model.Responses
{
    public class ReportStatisticsResponse
    {
        public int Id { get; set; }
        public DateTime TimePeriodWithMostRep { get; set; }
        public OfficeReportCount? OfficeWithMostRep { get; set; }
        public DeviceReportCount? DeviceWithMostRep { get; set; }
        public UserReportCount? UserWithMostRep { get; set; }
        public TimeReportBreakdown? TimeBreakdown { get; set; }
    }

    public class TimeReportBreakdown
    {
        public DateTime Month { get; set; }
        public Dictionary<int, int> ReportsByDay { get; set; } = new();
    }

    public class OfficeReportCount
    {
        public int OfficeId { get; set; }
        public string? OfficeName { get; set; }
        public int ReportCount { get; set; }
    }

    public class DeviceReportCount
    {
        public int DeviceId { get; set; }
        public string? DeviceName { get; set; }
        public int ReportCount { get; set; }
    }

    public class UserReportCount
    {
        public Guid UserId { get; set; }
        public string? Username { get; set; }
        public int ReportCount { get; set; }
    }
}
