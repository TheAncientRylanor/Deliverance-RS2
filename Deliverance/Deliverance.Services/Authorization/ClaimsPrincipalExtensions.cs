using Deliverance.Model.Enums;
using System.Security.Claims;

namespace Deliverance.Services;

public static class ClaimsPrincipalExtensions
{
    public static Guid GetUserId(this ClaimsPrincipal user)
    {
        var idClaim = user.FindFirst(ClaimTypes.NameIdentifier)?.Value
                      ?? user.FindFirst("sub")?.Value;

        if (idClaim is null || !Guid.TryParse(idClaim, out var userId))
            throw new UnauthorizedAccessException("User ID claim is missing or invalid.");

        return userId;
    }

    public static RoleEnum? GetUserRole(this ClaimsPrincipal user)
    {
        var roleClaim = user.FindFirst(ClaimTypes.Role)?.Value;

        if (roleClaim is null || !int.TryParse(roleClaim, out var roleId))
            return null;

        return (RoleEnum)roleId;
    }

    public static bool IsAdmin(this ClaimsPrincipal user)
        => user.GetUserRole() == RoleEnum.Admin;

    public const string SessionIdClaim = "session_id";

    public static int? FindSessionId(this ClaimsPrincipal user)
        => int.TryParse(user.FindFirst(SessionIdClaim)?.Value, out var sessionId) ? sessionId : null;

    public static int GetSessionId(this ClaimsPrincipal user)
        => user.FindSessionId() ?? throw new UnauthorizedAccessException("Session claim is missing or invalid.");

    public static Guid? FindUserId(this ClaimsPrincipal user)
        => Guid.TryParse(user.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var userId) ? userId : null;
}

public static class ScoutClaimsPrincipalExtensions
{
    public static int GetScoutId(this ClaimsPrincipal user)
    {
        var idClaim = user.FindFirst(Deliverance.Services.ScoutAuthDefaults.ScoutIdClaim)?.Value;

        if (idClaim is null || !int.TryParse(idClaim, out var scoutId))
            throw new UnauthorizedAccessException("Scout ID claim is missing or invalid.");

        return scoutId;
    }
}
