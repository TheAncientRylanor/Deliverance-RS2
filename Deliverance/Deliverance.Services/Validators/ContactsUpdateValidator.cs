using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class ContactsUpdateValidator : AbstractValidator<ContactsUpdateRequest>
    {
        public ContactsUpdateValidator()
        {
            RuleFor(x => x.FirstName).PersonName("First name");
            RuleFor(x => x.LastName).PersonName("Last name");

            RuleFor(x => x.ContactEmails)
                .NotEmpty().WithMessage("Add at least one email address");
            RuleForEach(x => x.ContactEmails).ChildRules(email =>
                email.RuleFor(x => x.Email).Email());

            RuleFor(x => x.ContactPhoneNumbers)
                .NotEmpty().WithMessage("Add at least one phone number");
            RuleForEach(x => x.ContactPhoneNumbers).ChildRules(phone =>
                phone.RuleFor(x => x.PhoneNumber).Phone());

            RuleForEach(x => x.Availabilities)
                .SetValidator(new AvailabilityRules<AvailabilityUpdateRequest>(a => a.Day, a => a.FromTime, a => a.ToTime, a => a.Pause));
            RuleFor(x => x.Availabilities)
                .NoOverlappingSlots(a => a.Day, a => a.FromTime, a => a.ToTime);

            RuleFor(x => x.ContactEmails)
                .Distinct(e => e.Email.Trim().ToLowerInvariant(), "The same email address is listed twice");
            RuleFor(x => x.ContactPhoneNumbers)
                .Distinct(p => p.PhoneNumber.Trim(), "The same phone number is listed twice");
        }
    }
}
