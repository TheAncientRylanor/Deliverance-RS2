using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using FluentValidation;
namespace Deliverance.Services.Validators
{
    public class ContactsUpdateValidator : AbstractValidator<ContactsUpdateRequest>
    {
        public ContactsUpdateValidator()
        {
            RuleFor(x => x.FirstName)
                .NotEmpty().WithMessage("First name is required");

                RuleFor(x => x.LastName)
                .NotEmpty().WithMessage("First name is required");
            RuleForEach(x => x.ContactEmails).SetValidator(new EmailValidator());
            
        
        }
    }
      public class EmailValidator : AbstractValidator<UpdateEmail>
        {
            public EmailValidator()
            {
                 RuleFor(x=>x.Email).NotEmpty().WithMessage("Email is required")
                .EmailAddress().WithMessage("Email is not in fill");
            }
        }
}
