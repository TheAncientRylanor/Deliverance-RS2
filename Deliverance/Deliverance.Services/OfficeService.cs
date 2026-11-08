using Deliverance.Model.Enums;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using Deliverance.Services.Validators;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Deliverance.Services
{
    public class OfficeService : BaseCRUDService<Office, OfficeResponse, OfficeSearchObject
        , OfficeInsertRequest, OfficeUpdateRequest>, IOfficeService
    {
        private readonly IScoutEnrollmentService _scoutEnrollmentService;
        public OfficeService(DeliveranceDbContext dbContext, IMapper mapper,
        IValidator<OfficeInsertRequest> insertValidator, IValidator<OfficeUpdateRequest> updateValidator,
        IScoutEnrollmentService scoutEnrollmentService)
        : base(dbContext, mapper, insertValidator, updateValidator)
        {
            _scoutEnrollmentService = scoutEnrollmentService;
        }


        protected override IQueryable<Office> ApplyFilters(IQueryable<Office> query, OfficeSearchObject? search, Guid userId, bool isAdmin = false)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(p => p.Name.Contains(search.Name));
                }
                if (search.Offices != null)
                {
                    query = query.Where(p => search.Offices.Contains(p.Id));
                }
                if (search.IncludeDevices || search.Offices != null)
                {
                    query = query.Include(x => x.Devices).ThenInclude(x => x.Scout);
                }
            }
            return query;
        }
        public override async Task<OfficeResponse> GetByIdAsync(int id, Guid userId, bool isAdmin = false)
        {
            var entity = await GetOfficeOrThrowAsync(id);
            var response = MapToResponse(entity, isAdmin);
            if (!isAdmin && response.Devices != null)
            {
                await AddReportHistoryAsync(response.Devices, userId);
            }
            return response;
        }

        public override async Task<PageResult<OfficeResponse>> GetAllAsync(OfficeSearchObject? search = null, Guid userId = default, bool isAdmin = false)
        {
            var result = await base.GetAllAsync(search, userId, isAdmin);
            if (!isAdmin && result.Items != null)
            {
                await AddReportHistoryAsync(result.Items.SelectMany(x => x.Devices ?? []).ToList(), userId);
            }
            return result;
        }

        private async Task AddReportHistoryAsync(List<DeviceReportSensitiveResponse> devices, Guid userId)
        {
            if (devices.Count == 0)
            {
                return;
            }

            var deviceIds = devices.Select(x => x.Id).ToList();
            var history = await _dbContext.DeviceReports
                .Where(dr => deviceIds.Contains(dr.DeviceId)
                    && dr.OfficeReport!.Report!.UserUUID == userId
                    && dr.OfficeReport.Report.Status != nameof(StatusEnum.DraftReportState))
                .GroupBy(dr => dr.DeviceId)
                .Select(g => new
                {
                    DeviceId = g.Key,
                    TimesReported = g.Count(),
                    HasOpenReport = g.Any(dr => dr.OfficeReport!.Report!.Status == nameof(StatusEnum.UnseenReportState)
                        || dr.OfficeReport.Report.Status == nameof(StatusEnum.SeenReportState)),
                })
                .ToDictionaryAsync(x => x.DeviceId);

            foreach (var device in devices)
            {
                var deviceHistory = history.GetValueOrDefault(device.Id);
                device.TimesReported = deviceHistory?.TimesReported ?? 0;
                device.HasOpenReport = deviceHistory?.HasOpenReport ?? false;
            }
        }

        protected override OfficeResponse MapToResponse(Office entity, bool isAdmin)
        {
            var response = base.MapToResponse(entity, isAdmin);
            if (!isAdmin && response.Devices != null)
            {
                response.Devices = _mapper.Map<List<DeviceReportSensitiveResponse>>(entity.Devices);
            }

            return response;
        }

        private async Task<Office> GetOfficeOrThrowAsync(int id)
        {
            return await _dbContext.Set<Office>()
                .Include(x => x.Devices).ThenInclude(d => d.Scout).AsNoTracking().FirstOrDefaultAsync(x => x.Id == id)
                ?? throw new NotFoundException($"Office with id {id} was not found.");
        }

        public async Task<OfficeResponse> GetFromReport(int officeReportId, int id, Guid userId, bool isAdmin = false)
        {
            var entity = await GetOfficeOrThrowAsync(id);

            var officeReport = await _dbContext.Set<OfficeReport>()
                .Where(x => x.Id == officeReportId && x.OfficeId == id)
                .Select(x => new { x.Report!.UserUUID })
                .FirstOrDefaultAsync()
                ?? throw new BusinessException("Report does not belong to this office.");
            if (!isAdmin && officeReport.UserUUID != userId)
            {
                throw new ForbiddenException("You do not have access to this report.");
            }

            var reportedDeviceIds = await _dbContext.DeviceReports
                .Where(x => x.OfficeReportId == officeReportId)
                .Select(x => x.DeviceId)
                .ToHashSetAsync();

            var mapDto = MapToResponse(entity, isAdmin);
            if (mapDto.Devices != null)
            {
                foreach (var device in mapDto.Devices.OfType<DeviceResponse>())
                {
                    device.IsReported = reportedDeviceIds.Contains(device.Id);
                }
            }
            return mapDto;
        }

        protected override Office MapInsertRequestToEntity(OfficeInsertRequest request)
        {
            var entity = base.MapInsertRequestToEntity(request);
            var createdAt = DateTime.UtcNow;
            entity.Devices = request.Devices?.Select(x => new Device
            {
                OfficeName = entity.Name,
                CreatedAt = createdAt,
                IconName = x.IconName,
                IpAddress = x.IpAddress,
                MacAddress = x.MacAddress,
                Manufacturer = x.Manufacturer,
                SubnetMask = x.SubnetMask,
                VlanID = x.VlanID,
                PositionX = x.PositionX,
                PositionY = x.PositionY,
                Type = x.Type,
                OS = x.OS,
                Name = x.Name,
            }).ToList() ?? new List<Device>();
            return entity;
        }
        public override async Task<OfficeResponse> InsertAsync(OfficeInsertRequest request, Guid userId)
        {
            var isAdmin = await _dbContext.Users.AnyAsync(u => u.UUID == userId && u.RoleId == RoleEnum.Admin);
            EnsureAdmin(isAdmin);
            await _insertValidator.ValidateAndThrowAsync(request);
            await EnsureNameIsFreeAsync(request.Name);
            var enrollments = await _scoutEnrollmentService.GetClaimedForLinkingAsync(
                request.Devices?.Select(d => d.EnrollmentId) ?? [], userId);

            var entity = MapInsertRequestToEntity(request);
            entity.CreatedAt = DateTime.UtcNow;
            entity.UserUUID = userId;
            foreach (var (device, deviceRequest) in entity.Devices.Zip(request.Devices ?? []))
            {
                AttachEnrollment(device, deviceRequest.EnrollmentId, enrollments);
            }

            _dbContext.Set<Office>().Add(entity);
            await _dbContext.SaveChangesAsync();
            return _mapper.Map<OfficeResponse>(entity);
        }

        private void AttachEnrollment(Device device, int? enrollmentId,
            IReadOnlyDictionary<int, ScoutEnrollment> enrollments)
        {
            if (enrollmentId is int id)
            {
                _scoutEnrollmentService.AttachToDevice(enrollments[id], device);
            }
        }

        private async Task EnsureNameIsFreeAsync(string name, int? excludeOfficeId = null)
        {
            var trimmed = name.Trim();
            var taken = await _dbContext.Set<Office>()
                .AnyAsync(o => o.Name == trimmed && o.Id != excludeOfficeId);
            if (taken)
            {
                throw FieldRules.FieldError("Name",
                    $"An office named {trimmed} already exists. Office names must be unique.");
            }
        }

        public override async Task<OfficeResponse> UpdateAsync(int id, OfficeUpdateRequest request, Guid userId, bool isAdmin = false)
        {
            EnsureAdmin(isAdmin);
            await _updateValidator.ValidateAndThrowAsync(request);
            await EnsureNameIsFreeAsync(request.Name, id);

            var entity = await _dbContext.Set<Office>()
                .Include(x => x.Devices)
                .ThenInclude(d => d.Scout)
                .FirstOrDefaultAsync(x => x.Id == id);
            if (entity == null)
            {
                throw new NotFoundException($"Office with id {id} was not found.");
            }
            await EnsureRemovedDevicesHaveNoReportsAsync(entity, request);
            var enrollments = await _scoutEnrollmentService.GetClaimedForLinkingAsync(
                request.Devices?.Select(d => d.EnrollmentId) ?? [], userId);

            MapUpdateRequestToEntity(request, entity, enrollments);
            entity.UpdatedAt = DateTime.UtcNow;
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<OfficeResponse>(entity);
        }

        public override async Task DeleteAsync(int id, Guid userId, bool isAdmin = false)
        {
            EnsureAdmin(isAdmin);

            var entity = await _dbContext.Set<Office>()
                .Include(x => x.Devices)
                .FirstOrDefaultAsync(x => x.Id == id);
            if (entity == null)
            {
                throw new NotFoundException($"Office with id {id} was not found.");
            }

            var reportCount = await _dbContext.Set<OfficeReport>().CountAsync(x => x.OfficeId == id);
            if (reportCount > 0)
            {
                throw new BusinessException(
                    $"{entity.Name} appears in {reportCount} report(s) and can't be deleted, so the report history stays intact.");
            }

            _dbContext.RemoveRange(entity.Devices);
            _dbContext.Remove(entity);
            await _dbContext.SaveChangesAsync();
        }

        private async Task EnsureRemovedDevicesHaveNoReportsAsync(Office entity, OfficeUpdateRequest request)
        {
            if (request.Devices == null) return;

            var keptIds = request.Devices.Select(d => d.Id).ToHashSet();
            var removed = entity.Devices.Where(d => !keptIds.Contains(d.Id)).ToList();
            if (removed.Count == 0) return;

            var reportCounts = await DeviceService.CountReportsAsync(_dbContext, removed.Select(d => d.Id).ToList());
            var blocked = removed
                .Where(d => reportCounts.ContainsKey(d.Id))
                .Select(d => $"{d.Name} ({reportCounts[d.Id]} report(s))")
                .ToList();
            if (blocked.Count > 0)
            {
                throw new BusinessException(
                    $"These devices appear in reports and can't be removed, so the report history stays intact: {string.Join(", ", blocked)}.");
            }
        }

        private static void EnsureAdmin(bool isAdmin)
        {
            if (!isAdmin)
            {
                throw new ForbiddenException("Only admins can manage offices.");
            }
        }

        protected override void MapUpdateRequestToEntity(OfficeUpdateRequest request, Office entity)
            => MapUpdateRequestToEntity(request, entity, new Dictionary<int, ScoutEnrollment>());

        private void MapUpdateRequestToEntity(OfficeUpdateRequest request, Office entity,
            IReadOnlyDictionary<int, ScoutEnrollment> enrollments)
        {
            entity.Name = request.Name;
            CollectionSync.Sync(
                entity.Devices,
                request.Devices,
                device => device.Id.ToString(),
                deviceRequest => deviceRequest.Id.ToString(),
                deviceRequest =>
                {
                    var device = new Device
                    {
                        OfficeId = entity.Id,
                        OfficeName = entity.Name,
                        CreatedAt = DateTime.UtcNow,
                        IconName = deviceRequest.IconName,
                        IpAddress = deviceRequest.IpAddress,
                        MacAddress = deviceRequest.MacAddress,
                        Manufacturer = deviceRequest.Manufacturer,
                        SubnetMask = deviceRequest.SubnetMask,
                        VlanID = deviceRequest.VlanID,
                        PositionX = deviceRequest.PositionX,
                        PositionY = deviceRequest.PositionY,
                        Type = deviceRequest.Type,
                        OS = deviceRequest.OS,
                        Name = deviceRequest.Name,
                    };
                    AttachEnrollment(device, deviceRequest.EnrollmentId, enrollments);
                    return device;
                },
                (existingDevice, deviceRequest) =>
                {
                    AttachEnrollment(existingDevice, deviceRequest.EnrollmentId, enrollments);
                    existingDevice.OfficeName = entity.Name;
                    existingDevice.IconName = deviceRequest.IconName;
                    existingDevice.IpAddress = deviceRequest.IpAddress;
                    existingDevice.MacAddress = deviceRequest.MacAddress;
                    existingDevice.Manufacturer = deviceRequest.Manufacturer;
                    existingDevice.SubnetMask = deviceRequest.SubnetMask;
                    existingDevice.VlanID = deviceRequest.VlanID;
                    existingDevice.PositionX = deviceRequest.PositionX;
                    existingDevice.PositionY = deviceRequest.PositionY;
                    existingDevice.Type = deviceRequest.Type;
                    existingDevice.OS = deviceRequest.OS;
                    existingDevice.Name = deviceRequest.Name;
                }
            );
        }
    }

}
