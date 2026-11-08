namespace Deliverance.Model.Exceptions
{
    /// <summary>The requested record doesn't exist. Mapped to 404 with its message.</summary>
    public class NotFoundException : Exception
    {
        public NotFoundException(string message) : base(message)
        {
        }

        /// <summary>"{Entity} with id {id} was not found."</summary>
        public static NotFoundException For<TEntity>(object id)
            => new($"{typeof(TEntity).Name} with id {id} was not found.");
    }
}
