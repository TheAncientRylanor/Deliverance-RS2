namespace Deliverance.Model.Request
{
    public class ChatBotMessageInsertRequest
    {
        public int? ConversationId { get; set; }

        public int? DeviceId { get; set; }

        public string Content { get; set; } = string.Empty;
    }
}
