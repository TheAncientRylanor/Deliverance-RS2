using Deliverance.Model.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Deliverance.Services.Database
{
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

        public int? ReportId { get; set; }

        public Guid? RelatedUserUUID { get; set; }

        [ForeignKey("UserUUID")]
        public User? User { get; set; }
    }
}
