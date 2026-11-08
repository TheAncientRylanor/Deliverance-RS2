namespace Deliverance.Model.Responses
{
    /// <summary>Body of every error response: { "message": "..." }.</summary>
    public class ErrorResponse
    {
        public string Message { get; set; } = string.Empty;
    }

    /// <summary>
    /// Body of a validation error (400): every message, plus the messages per field.
    /// </summary>
    public class ValidationErrorResponse
    {
        public List<string> Message { get; set; } = new();
        public Dictionary<string, List<string>> Errors { get; set; } = new();
    }
}
