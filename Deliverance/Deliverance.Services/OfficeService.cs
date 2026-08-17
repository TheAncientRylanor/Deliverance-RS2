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
        public OfficeService(DeliveranceDbContext dbContext, IMapper mapper,
        IValidator<OfficeInsertRequest> insertValidator,IValidator<OfficeUpdateRequest> updateValidator) 
        : base(dbContext, mapper,insertValidator,updateValidator)
        {

        }

   
        protected override IEnumerable<Office> ApplyFilters(IEnumerable<Office> query, OfficeSearchObject? search,Guid userId)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(p => p.Name.Contains(search.Name, StringComparison.OrdinalIgnoreCase));
                }
            }
            return query;
        }
        public override async Task<PageResult<OfficeResponse>> GetAllAsync(OfficeSearchObject? search = null, Guid userId = default)
        {
            var result = await base.GetAllAsync(search, userId);
            result.Items = result.Items.Select(x=> new OfficeResponse{Name = x.Name,Id = x.Id}).ToList();
            return result;
        }
        public override async Task<OfficeResponse> GetByIdAsync(int id, Guid userId)
        {
            var entity = this._dbContext.Set<Office>()
            .Include(x=>x.Devices).AsNoTracking().FirstOrDefault(x=>x.Id == id);
            if(entity == null)
            {
                throw new ClientException("Office does not exist");
            }
            if(entity.UserUUID != userId)
            {
                throw new ClientException("You do not have access to this office."); 
            }
            return await Task.FromResult(_mapper.Map<OfficeResponse>(entity));
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
        protected override void MapUpdateRequestToEntity(OfficeUpdateRequest request, Office entity)
        {
            base.MapUpdateRequestToEntity(request, entity);
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
        public override IEnumerable<Office> GetQuery()
        {
            return _dbContext.Set<Office>()
            .Include(x=>x.Devices);
        }
    }

}
