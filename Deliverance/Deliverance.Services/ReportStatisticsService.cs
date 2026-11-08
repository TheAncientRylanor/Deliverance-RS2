using Deliverance.Model.Exceptions;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Configuration;
using Deliverance.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;

namespace Deliverance.Services
{
    public class ReportStatisticsService : BaseReadService<ReportStatistics, ReportStatisticsResponse, ReportStatisticsSearchObject>, IReportStatisticsService
    {
        private readonly DisplayTimeZone _displayTimeZone;

        public ReportStatisticsService(IMapper mapper, DeliveranceDbContext dbContext, DisplayTimeZone displayTimeZone)
            : base(mapper, dbContext)
        {
            _displayTimeZone = displayTimeZone;
        }

        public override IQueryable<ReportStatistics> GetQuery()
        {
            return this._dbContext.Set<ReportStatistics>()
                .Include(x => x.Office)
                .Include(x => x.Device);
        }

        protected override IQueryable<ReportStatistics> ApplyFilters(IQueryable<ReportStatistics> query, ReportStatisticsSearchObject? search, Guid userId = default, bool isAdmin = false)
        {
            if (!isAdmin)
            {
                query = query.Where(x => x.Report.UserUUID == userId);
            }


            return query;
        }

        public override async Task<ReportStatisticsResponse> GetByIdAsync(int id, Guid userId, bool isAdmin = false)
        {
            var entity = await GetQuery()
                .Include(x => x.Report)
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
            {
                throw new NotFoundException($"{typeof(ReportStatistics).Name} with id {id} not found.");
            }
            if (!isAdmin && entity.Report?.UserUUID != userId)
            {
                throw new ForbiddenException("You do not have access to this resource.");
            }

            return _mapper.Map<ReportStatisticsResponse>(entity);
        }

        public async Task<ReportStatisticsResponse> GetStatistics(ReportStatisticsSearchObject? search, bool isAdmin = false)
        {
            if (!isAdmin)
            {
                throw new ForbiddenException("You do not have access to this resource.");
            }

            var query = this._dbContext.Set<ReportStatistics>().AsNoTracking();

            var topOffice = await query
                .GroupBy(x => x.OfficeId)
                .Select(g => new { OfficeId = g.Key, Count = g.Select(x => x.ReportId).Distinct().Count() })
                .OrderByDescending(g => g.Count)
                .FirstOrDefaultAsync();

            var topDevice = await query
                .GroupBy(x => x.DeviceId)
                .Select(g => new { DeviceId = g.Key, Count = g.Select(x => x.ReportId).Distinct().Count() })
                .OrderByDescending(g => g.Count)
                .FirstOrDefaultAsync();

            var topUser = await query
                .GroupBy(x => x.UserId)
                .Select(g => new { UserId = g.Key, Count = g.Select(x => x.ReportId).Distinct().Count() })
                .OrderByDescending(g => g.Count)
                .FirstOrDefaultAsync();

            // Dates are UTC, but "which day" means a day in the display time zone, which SQL
            // can't group by here. One row per report (its id and date) is grouped in memory.
            var reportDates = await query
                .Select(x => new { x.ReportId, x.DateReported })
                .Distinct()
                .ToListAsync();
            var topTimePeriod = reportDates
                .GroupBy(x => _displayTimeZone.FromUtc(x.DateReported).Date)
                .Select(g => new { Date = g.Key, Count = g.Count() })
                .OrderByDescending(g => g.Count)
                .FirstOrDefault();

            // The month is a calendar month in the display zone, so its bounds are converted to UTC.
            var targetMonth = search?.ReportDate is DateTime picked
                ? _displayTimeZone.FromUtc(picked)
                : _displayTimeZone.Now;
            var monthStart = new DateTime(targetMonth.Year, targetMonth.Month, 1);
            var monthStartUtc = _displayTimeZone.ToUtc(monthStart);
            var monthEndUtc = _displayTimeZone.ToUtc(monthStart.AddMonths(1));

            var officeId = search?.OfficeId;
            var dayCounts = (await query
                .Where(x => x.DateReported >= monthStartUtc && x.DateReported < monthEndUtc &&
                    (officeId == null || x.OfficeId == officeId))
                .Select(x => new { x.ReportId, x.DateReported })
                .Distinct()
                .ToListAsync())
                .GroupBy(x => _displayTimeZone.FromUtc(x.DateReported).Day)
                .ToDictionary(g => g.Key, g => g.Count());

            var timeBreakdown = new TimeReportBreakdown
            {
                Month = monthStart,
                ReportsByDay = dayCounts,
            };

            string? officeName = topOffice == null
                ? null
                : await this._dbContext.Set<Office>()
                    .Where(o => o.Id == topOffice.OfficeId)
                    .Select(o => o.Name)
                    .FirstOrDefaultAsync();

            string? deviceName = topDevice == null
                ? null
                : await this._dbContext.Set<Device>()
                    .Where(d => d.Id == topDevice.DeviceId)
                    .Select(d => d.Name)
                    .FirstOrDefaultAsync();

            string? username = topUser == null
                ? null
                : await this._dbContext.Set<User>()
                    .Where(u => u.UUID == topUser.UserId)
                    .Select(u => u.Username)
                    .FirstOrDefaultAsync();

            return new ReportStatisticsResponse
            {
                TimePeriodWithMostRep = topTimePeriod?.Date ?? default,
                OfficeWithMostRep = topOffice == null ? null : new OfficeReportCount
                {
                    OfficeId = topOffice.OfficeId,
                    OfficeName = officeName,
                    ReportCount = topOffice.Count,
                },
                DeviceWithMostRep = topDevice == null ? null : new DeviceReportCount
                {
                    DeviceId = topDevice.DeviceId,
                    DeviceName = deviceName,
                    ReportCount = topDevice.Count,
                },
                UserWithMostRep = topUser == null ? null : new UserReportCount
                {
                    UserId = topUser.UserId,
                    Username = username,
                    ReportCount = topUser.Count,
                },
                TimeBreakdown = timeBreakdown,
            };
        }

    }
}
