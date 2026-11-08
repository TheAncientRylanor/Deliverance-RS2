using Deliverance.Services.Messaging;
using Deliverance.Model.Enums;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services.Database;
using Deliverance.Services.Validators;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Deliverance.Services
{
    public class ScoutService : IScoutService
    {
        private const int LogMaxLength = 1000;

        private readonly DeliveranceDbContext _dbContext;
        private readonly IDeviceNotifier _deviceNotifier;
        private readonly IValidator<ScoutCommandResultRequest> _scoutCommandValidator;
        private readonly IValidator<ScoutLogBatchRequest> _scoutLogValidator;
        private readonly IMapper _mapper;

        public ScoutService(DeliveranceDbContext dbContext,
        IDeviceNotifier deviceNotifier,
        IValidator<ScoutCommandResultRequest> scoutCommandValidator,
        IValidator<ScoutLogBatchRequest> scoutLogValidator, IMapper mapper)
        {
            _dbContext = dbContext;
            _deviceNotifier = deviceNotifier;
            _scoutCommandValidator = scoutCommandValidator;
            _scoutLogValidator = scoutLogValidator;
            _mapper = mapper;
        }

        public async Task<ScoutResponse> GetMeAsync(int scoutId)
        {
            var scout = await _dbContext.Scouts.AsNoTracking()
                .Where(s => s.Id == scoutId)
                .Select(s => new ScoutResponse
                {
                    Id = s.Id,
                    CreatedAt = s.CreatedAt,
                    DeviceId = s.DeviceId,
                    DeviceName = s.Device!.Name,
                    OfficeId = s.Device.OfficeId,
                    OfficeName = s.Device.Office!.Name,
                })
                .FirstOrDefaultAsync();

            return scout ?? throw new UnauthorizedAccessException("This scout no longer exists.");
        }

        public async Task CommandUpdate(int commandId, ScoutCommandResultRequest result, int scoutId)
        {
            await _scoutCommandValidator.ValidateAndThrowAsync(result);

            var command = await _dbContext.ScoutCommands.Include(x => x.Scout)
                .FirstOrDefaultAsync(x => x.Id == commandId && x.ScoutId == scoutId);
            if (command is null)
            {
                throw new NotFoundException($"Command with id {commandId} was not found for this scout.");
            }
            if (command.Status != ScoutCommandStatusEnum.Pending && command.Status != ScoutCommandStatusEnum.Running)
            {
                throw new BusinessException("This command has already finished, so its result can't be changed.");
            }

            _mapper.Map(result, command);
            if (result.Status != ScoutCommandStatusEnum.Running)
            {
                command.CompletedAt = DateTime.UtcNow;
            }
            await _dbContext.SaveChangesAsync();

            var update = _mapper.Map<ScoutCommandResponse>(command);
            update.DeviceId = command.Scout!.DeviceId;
            await _deviceNotifier.CommandUpdated(update);
        }

        public async Task SaveLogsAsync(ScoutLogBatchRequest request, int scoutId)
        {
            await _scoutLogValidator.ValidateAndThrowAsync(request);

            var keys = request.Logs.Select(x => x.EventKey).Distinct().ToList();
            var savedKeys = await _dbContext.DeviceLogs
                .Where(x => x.ScoutId == scoutId && keys.Contains(x.EventKey!))
                .Select(x => x.EventKey!)
                .ToListAsync();

            var now = DateTime.UtcNow;
            var newLogs = request.Logs
                .DistinctBy(x => x.EventKey)
                .ExceptBy(savedKeys, x => x.EventKey)
                .Select(x => new DeviceLog
                {
                    ScoutId = scoutId,
                    EventKey = x.EventKey,
                    DateLogged = x.DateLogged.AsUtc() > now ? now : x.DateLogged.AsUtc(),
                    Log = FormatLog(x),
                });

            _dbContext.DeviceLogs.AddRange(newLogs);
            await _dbContext.SaveChangesAsync();
        }

        private static string FormatLog(ScoutLogEntryRequest log)
        {
            var repeated = log.Count > 1 ? $"(x{log.Count}) " : string.Empty;
            var line = $"[{log.Source} {log.EventId}] {repeated}{log.Message}";
            return line.Length <= LogMaxLength ? line : line[..LogMaxLength];
        }
    }
}
