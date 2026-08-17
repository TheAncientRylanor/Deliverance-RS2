using System.Net;
using System.Text.RegularExpressions;
using Deliverance.Model.Request;
using FluentValidation;
namespace Deliverance.Services.Validators
{
    public class DeviceInsertValidator : AbstractValidator<DeviceInsertRequest>
    {
        private static readonly Regex IpAddressRegex = new(
            @"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$",
            RegexOptions.Compiled);

        private static readonly Regex MacAddressRegex = new(
            @"^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$",
            RegexOptions.Compiled);

        public DeviceInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Name is required")
                .MaximumLength(50).WithMessage("Name cannot exceed 50 characters")
                .MinimumLength(2).WithMessage("Name must have at least 2 characters");

            RuleFor(x => x.Type)
                .NotEmpty().WithMessage("Type is required")
                .MaximumLength(50).WithMessage("Type cannot exceed 50 characters");

            RuleFor(x => x.IconName)
                .NotEmpty().WithMessage("Icon name is required")
                .MaximumLength(50).WithMessage("Icon name cannot exceed 50 characters");

            RuleFor(x => x.IpAddress)
                .Must(ip => string.IsNullOrEmpty(ip) || IpAddressRegex.IsMatch(ip))
                .WithMessage("IP address must be a valid IPv4 address (e.g. 192.168.1.1)");

            RuleFor(x => x.MacAddress)
                .Must(mac => string.IsNullOrEmpty(mac) || MacAddressRegex.IsMatch(mac))
                .WithMessage("MAC address must be in a valid format (e.g. 00:1A:2B:3C:4D:5E)");

            RuleFor(x => x.SubnetMask)
                .Must(mask => string.IsNullOrEmpty(mask) || IpAddressRegex.IsMatch(mask))
                .WithMessage("Subnet mask must be a valid IPv4-formatted mask (e.g. 255.255.255.0)")
                .Must(mask => string.IsNullOrEmpty(mask) || !IpAddressRegex.IsMatch(mask) || BeAContiguousSubnetMask(mask))
                .WithMessage("Subnet mask must consist of contiguous bits (e.g. 255.255.255.0)");

            RuleFor(x => x.VlanID)
                .Must(vlan => string.IsNullOrEmpty(vlan) || (int.TryParse(vlan, out var id) && id is >= 1 and <= 4094))
                .WithMessage("VLAN ID must be a number between 1 and 4094");

            RuleFor(x => x.PositionX)
                .GreaterThanOrEqualTo(0).WithMessage("Position X cannot be negative");

            RuleFor(x => x.PositionY)
                .GreaterThanOrEqualTo(0).WithMessage("Position Y cannot be negative");

            RuleFor(x => x.OS)
                .MaximumLength(50).WithMessage("OS cannot exceed 50 characters");

            RuleFor(x => x.Manufacturer)
                .MaximumLength(50).WithMessage("Manufacturer cannot exceed 50 characters");
        }

        private static bool BeAContiguousSubnetMask(string mask)
        {
            if (!IPAddress.TryParse(mask, out var ip))
                return false;

            var bytes = ip.GetAddressBytes();
            uint value = ((uint)bytes[0] << 24) | ((uint)bytes[1] << 16) | ((uint)bytes[2] << 8) | bytes[3];
            uint inverted = ~value;
            return (inverted & (inverted + 1)) == 0;
        }
    }
}
