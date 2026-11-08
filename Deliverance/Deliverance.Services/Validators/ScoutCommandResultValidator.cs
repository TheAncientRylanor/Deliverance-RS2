using Deliverance.Model.Enums;
using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class ScoutCommandResultValidator : AbstractValidator<ScoutCommandResultRequest>
    {
        public const int OutputMaxLength = 100_000;

        public ScoutCommandResultValidator()
        {
            RuleFor(x => x.Status)
                .Must(status => status is ScoutCommandStatusEnum.Running
                    or ScoutCommandStatusEnum.Completed
                    or ScoutCommandStatusEnum.Failed
                    or ScoutCommandStatusEnum.TimedOut)
                .WithMessage("Status must be Running, Completed, Failed or TimedOut");

            RuleFor(x => x.Output)
                .MaximumLength(OutputMaxLength).WithMessage($"Output cannot exceed {OutputMaxLength} characters");

            RuleFor(x => x.ExitCode)
                .NotNull().WithMessage("Exit code is required for a completed command")
                .When(x => x.Status == ScoutCommandStatusEnum.Completed);
        }
    }
}
