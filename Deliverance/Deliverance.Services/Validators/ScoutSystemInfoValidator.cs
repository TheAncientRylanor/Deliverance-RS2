using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators;

public class ScoutSystemInfoValidator : AbstractValidator<ScoutSystemInfoRequest>
{
    private static readonly DateTime EarliestOsUpdate = new(2000, 1, 1, 0, 0, 0, DateTimeKind.Utc);

    public ScoutSystemInfoValidator()
    {
        RuleFor(x => x.OS)
            .MaximumLength(50).WithMessage("OS cannot exceed 50 characters");

        RuleFor(x => x.LastOsUpdate)
            .Must(date => date == null
                || (date.Value.AsUtc() >= EarliestOsUpdate && date.Value.AsUtc() <= DateTime.UtcNow.AddDays(1)))
            .WithMessage("Last OS update must be a date between 2000 and today");
    }
}
