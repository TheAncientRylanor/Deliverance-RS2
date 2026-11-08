namespace Deliverance.Services.Messaging
{
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
