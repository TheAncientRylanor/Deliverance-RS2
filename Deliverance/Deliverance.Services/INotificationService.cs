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

        /// <summary>
        /// Adds a notification for one user to the shared DbContext without saving. The caller
        /// saves it together with the change it is about, then calls <see cref="PushAsync"/>.
        /// </summary>
        Task<IReadOnlyList<Notification>> AddForUserAsync(Guid userId, NotificationTypeEnum type, string title, string text,
            int? reportId = null);

        /// <summary>
        /// Like <see cref="AddForUserAsync"/>, for every admin. <paramref name="exceptUserId"/> skips the
        /// admin who caused the event.
        /// </summary>
        Task<IReadOnlyList<Notification>> AddForAdminsAsync(NotificationTypeEnum type, string title, string text,
            int? reportId = null, Guid? exceptUserId = null, Guid? relatedUserUUID = null);

        /// <summary>
        /// Sends saved notifications to their users over SignalR. Call it only after the save succeeded.
        /// Never throws: the change is already saved, and the user still sees it on the next load.
        /// </summary>
        Task PushAsync(IReadOnlyList<Notification> notifications);
    }
}
