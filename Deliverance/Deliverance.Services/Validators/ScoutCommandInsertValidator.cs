using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class ScoutCommandInsertValidator : AbstractValidator<ScoutCommandInsertRequest>
    {
        // Matches the CommandText column.
        public const int CommandTextMaxLength = 4000;

        public ScoutCommandInsertValidator()
        {
            RuleFor(x => x.DeviceId)
                .GreaterThan(0).WithMessage("Device is required");

            RuleFor(x => x.ExecutionCommandId)
                .IsInEnum().WithMessage("Execution mode must be CMD or PowerShell");

            RuleFor(x => x.CommandText)
                .Must(text => !string.IsNullOrWhiteSpace(text)).WithMessage("Command is required")
                .MaximumLength(CommandTextMaxLength).WithMessage($"Command cannot exceed {CommandTextMaxLength} characters");
        }
    }
}
