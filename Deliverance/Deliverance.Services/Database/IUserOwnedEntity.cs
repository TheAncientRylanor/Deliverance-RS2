namespace Deliverance.Services.Database;

public interface IUserOwnedEntity
{
    Guid UserUUID { get; }
}