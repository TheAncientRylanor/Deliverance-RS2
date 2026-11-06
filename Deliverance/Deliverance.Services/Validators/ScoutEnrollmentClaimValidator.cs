using System.Text.RegularExpressions;
using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    // Same formats and limits as the device validators, so whatever a scout reports
    // can be saved on the device later without failing validation there.
    public class ScoutEnrollmentClaimValidator : AbstractValidator<ScoutEnrollmentClaimRequest>
    {
        private static readonly Regex IpAddressRegex = new(
            @"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$",
            RegexOptions.Compiled);

        private static readonly Regex MacAddressRegex = new(
            @"^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$",
            RegexOptions.Compiled);

        public ScoutEnrollmentClaimValidator()
        {
            RuleFor(x => x.Token)
                .NotEmpty().WithMessage("Enrollment token is required")
                .MaximumLength(100).WithMessage("Enrollment token is invalid");

            RuleFor(x => x.IpAddress)
                .Must(ip => string.IsNullOrEmpty(ip) || IpAddressRegex.IsMatch(ip))
                .WithMessage("IP address must be a valid IPv4 address (e.g. 192.168.1.1)");

            RuleFor(x => x.MacAddress)
                .Must(mac => string.IsNullOrEmpty(mac) || MacAddressRegex.IsMatch(mac))
                .WithMessage("MAC address must be in a valid format (e.g. 00:1A:2B:3C:4D:5E)");

            RuleFor(x => x.SubnetMask)
                .Must(mask => string.IsNullOrEmpty(mask) || IpAddressRegex.IsMatch(mask))
                .WithMessage("Subnet mask must be a valid IPv4-formatted mask (e.g. 255.255.255.0)");

            RuleFor(x => x.VlanID)
                .Must(vlan => string.IsNullOrEmpty(vlan) || (int.TryParse(vlan, out var id) && id is >= 1 and <= 4094))
                .WithMessage("VLAN ID must be a number between 1 and 4094");

            RuleFor(x => x.OS)
                .MaximumLength(50).WithMessage("OS cannot exceed 50 characters");

            RuleFor(x => x.Manufacturer)
                .MaximumLength(50).WithMessage("Manufacturer cannot exceed 50 characters");

            RuleFor(x => x.Hostname)
                .MaximumLength(100).WithMessage("Hostname cannot exceed 100 characters");
        }
    }
}
