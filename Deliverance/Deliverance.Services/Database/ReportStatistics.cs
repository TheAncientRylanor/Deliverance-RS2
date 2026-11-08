using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Deliverance.Services.Database;

public class ReportStatistics
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }
    public int ReportId { get; set; }
    public int OfficeReportId { get; set; }
    public int OfficeId { get; set; }
    public int DeviceId { get; set; }
    public Guid UserId { get; set; }
    public DateTime DateReported { get; set; }

    [ForeignKey("ReportId")]
    public Report? Report { get; set; }

    [ForeignKey("OfficeId")]
    public Office? Office { get; set; }

    [ForeignKey("DeviceId")]
    public Device? Device { get; set; }

    [ForeignKey("UserId")]
    public User? User { get; set; }
}