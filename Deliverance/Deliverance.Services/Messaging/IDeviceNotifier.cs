using Deliverance.Model.Responses;

namespace Deliverance.Services.Messaging;

public interface IDeviceNotifier
{
    Task CommandUpdated(ScoutCommandResponse commandResult);
}