using Deliverance.Model.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Deliverance.Services.Database;

public class ScoutEnrollment
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required]
    [MaxLength(64)]
    public string TokenHash { get; set; } = string.Empty;

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

    public int? ScoutId { get; set; }

    [ForeignKey("CreatedByUserUUID")]
    public User? CreatedByUser { get; set; }

    [ForeignKey("ScoutId")]
    public Scout? Scout { get; set; }
}
