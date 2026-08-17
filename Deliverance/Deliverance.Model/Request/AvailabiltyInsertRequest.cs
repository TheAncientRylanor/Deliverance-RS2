

namespace Deliverance.Model.Request
{
    public class AvailablitiesInsertRequest
    {
        public string Day { get; set; } = string.Empty;

        public TimeOnly? FromTime { get; set; }

        public TimeOnly? ToTime { get; set; }

        public TimeOnly? Pause { get; set; }

    }
}
