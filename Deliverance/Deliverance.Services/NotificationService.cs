using Deliverance.Model.Enums;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using Deliverance.Services.Messaging;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Deliverance.Services
{
    public class NotificationService : BaseReadService<Notification, NotificationResponse, NotificationSearchObject>, INotificationService
    {
        private readonly INotificationNotifier _notifier;
        private readonly ILogger<NotificationService> _logger;

        public NotificationService(IMapper mapper, DeliveranceDbContext dbContext,
            INotificationNotifier notifier, ILogger<NotificationService> logger)
            : base(mapper, dbContext)
        {
            _notifier = notifier;
            _logger = logger;
        }

        protected override IQueryable<Notification> ApplyFilters(IQueryable<Notification> query,
            NotificationSearchObject? search, Guid userId = default, bool isAdmin = false)
        {
            query = query.Where(x => x.UserUUID == userId);

            if (search?.IsRead != null)
            {
                query = query.Where(x => x.IsRead == search.IsRead);
            }

            return query;
        }

        public override Task<PageResult<NotificationResponse>> GetAllAsync(NotificationSearchObject? search = null,
            Guid userId = default, bool isAdmin = false)
        {
            search ??= new NotificationSearchObject();

            if (string.IsNullOrWhiteSpace(search.SortBy))
            {
                search.SortBy = nameof(Notification.CreatedAt);
                search.Descending = true;
            }

            return base.GetAllAsync(search, userId, isAdmin);
        }

        public override Task<NotificationResponse> GetByIdAsync(int id, Guid userId, bool isAdmin = false)
            => base.GetByIdAsync(id, userId, isAdmin: false);

        public Task<int> GetUnreadCountAsync(Guid userId)
            => _dbContext.Notifications.CountAsync(x => x.UserUUID == userId && !x.IsRead);

        public async Task<NotificationResponse> MarkAsReadAsync(int id, Guid userId)
        {
            var entity = await _dbContext.Notifications.FirstOrDefaultAsync(x => x.Id == id && x.UserUUID == userId)
                ?? throw new NotFoundException($"Notification with id {id} was not found.");

            entity.IsRead = true;
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<NotificationResponse>(entity);
        }

        public Task MarkAllAsReadAsync(Guid userId)
            => _dbContext.Notifications
                .Where(x => x.UserUUID == userId && !x.IsRead)
                .ExecuteUpdateAsync(setters => setters.SetProperty(x => x.IsRead, true));

        public Task<IReadOnlyList<Notification>> AddForUserAsync(Guid userId, NotificationTypeEnum type, string title,
            string text, int? reportId = null)
            => AddAsync(_dbContext.Users.Where(x => x.UUID == userId), type, title, text, reportId);

        public Task<IReadOnlyList<Notification>> AddForAdminsAsync(NotificationTypeEnum type, string title, string text,
            int? reportId = null, Guid? exceptUserId = null, Guid? relatedUserUUID = null)
            => AddAsync(_dbContext.Users.Where(x => x.RoleId == RoleEnum.Admin && x.UUID != exceptUserId),
                type, title, text, reportId, relatedUserUUID);

        private async Task<IReadOnlyList<Notification>> AddAsync(IQueryable<User> recipients, NotificationTypeEnum type,
            string title, string text, int? reportId, Guid? relatedUserUUID = null)
        {
            var userIds = await recipients.Select(x => x.UUID).ToListAsync();
            var now = DateTime.UtcNow;
            var notifications = userIds
                .Select(userId => new Notification
                {
                    UserUUID = userId,
                    Type = type,
                    Title = title,
                    Text = text,
                    CreatedAt = now,
                    ReportId = reportId,
                    RelatedUserUUID = relatedUserUUID,
                })
                .ToList();

            _dbContext.Notifications.AddRange(notifications);
            return notifications;
        }

        public async Task PushAsync(IReadOnlyList<Notification> notifications)
        {
            foreach (var notification in notifications)
            {
                try
                {
                    await _notifier.NotificationCreatedAsync(notification.UserUUID,
                        _mapper.Map<NotificationResponse>(notification));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Could not push {Type} notification {NotificationId} to user {UserId}",
                        notification.Type, notification.Id, notification.UserUUID);
                }
            }
        }
    }
}
