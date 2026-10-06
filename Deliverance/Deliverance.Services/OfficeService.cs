using Deliverance.Model.Enums;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Deliverance.Services
{
    public class OfficeService : BaseCRUDService<Office, OfficeResponse, OfficeSearchObject
        ,OfficeInsertRequest, OfficeUpdateRequest>,IOfficeService
    {
           protected readonly DeliveranceDbContext _dbContext;
        public OfficeService(DeliveranceDbContext dbContext, IMapper mapper,
        IValidator<OfficeInsertRequest> insertValidator,IValidator<OfficeUpdateRequest> updateValidator) 
        : base(dbContext, mapper,insertValidator,updateValidator)
        {
            _dbContext = dbContext;
        }

   
        protected override IQueryable<Office> ApplyFilters(IQueryable<Office> query, OfficeSearchObject? search,Guid userId, bool isAdmin = false)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(p => p.Name.Contains(search.Name));
                }
                if(search.Offices!= null)
                {
                    query = query.Where(p=> search.Offices.Contains(p.Id));
                }
                // Lists only load devices when asked for them, or when specific
                // offices are requested (the mobile report wizard needs their
                // devices). Dropdowns only need id and name.
                if (search.IncludeDevices || search.Offices != null)
                {
                    query = query.Include(x => x.Devices);
                }
            }
            return query;
        }
        public override async Task<OfficeResponse> GetByIdAsync(int id, Guid userId, bool isAdmin = false)
        {
            var entity = await GetOfficeOrThrowAsync(id, userId, isAdmin);
            return _mapper.Map<OfficeResponse>(entity);
        }

        private async Task<Office> GetOfficeOrThrowAsync(int id, Guid userId, bool isAdmin)
        {
            var entity = await _dbContext.Set<Office>()
            .Include(x=>x.Devices).AsNoTracking().FirstOrDefaultAsync(x=>x.Id == id);
            if(entity == null)
            {
                throw new ClientException("Office does not exist");
            }
            if(!isAdmin && entity.UserUUID != userId)
            {
                throw new ClientException("You do not have access to this office.");
            }
            return entity;
        }

        public async Task<OfficeResponse> GetFromReport(int officeReportId, int id, Guid userId, bool isAdmin = false)
        {
            var entity = await GetOfficeOrThrowAsync(id, userId, isAdmin);

            var reportBelongsToOffice = await _dbContext.Set<OfficeReport>()
                .AnyAsync(x => x.Id == officeReportId && x.OfficeId == id);
            if (!reportBelongsToOffice)
            {
                throw new ClientException("Report does not belong to this office.");
            }

            var reportedDeviceIds = await _dbContext.DeviceReports
                .Where(x => x.OfficeReportId == officeReportId)
                .Select(x => x.DeviceId)
                .ToHashSetAsync();

            var mapDto = _mapper.Map<OfficeResponse>(entity);
            if (mapDto.Devices != null)
            {
                foreach(var device in mapDto.Devices)
                {
                    device.IsReported = reportedDeviceIds.Contains(device.Id);
                }
            }
            return mapDto;
        }
        
        protected override Office MapInsertRequestToEntity(OfficeInsertRequest request)
        {
            var entity =  base.MapInsertRequestToEntity(request);
            entity.Devices = request.Devices?.Select(x=>new Device
            {
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
            await EnsureNameIsFreeAsync(request.Name);
            return await base.InsertAsync(request, userId);
        }

        /// <summary>
        /// Office names are unique (unique index on Offices.Name). Checking first
        /// gives a clear message instead of a database error.
        /// </summary>
        private async Task EnsureNameIsFreeAsync(string name, int? excludeOfficeId = null)
        {
            var trimmed = name.Trim();
            var taken = await _dbContext.Set<Office>()
                .AnyAsync(o => o.Name == trimmed && o.Id != excludeOfficeId);
            if (taken)
            {
                throw new ClientException($"An office named '{trimmed}' already exists.");
            }
        }

        public override async Task<OfficeResponse> UpdateAsync(int id, OfficeUpdateRequest request, Guid userId, bool isAdmin = false)
        {
            EnsureAdmin(isAdmin);
            await _updateValidator.ValidateAndThrowAsync(request);
            await EnsureNameIsFreeAsync(request.Name, id);

            // Devices must be loaded so SyncCollection can match them by id;
            // the base UpdateAsync uses Find(), which leaves the collection empty.
            var entity = await _dbContext.Set<Office>()
                .Include(x => x.Devices)
                .FirstOrDefaultAsync(x => x.Id == id);
            if (entity == null)
            {
                throw new ClientException("Office does not exist");
            }

            MapUpdateRequestToEntity(request, entity);
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
                throw new KeyNotFoundException($"Office with id {id} not found.");
            }

            // Offices that appear in reports are kept, so report history stays intact.
            var hasReports = await _dbContext.Set<OfficeReport>().AnyAsync(x => x.OfficeId == id);
            if (hasReports)
            {
                throw new ClientException("This office has reports and can't be deleted.");
            }

            // Device -> Office is Restrict in the database, so the devices have to
            // be removed explicitly before the office.
            _dbContext.RemoveRange(entity.Devices);
            _dbContext.Remove(entity);
            await _dbContext.SaveChangesAsync();
        }

        private static void EnsureAdmin(bool isAdmin)
        {
            if (!isAdmin)
            {
                throw new ClientException("Only admins can manage offices.");
            }
        }

        protected override void MapUpdateRequestToEntity(OfficeUpdateRequest request, Office entity)
        {
            // Mapped by hand: letting Mapster map the request would replace the
            // tracked Devices collection with new, untracked Device objects.
            entity.Name = request.Name;
            SyncCollection(
                entity.Devices,
                request.Devices,
                device => device.Id.ToString(),
                deviceRequest => deviceRequest.Id.ToString(),
                deviceRequest => new Device
                {
                    OfficeId = entity.Id,
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
                },
                (existingDevice, deviceRequest) =>
                {
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
