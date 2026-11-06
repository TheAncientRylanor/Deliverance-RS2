using Deliverance.Model.Request;
using FluentValidation;

namespace Deliverance.Services.Validators
{
    public class ChatBotMessageInsertValidator : AbstractValidator<ChatBotMessageInsertRequest>
    {
        // Kept well under the 3000-character Content column so bot replies have room
        // and a single message can't blow up the prompt sent to the model.
        public const int ContentMaxLength = 1000;

        public ChatBotMessageInsertValidator()
        {
            RuleFor(x => x.ConversationId)
                .GreaterThan(0).When(x => x.ConversationId.HasValue)
                .WithMessage("Conversation is not valid");

            RuleFor(x => x.DeviceId)
                .GreaterThan(0).When(x => x.DeviceId.HasValue)
                .WithMessage("Device is not valid");

            RuleFor(x => x.Content)
                .Must(text => !string.IsNullOrWhiteSpace(text)).WithMessage("Message is required")
                .MaximumLength(ContentMaxLength).WithMessage($"Message cannot exceed {ContentMaxLength} characters");
        }
    }
}
