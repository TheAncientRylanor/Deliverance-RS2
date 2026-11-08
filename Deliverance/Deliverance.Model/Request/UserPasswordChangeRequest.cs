namespace Deliverance.Model.Request
{
    public class UserPasswordChangeRequest
    {
        public string OldPassword { get; set; } = null!;
        public string NewPassword { get; set; } = null!;
    }
}
