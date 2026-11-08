using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Deliverance.Services.Database;

public class ChatBotMessage : IUserOwnedEntity
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }
    public int ConversationId { get; set; }

    public Guid UserUUID { get; set; }
    public bool? IsFromBot { get; set; }

    [MaxLength(3000)]
    public string? Content { get; set; }

    public DateTime? CreatedAt { get; set; }

    [ForeignKey("UserUUID")]
    public User? User { get; set; }

    [ForeignKey("ConversationId")]
    public Conversation? Conversation { get; set; }
}