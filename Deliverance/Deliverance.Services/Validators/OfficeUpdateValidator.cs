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
                .Must(devices => devices == null || devices
                    .Select(d => d.Id)
                    .Distinct()
                    .Count() == devices.Count)
                .WithMessage("Duplicate device ids are not allowed within an office");
        }

        private static bool HaveUniqueValues(IEnumerable<string?> values)
        {
            var nonEmpty = values.Where(v => !string.IsNullOrWhiteSpace(v)).Select(v => v!.Trim().ToLowerInvariant()).ToList();
            return nonEmpty.Distinct().Count() == nonEmpty.Count;
        }
    }
}
