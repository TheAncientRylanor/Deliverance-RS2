namespace Deliverance.Model.SearchObjects
{
    public class ChatBotMessageSearchObject : BaseSearchObject
    {
        public int? ConversationId { get; set; }
        public bool? IsFromBot { get; set; }
        public string? Content { get; set; }
    }
}
