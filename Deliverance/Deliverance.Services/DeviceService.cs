using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using FluentValidation;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Deliverance.Services
{
    public class DeviceService : BaseCRUDService<Device,DeviceResponse,DeviceSearchObject
        ,DeviceInsertRequest,DeviceUpdateRequest>,IDeviceService
    {
        public DeviceService(DeliveranceDbContext dbContext,IMapper mapper,
            IValidator<DeviceInsertRequest> insertValidator, IValidator<DeviceUpdateRequest> updateValidator)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {

        }

        protected override IEnumerable<Device> ApplyFilters(IEnumerable<Device> query, DeviceSearchObject? search,Guid userId)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(p => p.Name.Contains(search.Name, StringComparison.OrdinalIgnoreCase));
                }
                if (!string.IsNullOrWhiteSpace(search.Manufacturer))
                {
                    query = query.Where(p => p.Manufacturer.Contains(search.Manufacturer, StringComparison.OrdinalIgnoreCase));
                }

                if (!string.IsNullOrWhiteSpace(search.MacAddress))
                {
                    query = query.Where(p => p.MacAddress.Contains(search.MacAddress, StringComparison.OrdinalIgnoreCase));
                }
                if (!string.IsNullOrWhiteSpace(search.IpAddress))
                {
                    query = query.Where(p => p.IpAddress.Contains(search.IpAddress, StringComparison.OrdinalIgnoreCase));
                }
            }

            return query;
        }
    }
}
