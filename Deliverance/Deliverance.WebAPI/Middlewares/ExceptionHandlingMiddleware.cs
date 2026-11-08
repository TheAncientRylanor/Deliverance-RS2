// ExceptionHandlingMiddleware.cs
using System.Text.Json;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Responses;
using FluentValidation;

/// <summary>
/// The one place exceptions become HTTP responses. Services throw, controllers don't catch:
/// ValidationException and BusinessException -> 400, UnauthorizedAccessException -> 401,
/// ForbiddenException -> 403, NotFoundException -> 404, anything else -> 500 (logged).
/// </summary>
public class ExceptionHandlingMiddleware
{
    // camelCase, so the body is { "message": ... } as the apps expect.
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (ValidationException ex)
        {
            await WriteAsync(context, StatusCodes.Status400BadRequest, new ValidationErrorResponse
            {
                Message = ex.Errors.Select(e => e.ErrorMessage).ToList(),
                Errors = ex.Errors
                    .GroupBy(e => e.PropertyName)
                    .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).ToList()),
            });
        }
        catch (BusinessException ex)
        {
            await WriteAsync(context, StatusCodes.Status400BadRequest, new ErrorResponse { Message = ex.Message });
        }
        catch (NotFoundException ex)
        {
            await WriteAsync(context, StatusCodes.Status404NotFound, new ErrorResponse { Message = ex.Message });
        }
        catch (ForbiddenException ex)
        {
            await WriteAsync(context, StatusCodes.Status403Forbidden, new ErrorResponse { Message = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            await WriteAsync(context, StatusCodes.Status401Unauthorized,
                new ErrorResponse { Message = "You are not authorized. Please sign in again." });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception on {Method} {Path}", context.Request.Method, context.Request.Path);
            await WriteAsync(context, StatusCodes.Status500InternalServerError,
                new ErrorResponse { Message = "Internal server error. Please try again." });
        }
    }

    private static Task WriteAsync<TBody>(HttpContext context, int statusCode, TBody body)
    {
        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/json";
        return context.Response.WriteAsync(JsonSerializer.Serialize(body, JsonOptions));
    }
}
