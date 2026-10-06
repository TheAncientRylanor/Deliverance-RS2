using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Deliverance.Model.Enums;

public class ReportOccurance
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required]
    public int ReportId { get; set; }

    [Required]
    public int OccuranceId { get; set; }

    public AnswerEnum Answer { get; set; }

    // Navigation
    [ForeignKey("ReportId")]
    public Report? Report { get; set; }

    [ForeignKey("OccuranceId")]
    public Occurance? Occurance { get; set; }
}
