using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class UserUpdateValidator : AbstractValidator<UserUpdateRequest>
    {
        public UserUpdateValidator()
        {
           
            RuleFor(x => x.FirstName)
                .NotEmpty().WithMessage("First name is required.")
                .MaximumLength(50).WithMessage("First name cannot exceed 50 characters.");
            RuleFor(x => x.LastName)
                .NotEmpty().WithMessage("Last name is required.")
                .MaximumLength(50).WithMessage("First name cannot exceed 50 characters.");
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email  is required.")
                .EmailAddress().WithMessage("First name cannot exceed 50 characters.");
            RuleFor(x => x.Username)
                .NotEmpty().WithMessage("Last name is required.")
                .MaximumLength(50).WithMessage("First name cannot exceed 50 characters.");
        }
    }
}