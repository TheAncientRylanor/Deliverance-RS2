using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class ChatBotMessageUpdateValidator : AbstractValidator<ChatBotMessageUpdateRequest>
    {
        public ChatBotMessageUpdateValidator()
        {
            RuleFor(x => x.Content)
                .Must(text => !string.IsNullOrWhiteSpace(text)).WithMessage("Message is required")
                .MaximumLength(ChatBotMessageInsertValidator.ContentMaxLength)
                .WithMessage($"Message cannot exceed {ChatBotMessageInsertValidator.ContentMaxLength} characters");
        }
    }
}
