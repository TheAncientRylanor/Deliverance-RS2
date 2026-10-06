using Deliverance.Model.Enums;

public class ReportOccuranceInsert
{
    public int OccuranceId {get;set;}
    public string Question {get;set;} = string.Empty;
    public AnswerEnum? Answer {get;set;}
}