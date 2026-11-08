namespace Deliverance.Model.Responses
{
    public class AvailabilityResponse
    {
        public int Id { get; set; }
        public string Day { get; set; } = string.Empty;
        public TimeOnly? FromTime { get; set; }

        public TimeOnly? ToTime { get; set; }
        public TimeOnly? Pause { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
