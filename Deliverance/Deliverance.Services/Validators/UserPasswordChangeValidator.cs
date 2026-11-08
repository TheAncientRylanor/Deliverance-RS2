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
                .Password("New password")
                .NotEqual(x => x.OldPassword).WithMessage("New password must be different from the current password");
        }
    }
}
