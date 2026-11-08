namespace Deliverance.Services.Messaging
{
    /// <summary>
    /// The retry schedule for RabbitMQ work: after the first attempt, wait 1s, 2s, 4s and 8s.
    /// </summary>
    public static class RetryBackoff
    {
        public static readonly TimeSpan[] Delays =
        [
            TimeSpan.FromSeconds(1),
            TimeSpan.FromSeconds(2),
            TimeSpan.FromSeconds(4),
            TimeSpan.FromSeconds(8),
        ];

        public static int MaxAttempts => Delays.Length + 1;

        /// <summary>
        /// Runs <paramref name="action"/>, retrying on the schedule. <paramref name="onRetry"/> gets the
        /// exception, the attempt that failed and the wait before the next one. When every attempt fails,
        /// the last exception is thrown; cancelling throws <see cref="OperationCanceledException"/>.
        /// </summary>
        public static async Task ExecuteAsync(Func<Task> action, Action<Exception, int, TimeSpan> onRetry,
            CancellationToken cancellationToken = default)
        {
            for (var attempt = 1; ; attempt++)
            {
                try
                {
                    await action();
                    return;
                }
                catch (Exception ex) when (attempt < MaxAttempts && !cancellationToken.IsCancellationRequested)
                {
                    var delay = Delays[attempt - 1];
                    onRetry(ex, attempt, delay);
                    await Task.Delay(delay, cancellationToken);
                }
            }
        }
    }
}
