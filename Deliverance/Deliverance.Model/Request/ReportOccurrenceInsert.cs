using Deliverance.Model.Enums;

namespace Deliverance.Model.Request;

public class ReportOccurrenceInsert
{
    public int OccurrenceId { get; set; }
    public string Question { get; set; } = string.Empty;
    public AnswerEnum? Answer { get; set; }
}