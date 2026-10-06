using Deliverance.Model.Enums;

public class ReportOccuranceUpdate
{
    public int Id {get;set; }
    public int OccuranceId {get;set;}
    public int ReportId {get;set;   }
    public AnswerEnum? Answer {get;set;}
}