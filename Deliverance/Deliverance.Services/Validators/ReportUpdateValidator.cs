using Deliverance.Model.Request;
using FluentValidation;
using System.Linq;

namespace Deliverance.Services.Validators
{
    public class ReportUpdateValidator : AbstractValidator<ReportUpdateRequest>
    {
        public ReportUpdateValidator()
        {
            RuleFor(x => x.ReportName)
                .NotEmpty().WithMessage("Report name is required")
                .When(x => !x.IsDraft);

            RuleFor(x => x.DateReported)
                .NotEmpty().WithMessage("Date reported is required")
                .When(x => !x.IsDraft);

            RuleFor(x => x.Detail)
                .NotEmpty().WithMessage("Description is required")
                .When(x => !x.IsDraft);

            RuleFor(x => x.OfficeReports)
                .NotEmpty().WithMessage("At least one location is required")
                .When(x => !x.IsDraft);

            RuleFor(x => x.ReportOccurances)
                .Must(occurances => occurances != null && occurances.Any(o => o.Answer != null))
                .WithMessage("At least one occurrence question must be answered")
                .When(x => !x.IsDraft);

            RuleForEach(x => x.OfficeReports)
                .SetValidator(new OfficeReportUpdateValidator())
                .When(x => !x.IsDraft);
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
