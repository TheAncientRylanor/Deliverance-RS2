using Deliverance.Model.Enums;

namespace Deliverance.Model.Responses
{
    public class NotificationResponse
    {
        public int Id { get; set; }
        public NotificationTypeEnum Type { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Text { get; set; } = string.Empty;
        public bool IsRead { get; set; }
        public DateTime CreatedAt { get; set; }
        public int? ReportId { get; set; }
        public Guid? RelatedUserUUID { get; set; }
    }
}
