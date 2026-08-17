using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class ReportInsertValidator : AbstractValidator<ReportInsertRequest>
    {
        public ReportInsertValidator()
        {
            RuleFor(x => x.ReportName)
                .NotEmpty().WithMessage("Report name is required");

            RuleFor(x => x.DateReported)
                .NotEmpty().WithMessage("Date reported is required");

            RuleForEach(x => x.OfficeReports)
                .SetValidator(new OfficeReportInsertValidator());
        }

        public class OfficeReportInsertValidator : AbstractValidator<OfficeReportInsertRequest>
        {
            public OfficeReportInsertValidator()
            {
                RuleFor(x => x.OfficeId)
                    .GreaterThan(0).WithMessage("Office is required");

                RuleForEach(x => x.DeviceReports)
                    .SetValidator(new DeviceReportInsertValidator());
            }
        }

        public class DeviceReportInsertValidator : AbstractValidator<DeviceReportInsertRequest>
        {
            public DeviceReportInsertValidator()
            {
                RuleFor(x => x.DeviceId)
                    .GreaterThan(0).WithMessage("Device is required");
            }
        }
    }
}
