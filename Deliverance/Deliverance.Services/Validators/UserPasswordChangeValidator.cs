using Deliverance.Model.Request;
using FluentValidation;


namespace Deliverance.Services.Validators
{
    public class UserPasswordChangeValidator : AbstractValidator<UserPasswordChangeRequest>
    {
        public UserPasswordChangeValidator()
        {
            RuleFor(x => x.OldPassword)
                .NotEmpty().WithMessage("Current password is required");

            RuleFor(x => x.NewPassword)
                .NotEmpty().WithMessage("New password is required")
                .MinimumLength(8).WithMessage("Password must be at least 8 characters long")
                .MaximumLength(55).WithMessage("Password cannot exceed 55 characters")
                .NotEqual(x => x.OldPassword).WithMessage("Password can't be the same as the previous password");
        }
    }
}
