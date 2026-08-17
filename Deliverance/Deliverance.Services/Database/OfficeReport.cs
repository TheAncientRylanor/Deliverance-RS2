using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class OfficeReport
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required]
    public int ReportId { get; set; }

    [Required]
    public int OfficeId { get; set; }

    public int? NumReportedDevices { get; set; }

    // Navigation
    [ForeignKey("ReportId")]
    public Report? Report { get; set; }

    [ForeignKey("OfficeId")]
    public Office? Office { get; set; }

    public ICollection<DeviceReport> DeviceReports { get; set; } = new List<DeviceReport>();
}