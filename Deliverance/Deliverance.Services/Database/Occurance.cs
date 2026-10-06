using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class Occurance
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }
    public string Question {get;set;} = string.Empty;

    public ICollection<ReportOccurance> ReportOccurances { get; set; } = new List<ReportOccurance>();
}