using Microsoft.Extensions.Logging;
using RabbitMQ.Client;

namespace Deliverance.Services.Messaging
{
    public static class RabbitMqConnection
    {
        public static async Task<IConnection> ConnectAsync(ConnectionFactory factory, ILogger logger)
        {
            factory.AutomaticRecoveryEnabled = true;
            factory.TopologyRecoveryEnabled = true;

            IConnection? connection = null;
            try
            {
                await RetryBackoff.ExecuteAsync(
                    async () => connection = await factory.CreateConnectionAsync(),
                    (ex, attempt, delay) => logger.LogWarning(ex,
                        "Could not connect to RabbitMQ at {Host}:{Port} (attempt {Attempt} of {MaxAttempts}), retrying in {Delay}s",
                        factory.HostName, factory.Port, attempt, RetryBackoff.MaxAttempts, delay.TotalSeconds));
            }
            catch (Exception ex)
            {
                logger.LogCritical(ex,
                    "Could not connect to RabbitMQ at {Host}:{Port} after {MaxAttempts} attempts. Is the rabbitmq container running?",
                    factory.HostName, factory.Port, RetryBackoff.MaxAttempts);
                throw;
            }

            logger.LogInformation("Connected to RabbitMQ at {Host}:{Port}", factory.HostName, factory.Port);
            WatchConnection(connection!, logger);
            return connection!;
        }

        private static void WatchConnection(IConnection connection, ILogger logger)
        {
            connection.ConnectionShutdownAsync += (_, args) =>
            {
                if (args.Initiator == ShutdownInitiator.Application)
                {
                    logger.LogInformation("RabbitMQ connection closed by the app");
                }
                else
                {
                    logger.LogWarning(args.Exception,
                        "RabbitMQ connection lost ({Initiator}, {ReplyCode} {ReplyText}). Trying to recover.",
                        args.Initiator, args.ReplyCode, args.ReplyText);
                }
                return Task.CompletedTask;
            };
            connection.RecoverySucceededAsync += (_, _) =>
            {
                logger.LogInformation("RabbitMQ connection recovered");
                return Task.CompletedTask;
            };
            connection.ConnectionRecoveryErrorAsync += (_, args) =>
            {
                logger.LogError(args.Exception, "RabbitMQ connection recovery failed, will keep trying");
                return Task.CompletedTask;
            };
            connection.CallbackExceptionAsync += (_, args) =>
            {
                logger.LogError(args.Exception, "Error in a RabbitMQ connection callback");
                return Task.CompletedTask;
            };
        }
    }
}
