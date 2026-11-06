using Deliverance.Model.Enums;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class ScoutEnrollment
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    // SHA-256 hex of the enrollment token; the plain token is never stored.
    [Required]
    [MaxLength(64)]
    public string TokenHash { get; set; } = string.Empty;

    // SHA-256 hex of the scout's long-term secret, issued when the token is claimed.
    // It only authenticates once the enrollment is Completed and linked to a Scout.
    [MaxLength(64)]
    public string? SecretHash { get; set; }

    [Required]
    public Guid CreatedByUserUUID { get; set; }

    [Required]
    public DateTime CreatedAt { get; set; }

    [Required]
    public DateTime ExpiresAt { get; set; }

    [Required]
    public ScoutEnrollmentStatusEnum Status { get; set; } = ScoutEnrollmentStatusEnum.Pending;

    // Reported by the scout when it claims the token
    [MaxLength(45)]
    public string? IpAddress { get; set; }

    [MaxLength(17)]
    public string? MacAddress { get; set; }

    [MaxLength(45)]
    public string? SubnetMask { get; set; }

    [MaxLength(10)]
    public string? VlanID { get; set; }

    [MaxLength(100)]
    public string? OS { get; set; }

    [MaxLength(100)]
    public string? Manufacturer { get; set; }

    [MaxLength(100)]
    public string? Hostname { get; set; }

    public DateTime? ClaimedAt { get; set; }

    // Set once the admin saves the office and the Scout is created
    public int? ScoutId { get; set; }

    // Navigation
    [ForeignKey("CreatedByUserUUID")]
    public User? CreatedByUser { get; set; }

    [ForeignKey("ScoutId")]
    public Scout? Scout { get; set; }
}
