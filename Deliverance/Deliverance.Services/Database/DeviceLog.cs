using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class DeviceLog
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }
    [Required]
    public DateTime DateLogged { get; set; }

    [Required]
    public int? ScoutId { get; set; }

    [MaxLength(1000)]
    public string? Log { get; set; }

    // Navigation
    [ForeignKey("ScoutId")]
    public Scout? Scout { get; set; }
}