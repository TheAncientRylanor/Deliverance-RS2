using Deliverance.Model.Request;
using FluentValidation;


namespace Deliverance.Services.Validators
{
    public class UserInsertValidator : AbstractValidator<UserInsertRequest>
    {
        public UserInsertValidator()
        {
            RuleFor(x => x.FirstName)
                .NotEmpty().WithMessage("Name is required");
            RuleFor(x => x.Password)
                .NotEmpty().WithMessage("Password is required")
                .MinimumLength(8).WithMessage("Password must be at least 8 characters long")
                .MaximumLength(55).WithMessage("Password cannot exceed 50 characters");

            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email is required")
                .EmailAddress().WithMessage("A valid email is required");

            RuleFor(x => x.Username)
                .NotEmpty().WithMessage("Username is required")
                .MinimumLength(3).WithMessage("Username has to have at least 3 characters in it")
                .MaximumLength(20).WithMessage("Username cannot exceed 20 characters");
        }
    }
}
