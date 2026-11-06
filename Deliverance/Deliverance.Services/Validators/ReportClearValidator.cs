using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class ReportClearValidator : AbstractValidator<ReportClearRequest>
    {
        public ReportClearValidator()
        {
            RuleFor(x => x.Comment)
                .MaximumLength(1000).WithMessage("Comment can't be longer than 1000 characters");

            RuleFor(x => x.IssueType)
                .IsInEnum().WithMessage("Unknown issue type")
                .When(x => x.IssueType != null);
        }
    }
}
