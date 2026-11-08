using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class ScoutLogBatchValidator : AbstractValidator<ScoutLogBatchRequest>
    {
        public const int MaxBatchSize = 100;
        public const int MessageMaxLength = 4000;

        public ScoutLogBatchValidator()
        {
            RuleFor(x => x.Logs)
                .NotEmpty().WithMessage("Logs are required")
                .Must(logs => logs.Count <= MaxBatchSize)
                .WithMessage($"A batch cannot have more than {MaxBatchSize} logs");

            RuleForEach(x => x.Logs).ChildRules(log =>
            {
                log.RuleFor(x => x.EventKey)
                    .NotEmpty().WithMessage("Event key is required")
                    .MaximumLength(100).WithMessage("Event key cannot exceed 100 characters");

                log.RuleFor(x => x.DateLogged)
                    .NotEmpty().WithMessage("Date is required");

                log.RuleFor(x => x.Source)
                    .NotEmpty().WithMessage("Source is required")
                    .MaximumLength(100).WithMessage("Source cannot exceed 100 characters");

                log.RuleFor(x => x.Count)
                    .GreaterThan(0).WithMessage("Count must be at least 1");

                log.RuleFor(x => x.Message)
                    .NotEmpty().WithMessage("Message is required")
                    .MaximumLength(MessageMaxLength).WithMessage($"Message cannot exceed {MessageMaxLength} characters");
            });
        }
    }
}
