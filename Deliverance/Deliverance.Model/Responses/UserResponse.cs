namespace Deliverance.Model.Responses
{
    public class UserResponse
    {
        public Guid UUID { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public int RoleId { get; set; }
        public DateTime? CreatedAt { get; set; }
        public string? ImagePath { get; set; }
    }
}
