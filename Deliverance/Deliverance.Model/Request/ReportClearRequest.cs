using Deliverance.Model.Enums;

namespace Deliverance.Model.Request
{
    public class ReportClearRequest
    {
        public string? Comment { get; set; }

        // Lets the admin correct the issue type the user picked; null keeps it as is.
        public IssueEnum? IssueType { get; set; }
    }
}
