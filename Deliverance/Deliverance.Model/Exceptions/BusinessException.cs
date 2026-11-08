namespace Deliverance.Model.Exceptions
{
    /// <summary>
    /// A request breaks a business rule (wrong state, duplicate, blocked delete...).
    /// Mapped to 400 with its message, so the message must make sense to the user.
    /// </summary>
    public class BusinessException : Exception
    {
        public BusinessException(string message) : base(message)
        {
        }

        public BusinessException(string message, Exception inner) : base(message, inner)
        {
        }
    }
}
