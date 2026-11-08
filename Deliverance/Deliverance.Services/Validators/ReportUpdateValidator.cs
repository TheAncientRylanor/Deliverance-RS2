using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class ReportUpdateValidator : AbstractValidator<ReportUpdateRequest>
    {
        public ReportUpdateValidator()
        {
            RuleFor(x => x.ReportName)
                .NotEmpty().WithMessage("Report title is required")
                .When(x => !x.IsDraft);
            RuleFor(x => x.ReportName)
                .MaximumLength(FieldRules.ReportNameMaxLength)
                .WithMessage($"Report title can have at most {FieldRules.ReportNameMaxLength} characters");

            RuleFor(x => x.DateReported)
                .NotEmpty().WithMessage("Date and time of the problem are required")
                .When(x => !x.IsDraft);
            RuleFor(x => x.DateReported)
                .Must(date => date.AsUtc() <= DateTime.UtcNow.AddMinutes(5))
                .WithMessage("Date and time of the problem can't be in the future")
                .When(x => x.DateReported != default);

            RuleFor(x => x.Detail)
                .NotEmpty().WithMessage("Description is required")
                .When(x => !x.IsDraft);
            RuleFor(x => x.Detail)
                .MaximumLength(FieldRules.ReportDetailMaxLength)
                .WithMessage($"Description can have at most {FieldRules.ReportDetailMaxLength} characters");

            RuleFor(x => x.Severity)
                .IsInEnum().WithMessage("Severity must be between 1 (None) and 5 (Extreme)")
                .When(x => x.Severity != null);
            RuleFor(x => x.IssueType)
                .IsInEnum().WithMessage("Issue type must be Hardware, Software or Both")
                .When(x => x.IssueType != null);

            RuleFor(x => x.OfficeReports)
                .NotEmpty().WithMessage("Select at least one office and device")
                .When(x => !x.IsDraft);

            RuleFor(x => x.ReportOccurrences)
                .Must(occurrences => occurrences != null && occurrences.Any(o => o.Answer != null))
                .WithMessage("Answer at least one of the occurrence questions")
                .When(x => !x.IsDraft);

            RuleFor(x => x.OfficeReports)
                .Distinct(o => o.OfficeId, "Each office can be in a report only once");
            RuleFor(x => x.ReportOccurrences)
                .Distinct(o => o.OccurrenceId, "Each occurrence question can be answered only once");

            RuleForEach(x => x.OfficeReports).ChildRules(office =>
            {
                office.RuleFor(x => x.DeviceReports)
                    .Distinct(d => d.DeviceId, "Each device can be listed only once per office");
                office.RuleFor(x => x.OfficeId)
                    .GreaterThan(0).WithMessage("Select an office");
                office.RuleForEach(x => x.DeviceReports).ChildRules(device =>
                {
                    device.RuleFor(x => x.DeviceId)
                        .GreaterThan(0).WithMessage("Select a device");
                    device.RuleFor(x => x.Detail)
                        .MaximumLength(FieldRules.DeviceReportDetailMaxLength)
                        .WithMessage($"Device description can have at most {FieldRules.DeviceReportDetailMaxLength} characters");
                });
            });
        }
    }
}
