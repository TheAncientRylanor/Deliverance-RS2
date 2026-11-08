namespace Deliverance.Model.Exceptions
{
    public class ForbiddenException : Exception
    {
        public ForbiddenException(string message = "You do not have access to this resource.") : base(message)
        {
        }
    }
}
