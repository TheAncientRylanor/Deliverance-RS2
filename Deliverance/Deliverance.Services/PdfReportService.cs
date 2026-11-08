using Deliverance.Services.ReportStateMachine;
using Deliverance.Model.Exceptions;
using Deliverance.Services.Configuration;
using Deliverance.Services.Database;
using Deliverance.Services.Pdf;
using Microsoft.EntityFrameworkCore;

namespace Deliverance.Services
{
    public class PdfReportService : IPdfReportService
    {
        private const int DefaultPeriodDays = 30;
        private const int TopDevicesWithLogs = 5;
        private const int LogsPerDevice = 8;
        private const int RecentLogDays = 7;

        private readonly DeliveranceDbContext _dbContext;
        private readonly IDeviceRecommendationService _recommendationService;

        private readonly DisplayTimeZone _displayTimeZone;

        public PdfReportService(DeliveranceDbContext dbContext, IDeviceRecommendationService recommendationService,
            DisplayTimeZone displayTimeZone)
        {
            _displayTimeZone = displayTimeZone;
            _dbContext = dbContext;
            _recommendationService = recommendationService;
        }

        public async Task<byte[]> GetReportActivityAsync(DateTime? from, DateTime? to, int? officeId, bool isAdmin)
        {
            EnsureAdmin(isAdmin);
            var end = to?.AsUtc() ?? DateTime.UtcNow;
            var start = from?.AsUtc()
                ?? _displayTimeZone.ToUtc(_displayTimeZone.FromUtc(end).Date.AddDays(-(DefaultPeriodDays - 1)));
            if (start > end)
            {
                throw new BusinessException("The start date can't be after the end date.");
            }
            var officeName = await GetOfficeNameAsync(officeId);

            var reports = await _dbContext.Reports
                .AsNoTracking()
                .Where(r => r.Status != nameof(DraftReportState) && r.DateReported >= start && r.DateReported <= end)
                .Where(r => officeId == null || r.OfficeReports.Any(o => o.OfficeId == officeId))
                .Include(r => r.OfficeReports)
                    .ThenInclude(o => o.Office)
                .Include(r => r.OfficeReports)
                    .ThenInclude(o => o.DeviceReports)
                    .ThenInclude(d => d.Device)
                .OrderBy(r => r.DateReported)
                .AsSplitQuery()
                .ToListAsync();

            return ReportActivityDocument.Generate(reports, start, end, officeId, officeName, _displayTimeZone);
        }

        public async Task<byte[]> GetDeviceHealthAsync(int? officeId, bool isAdmin)
        {
            EnsureAdmin(isAdmin);
            var officeName = await GetOfficeNameAsync(officeId);
            var now = DateTime.UtcNow;

            var devices = await _dbContext.Devices
                .AsNoTracking()
                .Where(d => officeId == null || d.OfficeId == officeId)
                .Select(d => new { d.Id, d.Name, d.OfficeName, d.Type })
                .ToListAsync();

            var reports = (await _dbContext.DeviceReports
                .AsNoTracking()
                .Where(dr => (officeId == null || dr.Device!.OfficeId == officeId)
                    && dr.OfficeReport!.Report!.Status != nameof(DraftReportState))
                .Select(dr => new
                {
                    dr.DeviceId,
                    dr.OfficeReport!.Report!.DateReported,
                    dr.OfficeReport.Report.Status,
                    dr.OfficeReport.Report.DateCleared,
                })
                .ToListAsync())
                .ToLookup(x => x.DeviceId);

            var scores = (await _recommendationService.ScoreAllDevicesAsync(isAdmin))
                .ToDictionary(x => x.DeviceId);

            var rows = devices
                .Select(d =>
                {
                    var deviceReports = reports[d.Id].ToList();
                    var score = scores.GetValueOrDefault(d.Id);
                    return (d.Id, Row: new DeviceHealthRow(
                        d.Name,
                        d.OfficeName,
                        d.Type,
                        deviceReports.Count(r => r.DateReported >= now.AddDays(-30)),
                        deviceReports.Count(r => r.Status != nameof(ClearedReportState)),
                        _displayTimeZone.FromUtc(deviceReports.Count == 0 ? null : deviceReports.Max(r => r.DateReported)),
                        _displayTimeZone.FromUtc(deviceReports.Max(r => r.DateCleared)),
                        score?.NeedsFixProbability,
                        score?.LikelyIssue));
                })
                .OrderByDescending(x => x.Row.NeedsFixProbability ?? -1)
                .ThenByDescending(x => x.Row.OpenReports)
                .ToList();

            var topDevices = rows
                .Where(x => x.Row.NeedsFixProbability >= DeviceHealthDocument.NeedsFixThreshold)
                .Take(TopDevicesWithLogs)
                .ToList();
            var topIds = topDevices.Select(x => x.Id).ToList();
            var since = now.AddDays(-RecentLogDays);
            var logs = (await _dbContext.DeviceLogs
                .AsNoTracking()
                .Where(l => topIds.Contains(l.Scout!.DeviceId) && l.DateLogged >= since)
                .Select(l => new { l.Scout!.DeviceId, l.DateLogged, l.Log })
                .ToListAsync())
                .ToLookup(x => x.DeviceId);

            var topDeviceLogs = topDevices.ToDictionary(
                x => $"{x.Row.Device} ({x.Row.Office})",
                x => logs[x.Id]
                    .OrderByDescending(l => l.DateLogged)
                    .Take(LogsPerDevice)
                    .Select(l => new DeviceLogLine(_displayTimeZone.FromUtc(l.DateLogged), l.Log))
                    .ToList());

            return DeviceHealthDocument.Generate(rows.Select(x => x.Row).ToList(), topDeviceLogs, officeName,
                _displayTimeZone.FromUtc(now));
        }

        private async Task<string?> GetOfficeNameAsync(int? officeId)
        {
            if (officeId == null) return null;
            return await _dbContext.Offices
                .Where(o => o.Id == officeId)
                .Select(o => o.Name)
                .FirstOrDefaultAsync()
                ?? throw new NotFoundException($"Office with id {officeId} was not found.");
        }

        private static void EnsureAdmin(bool isAdmin)
        {
            if (!isAdmin)
            {
                throw new ForbiddenException("You do not have access to this resource.");
            }
        }
    }
}
