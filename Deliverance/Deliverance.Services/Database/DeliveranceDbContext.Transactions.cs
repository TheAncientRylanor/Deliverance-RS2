using Microsoft.EntityFrameworkCore;

namespace Deliverance.Services.Database
{
    public partial class DeliveranceDbContext
    {
        /// <summary>
        /// Runs an operation that calls SaveChangesAsync more than once as one unit: either every
        /// save is kept, or (if anything throws) none is. Prefer one SaveChangesAsync where possible;
        /// use this when an earlier save is needed first, for example to get a generated id.
        /// Inside an existing transaction it just joins that one.
        /// </summary>
        public async Task<T> InTransactionAsync<T>(Func<Task<T>> operation)
        {
            if (Database.CurrentTransaction is not null)
            {
                return await operation();
            }

            // Disposed without CommitAsync (because operation threw) rolls everything back.
            await using var transaction = await Database.BeginTransactionAsync();
            var result = await operation();
            await transaction.CommitAsync();
            return result;
        }
    }
}
