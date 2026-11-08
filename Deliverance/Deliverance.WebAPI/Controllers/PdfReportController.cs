using Deliverance.Services;
using Deliverance.Services.Configuration;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers
{
    [Authorize]
    [ApiController]
    [Route("[controller]")]
    public class PdfReportController : ControllerBase
    {
        private const string PdfContentType = "application/pdf";
        private readonly IPdfReportService _service;
        private readonly DisplayTimeZone _displayTimeZone;

        public PdfReportController(IPdfReportService service, DisplayTimeZone displayTimeZone)
        {
            _service = service;
            _displayTimeZone = displayTimeZone;
        }

        [HttpGet("Activity")]
        public async Task<IActionResult> GetActivity([FromQuery] DateTime? from, [FromQuery] DateTime? to,
            [FromQuery] int? officeId)
        {
            var pdf = await _service.GetReportActivityAsync(from, to, officeId, User.IsAdmin());
            return File(pdf, PdfContentType, $"report-activity-{_displayTimeZone.Now:yyyy-MM-dd}.pdf");
        }

        [HttpGet("DeviceHealth")]
        public async Task<IActionResult> GetDeviceHealth([FromQuery] int? officeId)
        {
            var pdf = await _service.GetDeviceHealthAsync(officeId, User.IsAdmin());
            return File(pdf, PdfContentType, $"device-health-{_displayTimeZone.Now:yyyy-MM-dd}.pdf");
        }
    }
}
