namespace Deliverance.Model.Request
{
    public class ChatBotMessageInsertRequest
    {
        // Null starts a new conversation.
        public int? ConversationId { get; set; }

        // Admins only. Answers from this device's logs and reports. Sent with every
        // message of the conversation, because it isn't saved.
        public int? DeviceId { get; set; }

        public string Content { get; set; } = string.Empty;
    }
}
