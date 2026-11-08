using Deliverance.Model.Enums;

namespace Deliverance.Model.Request
{
    public class ReportClearRequest
    {
        public string? Comment { get; set; }

        public IssueEnum? IssueType { get; set; }
    }
}
