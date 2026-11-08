using FluentValidation;
using FluentValidation.Results;

namespace Deliverance.Services.Validators
{
    public static class FieldRules
    {
        public const int PersonNameMaxLength = 50;
        public const int UsernameMinLength = 3;
        public const int UsernameMaxLength = 20;
        public const int EmailMaxLength = 256;
        public const int PasswordMinLength = 8;
        public const int PasswordMaxLength = 55;
        public const int OfficeNameMinLength = 2;
        public const int OfficeNameMaxLength = 20;
        public const int ReportNameMaxLength = 30;
        public const int ReportDetailMaxLength = 255;
        public const int DeviceReportDetailMaxLength = 255;
        public const int CommentMaxLength = 1000;

        public const string PhonePattern = @"^\+?[0-9\s\-()]{6,20}$";
        public const string PhoneMessage =
            "Enter a phone number of 6 to 20 characters: digits, spaces, dashes or brackets, optionally starting with + (e.g. +387 61 123 456)";
        public const string EmailMessage = "Enter a valid email address in the format name@example.com";

        public static readonly string[] Weekdays =
            { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" };

        public static IRuleBuilderOptions<T, string?> PersonName<T>(this IRuleBuilder<T, string?> rule, string label)
            => rule
                .NotEmpty().WithMessage($"{label} is required")
                .MaximumLength(PersonNameMaxLength).WithMessage($"{label} can have at most {PersonNameMaxLength} characters");

        public static IRuleBuilderOptions<T, string?> Username<T>(this IRuleBuilder<T, string?> rule)
            => rule
                .NotEmpty().WithMessage("Username is required")
                .Length(UsernameMinLength, UsernameMaxLength)
                .WithMessage($"Username must be {UsernameMinLength} to {UsernameMaxLength} characters long");

        public static IRuleBuilderOptions<T, string?> Email<T>(this IRuleBuilder<T, string?> rule)
            => rule
                .NotEmpty().WithMessage("Email is required")
                .MaximumLength(EmailMaxLength).WithMessage($"Email can have at most {EmailMaxLength} characters")
                .EmailAddress().WithMessage(EmailMessage);

        public static IRuleBuilderOptions<T, string?> Password<T>(this IRuleBuilder<T, string?> rule, string label)
            => rule
                .NotEmpty().WithMessage($"{label} is required")
                .Length(PasswordMinLength, PasswordMaxLength)
                .WithMessage($"{label} must be {PasswordMinLength} to {PasswordMaxLength} characters long");

        public static IRuleBuilderOptions<T, string?> OfficeName<T>(this IRuleBuilder<T, string?> rule)
            => rule
                .Must(name => !string.IsNullOrWhiteSpace(name)).WithMessage("Office name is required")
                .Must(name => name == null || name.Trim().Length is >= OfficeNameMinLength and <= OfficeNameMaxLength)
                .WithMessage($"Office name must be {OfficeNameMinLength} to {OfficeNameMaxLength} characters long");

        public static IRuleBuilderOptions<T, string?> Phone<T>(this IRuleBuilder<T, string?> rule)
            => rule
                .NotEmpty().WithMessage("Phone number is required")
                .Matches(PhonePattern).WithMessage(PhoneMessage);

        public static ValidationException FieldError(string propertyName, string message)
            => new(new[] { new ValidationFailure(propertyName, message) });
    }

    public class AvailabilityRules<T> : AbstractValidator<T>
    {
        public AvailabilityRules(Func<T, string> day, Func<T, TimeOnly?> from, Func<T, TimeOnly?> to,
            Func<T, TimeOnly?>? pause = null)
        {
            RuleFor(x => day(x))
                .Must(d => FieldRules.Weekdays.Contains(d))
                .WithMessage($"Day must be one of: {string.Join(", ", FieldRules.Weekdays)}")
                .OverridePropertyName("Day");
            RuleFor(x => from(x))
                .NotNull().WithMessage("Start time is required")
                .OverridePropertyName("FromTime");
            RuleFor(x => to(x))
                .NotNull().WithMessage("End time is required")
                .Must((x, end) => from(x) == null || end == null || end > from(x))
                .WithMessage("End time must be later than the start time")
                .OverridePropertyName("ToTime");
            if (pause != null)
            {
                RuleFor(x => pause(x))
                    .Must((x, p) => p == null || from(x) == null || to(x) == null || (p >= from(x) && p < to(x)))
                    .WithMessage("The break must be between the start and end time")
                    .OverridePropertyName("Pause");
            }
        }
    }

    public static class CollectionRules
    {
        public const int DayMaxLength = 10;

        public static IRuleBuilderOptionsConditions<T, IEnumerable<TItem>?> NoOverlappingSlots<T, TItem>(
            this IRuleBuilder<T, IEnumerable<TItem>?> rule,
            Func<TItem, string> day, Func<TItem, TimeOnly?> from, Func<TItem, TimeOnly?> to)
            => rule.Custom((items, context) =>
            {
                if (items == null) return;
                var slots = items
                    .Select((item, index) => (Index: index, Day: day(item), From: from(item), To: to(item)))
                    .Where(s => s.From != null && s.To != null && s.To > s.From)
                    .OrderBy(s => s.Day).ThenBy(s => s.From)
                    .ToList();

                for (var i = 1; i < slots.Count; i++)
                {
                    var previous = slots[i - 1];
                    var current = slots[i];
                    if (current.Day == previous.Day && current.From < previous.To)
                    {
                        context.AddFailure(new ValidationFailure($"{context.PropertyPath}[{current.Index}].FromTime",
                            $"{current.Day} {current.From:HH\\:mm}-{current.To:HH\\:mm} overlaps {previous.From:HH\\:mm}-{previous.To:HH\\:mm}. " +
                            "Times on the same day can't overlap."));
                    }
                }
            });

        public static IRuleBuilderOptions<T, IEnumerable<TItem>?> Distinct<T, TItem, TKey>(
            this IRuleBuilder<T, IEnumerable<TItem>?> rule, Func<TItem, TKey> key, string message)
            => rule
                .Must(items => items == null || items.GroupBy(key).All(g => g.Count() == 1))
                .WithMessage(message);
    }
}
