using Deliverance.Model.Enums;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using Deliverance.Services.Messaging;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Deliverance.Services
{
    public class DeviceService : BaseCRUDService<Device, DeviceResponse, DeviceSearchObject
        , DeviceInsertRequest, DeviceUpdateRequest>, IDeviceService
    {

        private IScoutNotifier _scoutNotifier;
        private IValidator<ScoutCommandInsertRequest> _scoutCommandValidator;
        public DeviceService(DeliveranceDbContext dbContext, IMapper mapper,
            IValidator<DeviceInsertRequest> insertValidator,
             IValidator<DeviceUpdateRequest> updateValidator,
             IValidator<ScoutCommandInsertRequest> scoutCommandValidator
             , IScoutNotifier scoutNotifier)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _scoutNotifier = scoutNotifier;
            _scoutCommandValidator = scoutCommandValidator;
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
                    query = query.Where(p => p.Manufacturer.Contains(search.Manufacturer));
                }

                if (!string.IsNullOrWhiteSpace(search.MacAddress))
                {
                    query = query.Where(p => p.MacAddress.Contains(search.MacAddress));
                }
                if (!string.IsNullOrWhiteSpace(search.IpAddress))
                {
                    query = query.Where(p => p.IpAddress.Contains(search.IpAddress));
                }
            }

            return query;
        }

        public override async Task<DeviceResponse> InsertAsync(DeviceInsertRequest request, Guid userId)
        {
            var isAdmin = await _dbContext.Users.AnyAsync(u => u.UUID == userId && u.RoleId == RoleEnum.Admin);
            if (!isAdmin)
            {
                throw new ForbiddenException("Only admins can add devices.");
            }
            return await base.InsertAsync(request, userId);
        }

        public override async Task<DeviceResponse> UpdateAsync(int id, DeviceUpdateRequest request, Guid userId, bool isAdmin = false)
        {
            if (!isAdmin)
            {
                throw new ForbiddenException("Only admins can edit devices.");
            }
            return await base.UpdateAsync(id, request, userId, isAdmin);
        }

        public override async Task DeleteAsync(int id, Guid userId, bool isAdmin = false)
        {
            if (!isAdmin)
            {
                throw new ForbiddenException("Only admins can delete devices.");
            }
            var device = await _dbContext.Devices.FirstOrDefaultAsync(d => d.Id == id)
                ?? throw new NotFoundException($"Device with id {id} was not found.");

            var reportCount = await CountReportsAsync(_dbContext, [id]);
            if (reportCount.TryGetValue(id, out var count))
            {
                throw new BusinessException(
                    $"{device.Name} appears in {count} report(s) and can't be deleted, so the report history stays intact.");
            }

            _dbContext.Devices.Remove(device);
            await _dbContext.SaveChangesAsync();
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
            if (!isAdmin)
            {
                throw new ForbiddenException("Only admins can disable or enable scouts.");
            }
            var scout = await _dbContext.Scouts.FirstOrDefaultAsync(s => s.DeviceId == deviceId);
            if (scout == null)
            {
                throw new BusinessException("This device has no scout.");
            }
            scout.IsDisabled = isDisabled;
            await _dbContext.SaveChangesAsync();
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
