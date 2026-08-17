// ExceptionHandlingMiddleware.cs
using System.Text.Json;
using Deliverance.Model.Exceptions;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;

    public ExceptionHandlingMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (FluentValidation.ValidationException ex)
        {
            context.Response.ContentType = "application/json";
            context.Response.StatusCode = StatusCodes.Status400BadRequest;

            var payload = new
            {
                message = ex.Errors.Select(e => e.ErrorMessage).ToList(),
                errors = ex.Errors
                    .GroupBy(e => e.PropertyName)
                    .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).ToList())
            };

            await context.Response.WriteAsync(JsonSerializer.Serialize(payload));
        }
         catch (ClientException ex)
        {
            context.Response.ContentType = "application/json";
            context.Response.StatusCode = StatusCodes.Status400BadRequest;

            var payload = new { message = ex.Message };

            await context.Response.WriteAsync(JsonSerializer.Serialize(payload));
        }
        catch (Exception)
        {
            context.Response.ContentType = "application/json";
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            await context.Response.WriteAsync(
                JsonSerializer.Serialize(new { message = "Server error" }));
        }
    }
}