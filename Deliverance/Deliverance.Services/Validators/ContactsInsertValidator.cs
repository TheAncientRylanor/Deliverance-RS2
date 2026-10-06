
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using FluentValidation;
namespace Deliverance.Services.Validators
{
    public class ContactsInsertValidator : AbstractValidator<ContactsInsertRequest>
    {
        public ContactsInsertValidator()
        {
            RuleFor(x => x.FirstName)
                .NotEmpty().WithMessage("First name is required");

                RuleFor(x => x.LastName)
                .NotEmpty().WithMessage("First name is required");
                
                RuleFor(x => x.ContactEmails)
                .NotEmpty().WithMessage("At least one email is required");

                RuleForEach(x => x.ContactEmails)
                .SetValidator(new EmailValidator());

                RuleFor(x => x.ContactPhoneNumbers)
                .NotEmpty().WithMessage("At least one phone number is required");

                RuleForEach(x => x.ContactPhoneNumbers)
                .SetValidator(new PhoneNumberValidator());

        }
        public class EmailValidator : AbstractValidator<InsertEmail>
        {
            public EmailValidator()
            {
                 RuleFor(x=>x.Email).NotEmpty().WithMessage("Email is required")
                .EmailAddress().WithMessage("Email is not in fill");
            }
        }
        public class PhoneNumberValidator : AbstractValidator<InsertPhoneNumber>
        {
            public PhoneNumberValidator()
            {
                RuleFor(x => x.PhoneNumber).NotEmpty().WithMessage("Phone number is required")
                .Matches(@"^\+?[0-9\s\-()]{6,20}$").WithMessage("Phone number is not valid");
            }
        }
    }
}
