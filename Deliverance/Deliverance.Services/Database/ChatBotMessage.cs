using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class ChatBotMessage : IUserOwnedEntity
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    public Guid UserUUID { get; set; }

    [MaxLength(300)]
    public string? Content { get; set; }

    public DateTime? CreatedAt { get; set; }

    // Navigation
    [ForeignKey("UserUUID")]
    public User? User { get; set; }
}