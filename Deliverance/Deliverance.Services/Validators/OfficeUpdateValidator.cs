using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class OfficeUpdateValidator : AbstractValidator<OfficeUpdateRequest>
    {
        public OfficeUpdateValidator()
        {
            RuleFor(x=>x.Name)
            .NotEmpty().WithMessage("Office name is required")
            .MinimumLength(3).WithMessage("Office name must be at least 3 characters long")
            .MaximumLength(20).WithMessage("Office name cannot be longer more than 20 characters");

            RuleForEach(x => x.Devices)
                .SetValidator(new DeviceUpdateValidator());

            RuleFor(x => x.Devices)
                .Must(devices => devices == null || devices
                    .Select(d => d.Name.Trim().ToLowerInvariant())
                    .Distinct()
                    .Count() == devices.Count)
                .WithMessage("Device names must be unique within an office");

            RuleFor(x => x.Devices)
                .Must(devices => devices == null || HaveUniqueValues(devices.Select(d => d.IpAddress)))
                .WithMessage("Device IP addresses must be unique within an office");

            RuleFor(x => x.Devices)
                .Must(devices => devices == null || HaveUniqueValues(devices.Select(d => d.MacAddress)))
                .WithMessage("Device MAC addresses must be unique within an office");

            RuleFor(x => x.Devices)
                // New devices are sent with Id 0, so only existing ids must be unique.
                .Must(devices => devices == null || devices
                    .Where(d => d.Id != 0)
                    .GroupBy(d => d.Id)
                    .All(g => g.Count() == 1))
                .WithMessage("Duplicate device ids are not allowed within an office");
        }

        private static bool HaveUniqueValues(IEnumerable<string?> values)
        {
            var nonEmpty = values.Where(v => !string.IsNullOrWhiteSpace(v)).Select(v => v!.Trim().ToLowerInvariant()).ToList();
            return nonEmpty.Distinct().Count() == nonEmpty.Count;
        }
    }
}
