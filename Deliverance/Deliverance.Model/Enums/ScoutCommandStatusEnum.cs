namespace Deliverance.Model.Enums
{
    public enum ScoutCommandStatusEnum
    {
        // Saved, not yet picked up by the scout.
        Pending = 1,
        Running = 2,
        // The process ran to the end, whatever its exit code.
        Completed = 3,
        // The scout couldn't start the process.
        Failed = 4,
        // Killed by the scout, or no result reached the server in time.
        TimedOut = 5,
    }
}
