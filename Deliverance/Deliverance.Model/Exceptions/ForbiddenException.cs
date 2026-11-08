namespace Deliverance.Model.Exceptions
{
    /// <summary>
    /// The caller is signed in but may not do this (someone else's record, admin-only action).
    /// Mapped to 403 with its message. A missing or invalid sign-in is 401 instead.
    /// </summary>
    public class ForbiddenException : Exception
    {
        public ForbiddenException(string message = "You do not have access to this resource.") : base(message)
        {
        }
    }
}
