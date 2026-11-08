using Deliverance.Model.Responses;

namespace Deliverance.Services.Messaging
{

    public interface IScoutNotifier
    {
        Task CommandSent(ScoutCommandResponse scoutCommandInsertRequest);
    }
}
