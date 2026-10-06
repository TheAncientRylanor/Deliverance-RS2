using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Deliverance.Model.Enums;

public class ReportOccuranceResponse
{
    public int OccuranceId { get; set; }

    public string Question {get;set;}= string.Empty;

    public AnswerEnum Answer { get; set; }

}
