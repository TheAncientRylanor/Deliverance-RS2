using Deliverance.Model.Enums;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Services.Configuration;
using Deliverance.Services.Database;
using Deliverance.Services.Messaging;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Deliverance.Services
{
    public class ScoutEnrollmentService : IScoutEnrollmentService
    {
        private readonly DeliveranceDbContext _dbContext;
        private readonly IMapper _mapper;
        private readonly IValidator<ScoutEnrollmentClaimRequest> _claimValidator;
        private readonly IScoutEnrollmentNotifier _notifier;
        private readonly TimeSpan _tokenLifetime;

        public ScoutEnrollmentService(DeliveranceDbContext dbContext, IMapper mapper,
            IValidator<ScoutEnrollmentClaimRequest> claimValidator, IScoutEnrollmentNotifier notifier,
            AuthSettings authSettings)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _claimValidator = claimValidator;
            _notifier = notifier;
            _tokenLifetime = authSettings.ScoutEnrollmentTokenLifetime;
        }

        public async Task<ScoutEnrollmentTokenResponse> CreateAsync(Guid userId, bool isAdmin)
        {
            EnsureAdmin(isAdmin);

            var token = ScoutSecrets.Generate();
            var now = DateTime.UtcNow;
            var enrollment = new ScoutEnrollment
            {
                TokenHash = ScoutSecrets.Hash(token),
                CreatedByUserUUID = userId,
                CreatedAt = now,
                ExpiresAt = now.Add(_tokenLifetime),
                Status = ScoutEnrollmentStatusEnum.Pending,
            };
            _dbContext.ScoutEnrollments.Add(enrollment);
            await _dbContext.SaveChangesAsync();

            return new ScoutEnrollmentTokenResponse
            {
                EnrollmentId = enrollment.Id,
                Token = token,
                ExpiresAt = enrollment.ExpiresAt,
            };
        }

        public async Task<ScoutEnrollmentResponse> GetByIdAsync(int id, Guid userId, bool isAdmin)
        {
            var enrollment = await GetOwnedOrThrowAsync(id, userId, isAdmin);
            return _mapper.Map<ScoutEnrollmentResponse>(enrollment);
        }

        public async Task CancelAsync(int id, Guid userId, bool isAdmin)
        {
            var enrollment = await GetOwnedOrThrowAsync(id, userId, isAdmin);
            if (enrollment.Status == ScoutEnrollmentStatusEnum.Completed)
            {
                throw new BusinessException("This enrollment is already completed and can't be cancelled.");
            }
            enrollment.Status = ScoutEnrollmentStatusEnum.Cancelled;
            await _dbContext.SaveChangesAsync();
        }

        public async Task<ScoutEnrollmentClaimResponse> ClaimAsync(ScoutEnrollmentClaimRequest request)
        {
            await _claimValidator.ValidateAndThrowAsync(request);

            var tokenHash = ScoutSecrets.Hash(request.Token.Trim());
            var scoutSecret = ScoutSecrets.Generate();
            var secretHash = ScoutSecrets.Hash(scoutSecret);
            var now = DateTime.UtcNow;
            var ipAddress = Clean(request.IpAddress);
            var macAddress = Clean(request.MacAddress);
            var subnetMask = Clean(request.SubnetMask);
            var vlanId = Clean(request.VlanID);
            var os = Clean(request.OS);
            var manufacturer = Clean(request.Manufacturer);
            var hostname = Clean(request.Hostname);

            var claimed = await _dbContext.ScoutEnrollments
                .Where(x => x.TokenHash == tokenHash
                    && x.Status == ScoutEnrollmentStatusEnum.Pending
                    && x.ExpiresAt > now)
                .ExecuteUpdateAsync(s => s
                    .SetProperty(x => x.Status, ScoutEnrollmentStatusEnum.Claimed)
                    .SetProperty(x => x.ClaimedAt, now)
                    .SetProperty(x => x.SecretHash, secretHash)
                    .SetProperty(x => x.IpAddress, ipAddress)
                    .SetProperty(x => x.MacAddress, macAddress)
                    .SetProperty(x => x.SubnetMask, subnetMask)
                    .SetProperty(x => x.VlanID, vlanId)
                    .SetProperty(x => x.OS, os)
                    .SetProperty(x => x.Manufacturer, manufacturer)
                    .SetProperty(x => x.Hostname, hostname));
            if (claimed == 0)
            {
                throw new BusinessException("The enrollment token is invalid, has expired or was already used.");
            }

            var enrollment = await _dbContext.ScoutEnrollments.AsNoTracking()
                .FirstAsync(x => x.TokenHash == tokenHash);
            await _notifier.EnrollmentClaimedAsync(_mapper.Map<ScoutEnrollmentResponse>(enrollment));

            return new ScoutEnrollmentClaimResponse { ScoutSecret = scoutSecret };
        }

        public async Task<IReadOnlyDictionary<int, ScoutEnrollment>> GetClaimedForLinkingAsync(
            IEnumerable<int?> enrollmentIds, Guid userId)
        {
            var ids = enrollmentIds.Where(id => id.HasValue).Select(id => id!.Value).ToList();
            if (ids.Count == 0)
            {
                return new Dictionary<int, ScoutEnrollment>();
            }
            if (ids.Distinct().Count() != ids.Count)
            {
                throw new BusinessException("The same scout enrollment can't be used for two devices.");
            }

            var enrollments = await _dbContext.ScoutEnrollments
                .Where(x => ids.Contains(x.Id))
                .ToDictionaryAsync(x => x.Id);

            foreach (var id in ids)
            {
                if (!enrollments.TryGetValue(id, out var enrollment) || enrollment.CreatedByUserUUID != userId)
                {
                    throw new BusinessException($"Scout enrollment {id} was not found or was created by another admin. Generate a new enrollment token.");
                }
                if (enrollment.Status != ScoutEnrollmentStatusEnum.Claimed)
                {
                    throw new BusinessException(enrollment.Status switch
                    {
                        ScoutEnrollmentStatusEnum.Pending => "The scout hasn't sent its device information yet.",
                        ScoutEnrollmentStatusEnum.Completed => "This scout enrollment was already used for another device.",
                        _ => "This scout enrollment was cancelled.",
                    });
                }
            }
            return enrollments;
        }

        public void AttachToDevice(ScoutEnrollment enrollment, Device device)
        {
            if (device.Scout != null)
            {
                throw new BusinessException($"Device '{device.Name}' is already enrolled as a scout.");
            }

            var scout = new Scout { CreatedAt = DateTime.UtcNow, Device = device };
            device.Scout = scout;
            enrollment.Scout = scout;
            enrollment.Status = ScoutEnrollmentStatusEnum.Completed;
        }

        private async Task<ScoutEnrollment> GetOwnedOrThrowAsync(int id, Guid userId, bool isAdmin)
        {
            EnsureAdmin(isAdmin);
            var enrollment = await _dbContext.ScoutEnrollments.FirstOrDefaultAsync(x => x.Id == id);
            if (enrollment == null || enrollment.CreatedByUserUUID != userId)
            {
                throw new NotFoundException($"Scout enrollment with id {id} was not found.");
            }
            return enrollment;
        }

        private static void EnsureAdmin(bool isAdmin)
        {
            if (!isAdmin)
            {
                throw new ForbiddenException("Only admins can enroll scouts.");
            }
        }


        private static string? Clean(string? value)
            => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
