namespace Deliverance.Services
{
    /// <summary>
    /// Scouts authenticate with their own JWT scheme. Their tokens use a different
    /// audience than user tokens, so the default scheme (and every plain [Authorize]
    /// endpoint) rejects them, and the Scout scheme rejects user tokens.
    /// </summary>
    public static class ScoutAuthDefaults
    {
        public const string Scheme = "Scout";
        public const string Audience = "deliverance-scout";
        public const string ScoutIdClaim = "scoutId";
        public static readonly TimeSpan TokenLifetime = TimeSpan.FromMinutes(30);
    }
}
