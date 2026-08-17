using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class ReportUpdateValidator : AbstractValidator<ReportUpdateRequest>
    {
        public ReportUpdateValidator()
        {
            RuleFor(x => x.ReportName)
                .NotEmpty().WithMessage("Report name is required");

            RuleFor(x => x.DateReported)
                .NotEmpty().WithMessage("Date reported is required");

            RuleForEach(x => x.OfficeReports)
                .SetValidator(new OfficeReportUpdateValidator());
        }

        public class OfficeReportUpdateValidator : AbstractValidator<OfficeReportUpdateRequest>
        {
            public OfficeReportUpdateValidator()
            {
                RuleFor(x => x.OfficeId)
                    .GreaterThan(0).WithMessage("Office is required");

                RuleForEach(x => x.DeviceReports)
                    .SetValidator(new DeviceReportUpdateValidator());
            }
        }

        public class DeviceReportUpdateValidator : AbstractValidator<DeviceReportUpdateRequest>
        {
            public DeviceReportUpdateValidator()
            {
                RuleFor(x => x.DeviceId)
                    .GreaterThan(0).WithMessage("Device is required");
            }
        }
    }
}
