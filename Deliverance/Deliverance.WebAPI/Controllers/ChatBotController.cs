using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers
{
    public class ChatBotController : BaseCRUDController<ChatBotMessageResponse, ChatBotMessageSearchObject,
        ChatBotMessageInsertRequest, ChatBotMessageUpdateRequest, IChatBotService>
    {
        IChatBotService _chatBotService;
        public ChatBotController(IChatBotService chatBotService) : base(chatBotService)
        {
            _chatBotService = chatBotService;
        }

        // The base action doesn't pass on whether the caller is an admin, which DeviceId needs.
        public override async Task<ActionResult<ChatBotMessageResponse>> Create([FromBody] ChatBotMessageInsertRequest request)
        {
            return await _chatBotService.InsertAsync(request, User.GetUserId(), User.IsAdmin());
        }

        [HttpGet("Conversations")]
        public async Task<List<ConversationResponse>> GetConversations()
        {
            var result = await _chatBotService.GetConversationsAsync(User.GetUserId());
            return result;
        }

        [HttpGet("Conversations/{conversationId}/Messages")]
        public async Task<List<ChatBotMessageResponse>> GetConversationMessages(int conversationId, [FromQuery] int? beforeId, [FromQuery] int take = 10)
        {
            var result = await _chatBotService.GetConversationMessagesAsync(conversationId, User.GetUserId(), beforeId, take);
            return result;
        }

    }
}
