namespace Deliverance.Model.Responses
{
    public class ErrorResponse
    {
        public string Message { get; set; } = string.Empty;
    }

    public class ValidationErrorResponse
    {
        public List<string> Message { get; set; } = new();
        public Dictionary<string, List<string>> Errors { get; set; } = new();
    }
}
