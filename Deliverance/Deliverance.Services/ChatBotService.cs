using System.Net.Http.Json;
using System.Text;
using System.Text.Json.Serialization;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Deliverance.Services.Configuration;


namespace Deliverance.Services
{
    public class ChatBotService : BaseCRUDService<ChatBotMessage, ChatBotMessageResponse, ChatBotMessageSearchObject
        , ChatBotMessageInsertRequest, ChatBotMessageUpdateRequest>, IChatBotService
    {
        // The limits below keep the prompt small: a local model on the CPU reads
        // the whole prompt before answering, so every extra line adds waiting time.
        // How many earlier messages of the conversation are sent back to the model.
        private const int HistoryLimit = 10;
        private const int RecentReportsLimit = 3;
        private const int DevicesLimit = 30;
        // Windows event messages can be long, so a device's lines are cut before they reach the prompt.
        private const int DeviceLogsLimit = 10;
        private const int DeviceReportsLimit = 5;
        private const int DeviceLineMaxLength = 200;
        // Matches the Content column.
        private const int ContentMaxLength = 3000;
        private const int TitleMaxLength = 100;

        // Small models follow a few short, direct rules better than a long list.
        private const string Instructions = """
            You are the Deliverance helpdesk assistant. You help office workers fix
            hardware, software and network problems with their office devices.

            Rules:
            - Answer with short, numbered steps a non-technical person can follow.
            - Use the device and report information below when it is relevant.
            - Never suggest opening a device or touching wiring.
            - If the steps don't fix the problem, tell the user to submit a report in the app.
            - Only answer questions about office IT problems.
            - Answer in the same language as the user.
            - Keep answers under 200 words.
            """;

        // For an admin looking into one device from the recommendations.
        private const string DeviceInstructions = """
            You are the Deliverance assistant. You help an IT administrator understand
            the problems of the one device described below.

            Rules:
            - Explain what the logs and reports below mean, then say what to check next.
            - Only use the information below. Never make up events or results.
            - The risk comes from a prediction. It doesn't prove a fault or name its cause.
            - If the information doesn't show the cause, say so.
            - Answer in the same language as the administrator.
            - Keep answers under 200 words.
            """;

        private readonly HttpClient _httpClient;
        private readonly string _model;
        private readonly IDeviceRecommendationService _recommendationService;

        public ChatBotService(DeliveranceDbContext dbContext, IMapper mapper,
            IValidator<ChatBotMessageInsertRequest> insertValidator, IValidator<ChatBotMessageUpdateRequest> updateValidator,
            HttpClient httpClient, OllamaSettings ollamaSettings, IDeviceRecommendationService recommendationService)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {
            // Base address and timeout are set where the client is registered (Program.cs).
            _httpClient = httpClient;
            _model = ollamaSettings.Model;
            _recommendationService = recommendationService;
        }

        // Without knowing the caller is an admin, a message about a device is refused.
        public override Task<ChatBotMessageResponse> InsertAsync(ChatBotMessageInsertRequest request, Guid userId)
        {
            return InsertAsync(request, userId, isAdmin: false);
        }

        /// <summary>
        /// Saves the user's message, asks the model for a reply and returns the bot's message.
        /// Starts a new conversation when the request has no ConversationId.
        /// </summary>
        public async Task<ChatBotMessageResponse> InsertAsync(ChatBotMessageInsertRequest request, Guid userId, bool isAdmin)
        {
            var validationResult = await _insertValidator.ValidateAsync(request);
            if (validationResult.IsValid == false)
            {
                throw new ValidationException(validationResult.Errors);
            }

            Conversation conversation;
            List<ChatBotMessage> history = new();

            if (request.ConversationId.HasValue)
            {
                conversation = await _dbContext.Conversations.FindAsync(request.ConversationId.Value)
                    ?? throw new NotFoundException($"Conversation with id {request.ConversationId} not found.");
                if (conversation.UserUUID != userId)
                {
                    throw new ForbiddenException("You do not have access to this conversation.");
                }

                history = await _dbContext.ChatBotMessages
                    .AsNoTracking()
                    .Where(x => x.ConversationId == conversation.Id)
                    // Same order as GetConversationMessagesAsync.
                    .OrderByDescending(x => x.CreatedAt).ThenByDescending(x => x.Id)
                    .Take(HistoryLimit)
                    .ToListAsync();
                history.Reverse();
            }
            else
            {
                conversation = new Conversation
                {
                    UserUUID = userId,
                    Title = Truncate(request.Content.Trim(), TitleMaxLength),
                    CreatedAt = DateTime.UtcNow,
                };
                _dbContext.Conversations.Add(conversation);
            }

            // Ask the model before saving anything, so a failed call doesn't leave
            // an unanswered message in the conversation.
            var systemPrompt = request.DeviceId.HasValue
                ? await BuildDevicePromptAsync(request.DeviceId.Value, isAdmin)
                : Instructions + "\n" + await BuildContextAsync(userId);
            string reply = await AskModelAsync(systemPrompt, history, request.Content);

            var now = DateTime.UtcNow;
            _dbContext.ChatBotMessages.Add(new ChatBotMessage
            {
                Conversation = conversation,
                UserUUID = userId,
                IsFromBot = false,
                Content = request.Content,
                CreatedAt = now,
            });
            var botMessage = new ChatBotMessage
            {
                Conversation = conversation,
                UserUUID = userId,
                IsFromBot = true,
                Content = Truncate(reply, ContentMaxLength),
                // Keeps the reply ordered after the question when sorting by CreatedAt.
                CreatedAt = now.AddMilliseconds(1),
            };
            _dbContext.ChatBotMessages.Add(botMessage);

            await _dbContext.SaveChangesAsync();

            return _mapper.Map<ChatBotMessageResponse>(botMessage);
        }

        public async Task<List<ConversationResponse>> GetConversationsAsync(Guid userId)
        {
            var conversations = await _dbContext.Conversations
                .AsNoTracking()
                .Where(x => x.UserUUID == userId)
                .OrderByDescending(x => x.Id)
                .ToListAsync();

            return _mapper.Map<List<ConversationResponse>>(conversations);
        }

        /// <summary>
        /// Returns up to <paramref name="take"/> messages of one of the user's conversations,
        /// newest first. With <paramref name="beforeId"/>, returns the messages older than that one,
        /// so the app can load the history page by page while scrolling up.
        /// </summary>
        public async Task<List<ChatBotMessageResponse>> GetConversationMessagesAsync(int conversationId,
            Guid userId, int? beforeId, int take)
        {
            var conversation = await _dbContext.Conversations
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == conversationId)
                ?? throw new NotFoundException($"Conversation with id {conversationId} not found.");
            if (conversation.UserUUID != userId)
            {
                throw new ForbiddenException("You do not have access to this conversation.");
            }

            take = Math.Clamp(take, 1, 50);
            var query = _dbContext.ChatBotMessages
                .AsNoTracking()
                .Where(x => x.ConversationId == conversationId);

            if (beforeId.HasValue)
            {
                var cursor = await _dbContext.ChatBotMessages
                    .AsNoTracking()
                    .Where(x => x.Id == beforeId.Value && x.ConversationId == conversationId)
                    .Select(x => new { x.CreatedAt, x.Id })
                    .FirstOrDefaultAsync()
                    ?? throw new NotFoundException($"Message with id {beforeId} not found.");

                query = query.Where(x => x.CreatedAt < cursor.CreatedAt
                    || (x.CreatedAt == cursor.CreatedAt && x.Id < cursor.Id));
            }

            // The question and its reply are saved together, so CreatedAt orders them, not Id.
            var messages = await query
                .OrderByDescending(x => x.CreatedAt).ThenByDescending(x => x.Id)
                .Take(take)
                .ToListAsync();

            return _mapper.Map<List<ChatBotMessageResponse>>(messages);
        }

        protected override void MapUpdateRequestToEntity(ChatBotMessageUpdateRequest request, ChatBotMessage entity)
        {
            if (entity.IsFromBot == true)
            {
                throw new BusinessException("The assistant's messages can't be edited.");
            }
            base.MapUpdateRequestToEntity(request, entity);
        }

        protected override IQueryable<ChatBotMessage> ApplyFilters(IQueryable<ChatBotMessage> query, ChatBotMessageSearchObject? search, Guid userId, bool isAdmin = false)
        {
            if (!isAdmin)
            {
                query = query.Where(x => x.UserUUID == userId);
            }

            if (search != null)
            {
                if (search.ConversationId.HasValue)
                {
                    query = query.Where(x => x.ConversationId == search.ConversationId.Value);
                }
                if (search.IsFromBot.HasValue)
                {
                    query = query.Where(x => x.IsFromBot == search.IsFromBot.Value);
                }
                if (!string.IsNullOrWhiteSpace(search.Content))
                {
                    query = query.Where(x => x.Content != null && x.Content.Contains(search.Content));
                }
            }
            return query;
        }

        private async Task<string> AskModelAsync(string systemPrompt, List<ChatBotMessage> history, string content)
        {
            var messages = new List<OllamaMessage>
            {
                new("system", systemPrompt),
            };
            // Start the history at a user message, which the history limit can cut off.
            foreach (var message in history.SkipWhile(x => x.IsFromBot == true))
            {
                messages.Add(new(message.IsFromBot == true ? "assistant" : "user", message.Content ?? string.Empty));
            }
            messages.Add(new("user", content));

            var request = new OllamaChatRequest(_model, messages, false, new OllamaOptions(
                // Ollama's default context is small and it silently cuts off the start of a
                // longer prompt, which is the system prompt, so set it explicitly.
                NumCtx: 8192,
                // Caps the answer length, about 300 words.
                NumPredict: 400,
                // Lower is more focused and less creative, which suits troubleshooting steps.
                Temperature: 0.3));

            OllamaChatResponse? response;
            try
            {
                var httpResponse = await _httpClient.PostAsJsonAsync("api/chat", request);
                httpResponse.EnsureSuccessStatusCode();
                response = await httpResponse.Content.ReadFromJsonAsync<OllamaChatResponse>();
            }
            // Ollama isn't running, the model isn't pulled, or the answer took longer than the timeout.
            catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
            {
                throw new BusinessException("The assistant is currently unavailable. Please try again later.");
            }

            var reply = response?.Message?.Content?.Trim();

            if (string.IsNullOrEmpty(reply))
            {
                throw new BusinessException("The assistant could not answer this message. Try rephrasing it.");
            }
            return reply;
        }

        /// <summary>
        /// Describes the user, the offices with their devices and the user's recent reports,
        /// so the model can give answers specific to this office.
        /// </summary>
        private async Task<string> BuildContextAsync(Guid userId)
        {
            var user = await _dbContext.Users.AsNoTracking().FirstOrDefaultAsync(x => x.UUID == userId);

            var devices = await _dbContext.Devices
                .AsNoTracking()
                .OrderBy(x => x.OfficeName).ThenBy(x => x.Name)
                .Take(DevicesLimit)
                .ToListAsync();

            var reports = await _dbContext.Reports
                .AsNoTracking()
                .Where(x => x.UserUUID == userId)
                .OrderByDescending(x => x.DateReported)
                .Take(RecentReportsLimit)
                .ToListAsync();

            var context = new StringBuilder();
            context.AppendLine($"The user's name is {user?.FirstName ?? "unknown"}.");

            context.AppendLine();
            context.AppendLine("Devices in the offices:");
            if (devices.Count == 0)
            {
                context.AppendLine("- none registered");
            }
            foreach (var device in devices)
            {
                context.AppendLine($"- {device.Name} (office: {device.OfficeName}, type: {device.Type ?? "unknown"}, " +
                    $"OS: {device.OS ?? "unknown"}, manufacturer: {device.Manufacturer ?? "unknown"}, IP: {device.IpAddress ?? "unknown"})");
            }

            context.AppendLine();
            context.AppendLine("The user's most recent reports:");
            if (reports.Count == 0)
            {
                context.AppendLine("- none");
            }
            foreach (var report in reports)
            {
                context.AppendLine($"- {report.ReportName} ({report.DateReported:yyyy-MM-dd}, status: {report.Status ?? "unknown"}, " +
                    $"severity: {report.Severity?.ToString() ?? "unknown"}, issue: {report.IssueType?.ToString() ?? "unknown"}): {report.Detail}");
            }

            return context.ToString();
        }

        /// <summary>
        /// Describes one device with the same evidence the admin sees. This replaces the
        /// general context, which would only make the prompt longer and slower.
        /// </summary>
        private async Task<string> BuildDevicePromptAsync(int deviceId, bool isAdmin)
        {
            var evidence = await _recommendationService.GetDeviceEvidenceAsync(deviceId, isAdmin);
            var device = evidence.Recommendation;

            var prompt = new StringBuilder();
            prompt.AppendLine(DeviceInstructions);
            prompt.AppendLine();
            prompt.AppendLine($"Device: {device.DeviceName} (office: {device.OfficeName}).");
            prompt.AppendLine($"Prediction: {device.NeedsFixProbability:P0} risk of a problem in the next 14 days, " +
                $"most likely type: {device.LikelyIssue}.");

            prompt.AppendLine();
            prompt.AppendLine("Logs from the last 7 days, most frequent first:");
            // Counted here, because a small model can't be trusted to count lines itself.
            var logs = evidence.Logs
                .GroupBy(x => Truncate(x.Log, DeviceLineMaxLength))
                .OrderByDescending(x => x.Count())
                .Take(DeviceLogsLimit)
                .Select(x => $"{x.Key} (seen {x.Count()} times)")
                .ToList();
            if (logs.Count == 0)
            {
                prompt.AppendLine("- none");
            }
            foreach (var log in logs)
            {
                prompt.AppendLine($"- {log}");
            }

            prompt.AppendLine();
            prompt.AppendLine("Reports from the last 90 days, newest first:");
            if (evidence.Reports.Count == 0)
            {
                prompt.AppendLine("- none");
            }
            foreach (var report in evidence.Reports.Take(DeviceReportsLimit))
            {
                var comment = report.Comment == null ? "" : $" Admin comment: {Truncate(report.Comment, DeviceLineMaxLength)}";
                prompt.AppendLine($"- {report.ReportName} ({report.DateReported:yyyy-MM-dd}, status: {report.Status ?? "unknown"}, " +
                    $"severity: {report.Severity?.ToString() ?? "unknown"}, issue: {report.IssueType?.ToString() ?? "unknown"}): " +
                    $"{report.Detail}{comment}");
            }

            return prompt.ToString();
        }

        private static string Truncate(string value, int maxLength)
        {
            return value.Length <= maxLength ? value : value[..maxLength];
        }

        // Request and response shapes of Ollama's POST /api/chat.
        private record OllamaMessage(string Role, string Content);

        private record OllamaOptions(
            [property: JsonPropertyName("num_ctx")] int NumCtx,
            [property: JsonPropertyName("num_predict")] int NumPredict,
            double Temperature);

        private record OllamaChatRequest(string Model, List<OllamaMessage> Messages, bool Stream, OllamaOptions Options);

        private record OllamaChatResponse(OllamaMessage? Message);
    }
}
