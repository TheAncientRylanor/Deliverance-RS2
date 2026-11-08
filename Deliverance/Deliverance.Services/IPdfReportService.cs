namespace Deliverance.Services
{
    public interface IPdfReportService
    {
        Task<byte[]> GetReportActivityAsync(DateTime? from, DateTime? to, int? officeId, bool isAdmin);
        Task<byte[]> GetDeviceHealthAsync(int? officeId, bool isAdmin);
    }
}
