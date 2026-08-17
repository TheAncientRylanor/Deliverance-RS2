using Deliverance.Model.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class DeviceReport
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    public SeverityEnum? Severity { get; set; }

    [MaxLength(255)]
    public string? Detail { get; set; }
    [Required]
    public int OfficeReportId { get; set; }

    [Required]
    public int DeviceId { get; set; }

    // Navigation
    [ForeignKey("OfficeReportId")]
    public OfficeReport? OfficeReport { get; set; }

    [ForeignKey("DeviceId")]
    public Device? Device { get; set; }
}