using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class TSK
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required]
    public string Key { get; set; } = string.Empty;
    [Required]
    public DateTime CreatedAt { get; set; }

    public DateTime? ExpiresAt { get; set; }

    public string? Status { get; set; }

    [Required]
    public Guid RequestedByUserUUID { get; set; }

    public int? ScoutId { get; set; }

    // Navigation
    [ForeignKey("RequestedByUserUUID")]
    public User? RequestedByUser { get; set; }

    [ForeignKey("ScoutId")]
    public Scout? Scout { get; set; }
}