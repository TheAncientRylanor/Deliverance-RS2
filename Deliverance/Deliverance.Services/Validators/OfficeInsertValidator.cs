using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class OfficeInsertValidator : AbstractValidator<OfficeInsertRequest>
    {
        public OfficeInsertValidator()
        {
            RuleFor(x => x.Name).OfficeName();

            RuleForEach(x => x.Devices)
                .SetValidator(new DeviceInsertValidator());

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
        }

        private static bool HaveUniqueValues(IEnumerable<string?> values)
        {
            var nonEmpty = values.Where(v => !string.IsNullOrWhiteSpace(v)).Select(v => v!.Trim().ToLowerInvariant()).ToList();
            return nonEmpty.Distinct().Count() == nonEmpty.Count;
        }
    }
}
