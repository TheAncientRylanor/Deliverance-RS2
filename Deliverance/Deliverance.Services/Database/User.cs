using Deliverance.Model.Enums;
using Deliverance.Services.Database;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class User 
{
    [Key]
    public Guid UUID { get; set; }

    [Required]
    public string Username { get; set; } = string.Empty;

    [Required]
    public string FirstName { get; set; } = string.Empty;
    public string? LastName { get; set; }


    public RoleEnum? RoleId { get; set; }

    [Required]
    public string Email { get; set; } =  string.Empty;

    [Required]
    public string PasswordHash { get; set; } = string.Empty;

    [Required]
    public string PasswordSalt { get; set; }= string.Empty;
    [Required]
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public string? ImagePath {get;set;} = string.Empty;

    // Navigation Properties
    [ForeignKey("RoleId")]
    public Role? Role { get; set; }
    public ICollection<RefreshTokens>? RefreshToken { get; set; }
    public ICollection<Contact> Contacts { get; set; } = new List<Contact>();
    public ICollection<Report> Reports { get; set; } = new List<Report>();
    public ICollection<ChatBotMessage> ChatBotMessages { get; set; } = new List<ChatBotMessage>();
}