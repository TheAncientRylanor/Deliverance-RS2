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
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

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

        public async Task SetScoutDisabledAsync(int deviceId, bool isDisabled, bool isAdmin)
        {
            if (!isAdmin)
            {
                throw new ClientException("Only admins can disable or enable scouts.");
            }
            var scout = await _dbContext.Scouts.FirstOrDefaultAsync(s => s.DeviceId == deviceId);
            if (scout == null)
            {
                throw new ClientException("This device has no scout.");
            }
            scout.IsDisabled = isDisabled;
            await _dbContext.SaveChangesAsync();
        }

        public async Task<ScoutCommandResponse> SendDeviceCommand(ScoutCommandInsertRequest command, Guid userId, bool isAdmin)
        {

            if (!isAdmin)
            {
                throw new ClientException("Only admins can send commands to scouts.");
            }
            var device = await _dbContext.Devices.Include(x => x.Scout).FirstOrDefaultAsync(x => x.Id == command.DeviceId);
            if (device is null)
            {
                throw new ClientException("Device does not exist inside the database");
            }
            if (device.Scout is null)
            {
                throw new ClientException($"Current device {device.Name} is not a scout");
            }
            if (device.Scout.IsDisabled)
            {
                throw new ClientException("Scout is disabled and cannot recieve any commands");
            }
            await _scoutCommandValidator.ValidateAndThrowAsync(command);

            // Saved first, so the scout gets the Id it reports the result to.
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
