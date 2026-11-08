using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class ChatBotMessageInsertValidator : AbstractValidator<ChatBotMessageInsertRequest>
    {
        public const int ContentMaxLength = 1000;

        public ChatBotMessageInsertValidator()
        {
            RuleFor(x => x.ConversationId)
                .GreaterThan(0).When(x => x.ConversationId.HasValue)
                .WithMessage("Conversation id must be a positive number");

            RuleFor(x => x.DeviceId)
                .GreaterThan(0).When(x => x.DeviceId.HasValue)
                .WithMessage("Device id must be a positive number");

            RuleFor(x => x.Content)
                .Must(text => !string.IsNullOrWhiteSpace(text)).WithMessage("Message is required")
                .MaximumLength(ContentMaxLength).WithMessage($"Message can have at most {ContentMaxLength} characters");
        }
    }
}
