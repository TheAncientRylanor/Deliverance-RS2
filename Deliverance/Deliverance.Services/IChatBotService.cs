using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;


namespace Deliverance.Services
{
    public interface IChatBotService :
        IBaseCRUDService<ChatBotMessageResponse, ChatBotMessageSearchObject, ChatBotMessageInsertRequest, ChatBotMessageUpdateRequest>
    {
        Task<ChatBotMessageResponse> InsertAsync(ChatBotMessageInsertRequest request, Guid userId, bool isAdmin);
        Task<List<ConversationResponse>> GetConversationsAsync(Guid userId);
        Task<List<ChatBotMessageResponse>> GetConversationMessagesAsync(int conversationId, Guid userId, int? beforeId, int take);
    }
}
