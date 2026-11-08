using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class ReportClearValidator : AbstractValidator<ReportClearRequest>
    {
        public ReportClearValidator()
        {
            RuleFor(x => x.Comment)
                .MaximumLength(FieldRules.CommentMaxLength)
                .WithMessage($"Comment can have at most {FieldRules.CommentMaxLength} characters");

            RuleFor(x => x.IssueType)
                .IsInEnum().WithMessage("Issue type must be Hardware, Software or Both")
                .When(x => x.IssueType != null);
        }
    }
}
