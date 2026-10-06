using Deliverance.Model.Exceptions;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;

namespace Deliverance.Services
{
    public class ReportStatisticsService : BaseReadService<ReportStatistics, ReportStatisticsResponse, ReportStatisticsSearchObject>, IReportStatisticsService
    {
        public ReportStatisticsService(IMapper mapper, DeliveranceDbContext dbContext)
            : base(mapper, dbContext)
        {
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
                throw new KeyNotFoundException($"{typeof(ReportStatistics).Name} with id {id} not found.");
            }
            if (!isAdmin && entity.Report?.UserUUID != userId)
            {
                throw new ClientException("You do not have access to this resource.");
            }

            return _mapper.Map<ReportStatisticsResponse>(entity);
        }

        public async Task<ReportStatisticsResponse> GetStatistics(ReportStatisticsSearchObject? search, bool isAdmin = false)
        {
            if (!isAdmin)
            {
                throw new ClientException("You do not have access to this resource.");
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

            var topTimePeriod = await query
                .GroupBy(x => x.DateReported.Date)
                .Select(g => new { Date = g.Key, Count = g.Select(x => x.ReportId).Distinct().Count() })
                .OrderByDescending(g => g.Count)
                .FirstOrDefaultAsync();

            var targetMonth = search?.ReportDate ?? DateTime.UtcNow;
            var monthStart = new DateTime(targetMonth.Year, targetMonth.Month, 1);
            var monthEnd = monthStart.AddMonths(1);

            var officeId = search?.OfficeId;
            var dayCounts = await query
            .Where(x => x.DateReported >= monthStart && x.DateReported < monthEnd &&
            (officeId == null || x.OfficeId == officeId))
            .GroupBy(x => x.DateReported.Day)
            .Select(g => new { Day = g.Key, Count = g.Select(x => x.ReportId).Distinct().Count() })
            .ToDictionaryAsync(x => x.Day, x => x.Count);

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
