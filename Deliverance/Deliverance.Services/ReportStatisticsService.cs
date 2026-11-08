using Deliverance.Model.Exceptions;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Configuration;
using Deliverance.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

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
                query = query.Where(x => x.UserId == userId);
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
                throw new NotFoundException($"{typeof(ReportStatistics).Name} with id {id} was not found.");
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

            var topOffice = query
                .GroupBy(x => x.OfficeId)
                .Select(g => new { Key = g.Key, Count = g.Select(x => x.ReportId).Distinct().Count() })
                .OrderByDescending(g => g.Count)
                .Take(1)
                .Select(g => new TopEntry
                {
                    Dimension = TopDimension.Office,
                    IntId = g.Key,
                    GuidId = null,
                    Name = this._dbContext.Set<Office>().Where(o => o.Id == g.Key).Select(o => o.Name).FirstOrDefault(),
                    Count = g.Count,
                });
            var topDevice = query
                .GroupBy(x => x.DeviceId)
                .Select(g => new { Key = g.Key, Count = g.Select(x => x.ReportId).Distinct().Count() })
                .OrderByDescending(g => g.Count)
                .Take(1)
                .Select(g => new TopEntry
                {
                    Dimension = TopDimension.Device,
                    IntId = g.Key,
                    GuidId = null,
                    Name = this._dbContext.Set<Device>().Where(d => d.Id == g.Key).Select(d => d.Name).FirstOrDefault(),
                    Count = g.Count,
                });
            var topUser = query
                .GroupBy(x => x.UserId)
                .Select(g => new { Key = g.Key, Count = g.Select(x => x.ReportId).Distinct().Count() })
                .OrderByDescending(g => g.Count)
                .Take(1)
                .Select(g => new TopEntry
                {
                    Dimension = TopDimension.User,
                    IntId = null,
                    GuidId = g.Key,
                    Name = this._dbContext.Set<User>().Where(u => u.UUID == g.Key).Select(u => u.Username).FirstOrDefault(),
                    Count = g.Count,
                });
            var tops = await topOffice.Concat(topDevice).Concat(topUser).ToListAsync();
            var office = tops.FirstOrDefault(x => x.Dimension == TopDimension.Office);
            var device = tops.FirstOrDefault(x => x.Dimension == TopDimension.Device);
            var user = tops.FirstOrDefault(x => x.Dimension == TopDimension.User);

            var officeId = search?.OfficeId;
            var sqlTimeZone = _displayTimeZone.SqlServerId;
            var days = await this._dbContext.Database.SqlQuery<ReportDayCount>($"""
                SELECT d.Day,
                       COUNT(DISTINCT d.ReportId) AS Total,
                       COUNT(DISTINCT CASE WHEN {officeId} IS NULL OR d.OfficeId = {officeId} THEN d.ReportId END) AS OfficeTotal
                FROM (
                    SELECT ReportId, OfficeId,
                           CAST((DateReported AT TIME ZONE 'UTC') AT TIME ZONE {sqlTimeZone} AS date) AS Day
                    FROM ReportStatistics
                ) AS d
                GROUP BY d.Day
                """).ToListAsync();

            var busiestDay = days.OrderByDescending(d => d.Total).ThenByDescending(d => d.Day).FirstOrDefault();

            var targetMonth = search?.ReportDate is DateTime picked
                ? _displayTimeZone.FromUtc(picked)
                : _displayTimeZone.Now;
            var monthStart = new DateTime(targetMonth.Year, targetMonth.Month, 1);
            var monthEnd = monthStart.AddMonths(1);
            var timeBreakdown = new TimeReportBreakdown
            {
                Month = monthStart,
                ReportsByDay = days
                    .Where(d => d.Day >= monthStart && d.Day < monthEnd && d.OfficeTotal > 0)
                    .ToDictionary(d => d.Day.Day, d => d.OfficeTotal),
            };

            return new ReportStatisticsResponse
            {
                TimePeriodWithMostRep = busiestDay == null ? default : DateTime.SpecifyKind(busiestDay.Day, DateTimeKind.Unspecified),
                OfficeWithMostRep = office == null ? null : new OfficeReportCount
                {
                    OfficeId = office.IntId!.Value,
                    OfficeName = office.Name,
                    ReportCount = office.Count,
                },
                DeviceWithMostRep = device == null ? null : new DeviceReportCount
                {
                    DeviceId = device.IntId!.Value,
                    DeviceName = device.Name,
                    ReportCount = device.Count,
                },
                UserWithMostRep = user == null ? null : new UserReportCount
                {
                    UserId = user.GuidId!.Value,
                    Username = user.Name,
                    ReportCount = user.Count,
                },
                TimeBreakdown = timeBreakdown,
            };
        }

        private enum TopDimension
        {
            Office,
            Device,
            User,
        }

        private sealed class TopEntry
        {
            public TopDimension Dimension { get; set; }
            public int? IntId { get; set; }
            public Guid? GuidId { get; set; }
            public string? Name { get; set; }
            public int Count { get; set; }
        }

        private sealed class ReportDayCount
        {
            public DateTime Day { get; set; }
            public int Total { get; set; }
            public int OfficeTotal { get; set; }
        }

    }
}
