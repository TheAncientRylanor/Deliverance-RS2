using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Deliverance.Model.Enums;

namespace Deliverance.Services.Database;

public class ReportOccurrence
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required]
    public int ReportId { get; set; }

    [Required]
    public int OccurrenceId { get; set; }

    public AnswerEnum Answer { get; set; }

    [ForeignKey("ReportId")]
    public Report? Report { get; set; }

    [ForeignKey("OccurrenceId")]
    public Occurrence? Occurrence { get; set; }
}
