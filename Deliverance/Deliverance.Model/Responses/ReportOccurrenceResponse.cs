using Deliverance.Model.Enums;

namespace Deliverance.Model.Responses;

public class ReportOccurrenceResponse
{
    public int OccurrenceId { get; set; }

    public string Question { get; set; } = string.Empty;

    public AnswerEnum Answer { get; set; }

}
