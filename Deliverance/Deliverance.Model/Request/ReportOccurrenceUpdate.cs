using Deliverance.Model.Enums;

namespace Deliverance.Model.Request;

public class ReportOccurrenceUpdate
{
    public int Id { get; set; }
    public int OccurrenceId { get; set; }
    public int ReportId { get; set; }
    public AnswerEnum? Answer { get; set; }
}