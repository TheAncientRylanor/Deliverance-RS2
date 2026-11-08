namespace Deliverance.Services.Database
{
    public partial class DeliveranceDbContext
    {
        public async Task<T> InTransactionAsync<T>(Func<Task<T>> operation)
        {
            if (Database.CurrentTransaction is not null)
            {
                return await operation();
            }

            await using var transaction = await Database.BeginTransactionAsync();
            var result = await operation();
            await transaction.CommitAsync();
            return result;
        }
    }
}
