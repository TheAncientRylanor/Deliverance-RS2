using Deliverance.Model.Request;
using Deliverance.Model.Responses;

public interface IDeviceNotifier
{
    Task CommandUpdated(ScoutCommandResponse commandResult);
}