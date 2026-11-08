using Deliverance.Model.Enums;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;

namespace Deliverance.Services
{
    public interface INotificationService :
        IBaseReadService<NotificationResponse, NotificationSearchObject>
    {
        Task<int> GetUnreadCountAsync(Guid userId);
        Task<NotificationResponse> MarkAsReadAsync(int id, Guid userId);
        Task MarkAllAsReadAsync(Guid userId);

        Task<IReadOnlyList<Notification>> AddForUserAsync(Guid userId, NotificationTypeEnum type, string title, string text,
            int? reportId = null);

        Task<IReadOnlyList<Notification>> AddForAdminsAsync(NotificationTypeEnum type, string title, string text,
            int? reportId = null, Guid? exceptUserId = null, Guid? relatedUserUUID = null);

        Task PushAsync(IReadOnlyList<Notification> notifications);
    }
}
