namespace Deliverance.Model.Responses
{
    public class ConversationResponse
    {
        public int Id { get; set; }
        public Guid UserUUID { get; set; }
        public string? Title { get; set; }
        public DateTime? CreatedAt { get; set; }
    }
}
