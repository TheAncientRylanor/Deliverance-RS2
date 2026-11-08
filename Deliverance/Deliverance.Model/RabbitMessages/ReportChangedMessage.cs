using Deliverance.Model.Enums;
namespace Deliverance.Model.RabbitMessages;

public class ReportChangedMessage
{
    public int ReportId { get; set; }
    public ChangeType Type { get; set; }
}