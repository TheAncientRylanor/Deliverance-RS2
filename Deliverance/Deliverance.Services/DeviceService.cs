using Deliverance.Model.Enums;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using Deliverance.Services.Messaging;
using Deliverance.Services.Validators;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System.Net;
using System.Net.NetworkInformation;

namespace Deliverance.Services
{
    public class DeviceService : BaseCRUDService<Device, DeviceResponse, DeviceSearchObject
        , DeviceInsertRequest, DeviceUpdateRequest>, IDeviceService
    {

        private static readonly TimeSpan PingTimeout = TimeSpan.FromSeconds(2);

        private readonly IScoutNotifier _scoutNotifier;
        private readonly IValidator<ScoutCommandInsertRequest> _scoutCommandValidator;
        private readonly IScoutEnrollmentService _scoutEnrollmentService;
        public DeviceService(DeliveranceDbContext dbContext, IMapper mapper,
            IValidator<DeviceInsertRequest> insertValidator,
             IValidator<DeviceUpdateRequest> updateValidator,
             IValidator<ScoutCommandInsertRequest> scoutCommandValidator
             , IScoutNotifier scoutNotifier, IScoutEnrollmentService scoutEnrollmentService)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _scoutNotifier = scoutNotifier;
            _scoutCommandValidator = scoutCommandValidator;
            _scoutEnrollmentService = scoutEnrollmentService;
        }

        public override IQueryable<Device> GetQuery()
        {
            return _dbContext.Devices.Include(d => d.Scout);
        }

        protected override IQueryable<Device> ApplyFilters(IQueryable<Device> query, DeviceSearchObject? search, Guid userId, bool isAdmin = false)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(p => p.Name.Contains(search.Name));
                }
                if (!string.IsNullOrWhiteSpace(search.Manufacturer))
                {
                    query = query.Where(p => p.Manufacturer != null && p.Manufacturer.Contains(search.Manufacturer));
                }

                if (!string.IsNullOrWhiteSpace(search.MacAddress))
                {
                    query = query.Where(p => p.MacAddress != null && p.MacAddress.Contains(search.MacAddress));
                }
                if (!string.IsNullOrWhiteSpace(search.IpAddress))
                {
                    query = query.Where(p => p.IpAddress != null && p.IpAddress.Contains(search.IpAddress));
                }
            }

            return query;
        }

        public override Task<PageResult<DeviceResponse>> GetAllAsync(DeviceSearchObject? search = null, Guid userId = default, bool isAdmin = false)
        {
            EnsureAdmin(isAdmin, "Only admins can see device details. Devices are listed under their office.");
            return base.GetAllAsync(search, userId, isAdmin);
        }

        public override async Task<DeviceResponse> GetByIdAsync(int id, Guid userId, bool isAdmin = false)
        {
            EnsureAdmin(isAdmin, "Only admins can see device details. Devices are listed under their office.");
            var device = await GetQuery().AsNoTracking().FirstOrDefaultAsync(d => d.Id == id)
                ?? throw new NotFoundException($"Device with id {id} was not found.");
            return _mapper.Map<DeviceResponse>(device);
        }

        public override async Task<DeviceResponse> InsertAsync(DeviceInsertRequest request, Guid userId)
        {
            var isAdmin = await _dbContext.Users.AnyAsync(u => u.UUID == userId && u.RoleId == RoleEnum.Admin);
            EnsureAdmin(isAdmin, "Only admins can add devices.");
            await _insertValidator.ValidateAndThrowAsync(request);
            if (string.IsNullOrWhiteSpace(request.OfficeName))
            {
                throw FieldRules.FieldError(nameof(DeviceInsertRequest.OfficeName), "Choose the office the device is in");
            }
            var office = await FindOfficeOrThrowAsync(request.OfficeName);
            var enrollments = await _scoutEnrollmentService.GetClaimedForLinkingAsync([request.EnrollmentId], userId);

            var device = MapInsertRequestToEntity(request);
            device.OfficeId = office.Id;
            device.OfficeName = office.Name;
            device.CreatedAt = DateTime.UtcNow;
            if (request.EnrollmentId is int enrollmentId)
            {
                _scoutEnrollmentService.AttachToDevice(enrollments[enrollmentId], device);
            }

            _dbContext.Devices.Add(device);
            await _dbContext.SaveChangesAsync();
            return _mapper.Map<DeviceResponse>(device);
        }

        public override async Task<DeviceResponse> UpdateAsync(int id, DeviceUpdateRequest request, Guid userId, bool isAdmin = false)
        {
            EnsureAdmin(isAdmin, "Only admins can edit devices.");
            await _updateValidator.ValidateAndThrowAsync(request);
            var device = await _dbContext.Devices.Include(d => d.Scout).FirstOrDefaultAsync(d => d.Id == id)
                ?? throw new NotFoundException($"Device with id {id} was not found.");

            var office = string.IsNullOrWhiteSpace(request.OfficeName)
                ? null
                : await FindOfficeOrThrowAsync(request.OfficeName);
            if (office != null && office.Id != device.OfficeId)
            {
                await EnsureNotInReportsAsync(device, "moved to another office");
            }
            var enrollments = await _scoutEnrollmentService.GetClaimedForLinkingAsync([request.EnrollmentId], userId);

            device.Name = request.Name;
            device.IconName = request.IconName;
            device.IpAddress = request.IpAddress;
            device.MacAddress = request.MacAddress;
            device.Manufacturer = request.Manufacturer;
            device.SubnetMask = request.SubnetMask;
            device.VlanID = request.VlanID;
            device.PositionX = request.PositionX;
            device.PositionY = request.PositionY;
            device.Type = request.Type;
            device.OS = request.OS;
            if (office != null)
            {
                device.OfficeId = office.Id;
                device.OfficeName = office.Name;
            }
            if (request.EnrollmentId is int enrollmentId)
            {
                _scoutEnrollmentService.AttachToDevice(enrollments[enrollmentId], device);
            }
            device.UpdatedAt = DateTime.UtcNow;

            await _dbContext.SaveChangesAsync();
            return _mapper.Map<DeviceResponse>(device);
        }

        public override async Task DeleteAsync(int id, Guid userId, bool isAdmin = false)
        {
            EnsureAdmin(isAdmin, "Only admins can delete devices.");
            var device = await _dbContext.Devices.FirstOrDefaultAsync(d => d.Id == id)
                ?? throw new NotFoundException($"Device with id {id} was not found.");

            await EnsureNotInReportsAsync(device, "deleted");

            _dbContext.Devices.Remove(device);
            await _dbContext.SaveChangesAsync();
        }

        private async Task<Office> FindOfficeOrThrowAsync(string officeName)
        {
            var trimmed = officeName.Trim();
            return await _dbContext.Offices.FirstOrDefaultAsync(o => o.Name == trimmed)
                ?? throw FieldRules.FieldError(nameof(DeviceInsertRequest.OfficeName), $"There is no office named {trimmed}");
        }

        private async Task EnsureNotInReportsAsync(Device device, string action)
        {
            var reportCount = await CountReportsAsync(_dbContext, [device.Id]);
            if (reportCount.TryGetValue(device.Id, out var count))
            {
                throw new BusinessException(
                    $"{device.Name} appears in {count} report(s) and can't be {action}, so the report history stays intact.");
            }
        }

        private static void EnsureAdmin(bool isAdmin, string message)
        {
            if (!isAdmin)
            {
                throw new ForbiddenException(message);
            }
        }

        public static async Task<Dictionary<int, int>> CountReportsAsync(DeliveranceDbContext dbContext,
            IReadOnlyCollection<int> deviceIds)
        {
            return await dbContext.DeviceReports
                .Where(dr => deviceIds.Contains(dr.DeviceId))
                .GroupBy(dr => dr.DeviceId)
                .Select(g => new { DeviceId = g.Key, Count = g.Select(dr => dr.OfficeReport!.ReportId).Distinct().Count() })
                .ToDictionaryAsync(x => x.DeviceId, x => x.Count);
        }

        public async Task SetScoutDisabledAsync(int deviceId, bool isDisabled, bool isAdmin)
        {
            EnsureAdmin(isAdmin, "Only admins can disable or enable scouts.");
            var device = await _dbContext.Devices.Include(d => d.Scout).FirstOrDefaultAsync(d => d.Id == deviceId)
                ?? throw new NotFoundException($"Device with id {deviceId} was not found.");
            var scout = device.Scout
                ?? throw new BusinessException($"{device.Name} has no scout.");
            scout.IsDisabled = isDisabled;
            await _dbContext.SaveChangesAsync();
        }

        public async Task<PageResult<DeviceEvidenceLogResponse>> GetRecentLogsAsync(int deviceId, bool isAdmin)
        {
            if (!isAdmin)
            {
                throw new ForbiddenException("Only admins can see device logs.");
            }
            if (!await _dbContext.Devices.AnyAsync(d => d.Id == deviceId))
            {
                throw new NotFoundException($"Device with id {deviceId} was not found.");
            }

            var logs = _dbContext.DeviceLogs.AsNoTracking().Where(l => l.Scout!.DeviceId == deviceId);
            var totalCount = await logs.CountAsync();
            var items = await logs
                .OrderByDescending(l => l.DateLogged)
                .Take(DeviceRecommendationService.RecentLogsLimit)
                .Select(l => new DeviceEvidenceLogResponse { DateLogged = l.DateLogged, Log = l.Log ?? string.Empty })
                .ToListAsync();

            return new PageResult<DeviceEvidenceLogResponse>
            {
                Items = items,
                TotalCount = totalCount,
                TotalPages = Paging.TotalPages(totalCount, DeviceRecommendationService.RecentLogsLimit),
            };
        }

        public async Task<DevicePingResponse> PingAsync(int deviceId, bool isAdmin)
        {
            if (!isAdmin)
            {
                throw new ForbiddenException("Only admins can check if a device is online.");
            }
            var ipAddress = await _dbContext.Devices
                .Where(d => d.Id == deviceId)
                .Select(d => new { d.IpAddress })
                .FirstOrDefaultAsync()
                ?? throw new NotFoundException($"Device with id {deviceId} was not found.");
            if (!IPAddress.TryParse(ipAddress.IpAddress, out var address))
            {
                throw new BusinessException("This device has no valid IP address to check.");
            }

            using var ping = new Ping();
            try
            {
                var reply = await ping.SendPingAsync(address, PingTimeout);
                return reply.Status == IPStatus.Success
                    ? new DevicePingResponse { IsOnline = true, RoundtripMs = reply.RoundtripTime }
                    : new DevicePingResponse { IsOnline = false };
            }
            catch (PingException)
            {
                return new DevicePingResponse { IsOnline = false };
            }
        }

        public async Task<ScoutCommandResponse> SendDeviceCommand(ScoutCommandInsertRequest command, Guid userId, bool isAdmin)
        {

            if (!isAdmin)
            {
                throw new ForbiddenException("Only admins can send commands to scouts.");
            }
            var device = await _dbContext.Devices.Include(x => x.Scout).FirstOrDefaultAsync(x => x.Id == command.DeviceId);
            if (device is null)
            {
                throw new NotFoundException($"Device with id {command.DeviceId} was not found.");
            }
            if (device.Scout is null)
            {
                throw new BusinessException($"{device.Name} has no scout installed, so it can't run commands.");
            }
            if (device.Scout.IsDisabled)
            {
                throw new BusinessException($"The scout on {device.Name} is disabled, so it can't receive commands. Enable it first.");
            }
            await _scoutCommandValidator.ValidateAndThrowAsync(command);

            var entity = new ScoutCommand
            {
                ScoutId = device.Scout.Id,
                ExecutionCommandId = command.ExecutionCommandId,
                CommandText = command.CommandText,
                Status = ScoutCommandStatusEnum.Pending,
                CreatedByUserUUID = userId,
                CreatedAt = DateTime.UtcNow,
            };
            _dbContext.ScoutCommands.Add(entity);
            await _dbContext.SaveChangesAsync();

            var response = _mapper.Map<ScoutCommandResponse>(entity);
            response.DeviceId = device.Id;
            await _scoutNotifier.CommandSent(response);
            return response;
        }
    }
}
