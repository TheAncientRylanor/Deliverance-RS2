using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Deliverance.Services.Database;

public class Occurrence
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }
    public string Question { get; set; } = string.Empty;

    public ICollection<ReportOccurrence> ReportOccurrences { get; set; } = new List<ReportOccurrence>();
}