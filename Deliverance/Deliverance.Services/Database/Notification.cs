using Deliverance.Model.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Deliverance.Services.Database
{
    /// <summary>One notification for one recipient, so each person has their own read status.</summary>
    public class Notification : IUserOwnedEntity
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        public Guid UserUUID { get; set; }

        public NotificationTypeEnum Type { get; set; }

        [Required]
        [MaxLength(100)]
        public string Title { get; set; } = string.Empty;

        [Required]
        public string Text { get; set; } = string.Empty;

        public bool IsRead { get; set; }

        public DateTime CreatedAt { get; set; }

        // Not a foreign key: Users -> Reports -> Notifications next to the cascade from
        // Users would be a second delete path, which SQL Server can reject.
        public int? ReportId { get; set; }

        // The user the notification is about, such as a new registration. Not a foreign key
        // for the same reason as ReportId.
        public Guid? RelatedUserUUID { get; set; }

        [ForeignKey("UserUUID")]
        public User? User { get; set; }
    }
}
