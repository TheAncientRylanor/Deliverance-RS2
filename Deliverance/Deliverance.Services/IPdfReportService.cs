namespace Deliverance.Services
{
    public interface IPdfReportService
    {
        // Both ends are included. Defaults to the 30 days up to now.
        Task<byte[]> GetReportActivityAsync(DateTime? from, DateTime? to, int? officeId, bool isAdmin);
        Task<byte[]> GetDeviceHealthAsync(int? officeId, bool isAdmin);
    }
}
