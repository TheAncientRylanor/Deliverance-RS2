using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class OfficeUpdateValidator : AbstractValidator<OfficeUpdateRequest>
    {
        public OfficeUpdateValidator()
        {
            RuleFor(x => x.Name).OfficeName();

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
                    .Where(d => d.Id != 0)
                    .GroupBy(d => d.Id)
                    .All(g => g.Count() == 1))
                .WithMessage("The same device appears twice in this office; reload the office and try again");
        }

        private static bool HaveUniqueValues(IEnumerable<string?> values)
        {
            var nonEmpty = values.Where(v => !string.IsNullOrWhiteSpace(v)).Select(v => v!.Trim().ToLowerInvariant()).ToList();
            return nonEmpty.Distinct().Count() == nonEmpty.Count;
        }
    }
}
