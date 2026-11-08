

namespace Deliverance.Model.Request
{
    public class AvailabilityInsertRequest
    {
        public string Day { get; set; } = string.Empty;

        public TimeOnly? FromTime { get; set; }

        public TimeOnly? ToTime { get; set; }

        public TimeOnly? Pause { get; set; }

    }
}
