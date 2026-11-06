using Deliverance.Model.Enums;
using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class ScoutCommandResultValidator : AbstractValidator<ScoutCommandResultRequest>
    {
        // The column is nvarchar(max), so this is the only cap. The scout should
        // truncate longer output itself rather than have the whole result rejected.
        public const int OutputMaxLength = 100_000;

        public ScoutCommandResultValidator()
        {
            // Running marks that the scout picked the command up; the others end it.
            // Pending is set by the server only.
            RuleFor(x => x.Status)
                .Must(status => status is ScoutCommandStatusEnum.Running
                    or ScoutCommandStatusEnum.Completed
                    or ScoutCommandStatusEnum.Failed
                    or ScoutCommandStatusEnum.TimedOut)
                .WithMessage("Status must be Running, Completed, Failed or TimedOut");

            RuleFor(x => x.Output)
                .MaximumLength(OutputMaxLength).WithMessage($"Output cannot exceed {OutputMaxLength} characters");

            // Only a process that ran to the end has an exit code.
            RuleFor(x => x.ExitCode)
                .NotNull().WithMessage("Exit code is required for a completed command")
                .When(x => x.Status == ScoutCommandStatusEnum.Completed);
        }
    }
}
