namespace Deliverance.Model.Enums
{
    public enum ScoutTokenStatusEnum
    {
        // The scout claimed its token, but the admin hasn't saved the device yet.
        PendingApproval = 1,
        Active = 2,
        // An admin disabled the scout; it gets no token until it is enabled again.
        Disabled = 3,
    }
}
