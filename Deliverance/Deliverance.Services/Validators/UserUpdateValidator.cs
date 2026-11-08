using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class UserUpdateValidator : AbstractValidator<UserUpdateRequest>
    {
        public UserUpdateValidator()
        {
            RuleFor(x => x.FirstName).PersonName("First name");
            RuleFor(x => x.LastName).PersonName("Last name");
            RuleFor(x => x.Username).Username();
            RuleFor(x => x.Email).Email();
        }
    }
}
