using Deliverance.Model.Enums;
using System.Security.Claims;

public static class ClaimsPrincipalExtensions
{
    public static Guid GetUserId(this ClaimsPrincipal user)
    {
        var idClaim = user.FindFirst(ClaimTypes.NameIdentifier)?.Value
                      ?? user.FindFirst("sub")?.Value; // depends how you named the claim when issuing the token

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
}

public static class ScoutClaimsPrincipalExtensions
{
    /// <summary>Id of the scout behind a token issued by ScoutAccessManager.</summary>
    public static int GetScoutId(this ClaimsPrincipal user)
    {
        var idClaim = user.FindFirst(Deliverance.Services.ScoutAuthDefaults.ScoutIdClaim)?.Value;

        if (idClaim is null || !int.TryParse(idClaim, out var scoutId))
            throw new UnauthorizedAccessException("Scout ID claim is missing or invalid.");

        return scoutId;
    }
}
