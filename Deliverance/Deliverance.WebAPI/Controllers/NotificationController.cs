using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers
{
    public class NotificationController : BaseReadController<NotificationResponse, NotificationSearchObject, INotificationService>
    {
        public NotificationController(INotificationService notificationService) : base(notificationService)
        {
        }

        [HttpGet("UnreadCount")]
        public Task<int> UnreadCount()
        {
            return _service.GetUnreadCountAsync(User.GetUserId());
        }

        [HttpPut("Read/{id}")]
        public async Task<ActionResult<NotificationResponse>> Read(int id)
        {
            return await _service.MarkAsReadAsync(id, User.GetUserId());
        }

        [HttpPut("ReadAll")]
        public async Task<IActionResult> ReadAll()
        {
            await _service.MarkAllAsReadAsync(User.GetUserId());
            return NoContent();
        }
    }
}
