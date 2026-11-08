namespace Deliverance.Model.Exceptions
{
    public class NotFoundException : Exception
    {
        public NotFoundException(string message) : base(message)
        {
        }

        public static NotFoundException For<TEntity>(object id)
            => new($"{typeof(TEntity).Name} with id {id} was not found.");
    }
}
