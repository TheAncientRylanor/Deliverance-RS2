using Deliverance.Services.Messaging;

namespace Deliverance.WebAPI.BackgroundServices
{
    public class ReportEventPublisherWorker : BackgroundService
    {
        private readonly ReportEventQueue _queue;
        private readonly RabbitMqReportEventSender _sender;
        private readonly ILogger<ReportEventPublisherWorker> _logger;

        public ReportEventPublisherWorker(ReportEventQueue queue, RabbitMqReportEventSender sender,
            ILogger<ReportEventPublisherWorker> logger)
        {
            _queue = queue;
            _sender = sender;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Report event publisher started");
            try
            {
                await foreach (var message in _queue.Reader.ReadAllAsync(stoppingToken))
                {
                    await _sender.SendWithRetryAsync(message, stoppingToken);
                }
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                var left = _queue.Reader.CanCount ? _queue.Reader.Count : 0;
                if (left > 0)
                {
                    _logger.LogWarning(
                        "Report event publisher stopped with {Count} unsent event(s); those reports' statistics update the next time they change",
                        left);
                }
            }
            catch (Exception ex)
            {
                _logger.LogCritical(ex, "Report event publisher stopped unexpectedly. Report statistics won't update until the API restarts.");
            }
        }

        public override Task StopAsync(CancellationToken cancellationToken)
        {
            _queue.Complete();
            return base.StopAsync(cancellationToken);
        }
    }
}
