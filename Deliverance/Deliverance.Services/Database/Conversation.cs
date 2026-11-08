using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Deliverance.Services.Database;

public class Conversation : IUserOwnedEntity
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    public Guid UserUUID { get; set; }

    [MaxLength(100)]
    public string? Title { get; set; }

    public DateTime? CreatedAt { get; set; }

    [ForeignKey("UserUUID")]
    public User? User { get; set; }

    public List<ChatBotMessage> ChatBotMessages { get; set; } = [];
}
