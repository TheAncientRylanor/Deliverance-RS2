namespace Deliverance.Model.Responses
{
    public class ChatBotMessageResponse
    {
        public int Id { get; set; }
        public int ConversationId { get; set; }
        public Guid UserUUID { get; set; }
        public bool? IsFromBot { get; set; }
        public string? Content { get; set; }
        public DateTime? CreatedAt { get; set; }
    }
}
