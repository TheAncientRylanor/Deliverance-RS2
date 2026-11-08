using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
namespace Deliverance.Services
{
    public interface IUserService : IBaseCRUDService<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        Task<UserSensitiveResponse?> GetByUsernameAsync(string username);
        Task<UserResponse> GetByUUID(Guid id);
        Task<UserResponse> GetByUUID(Guid id, Guid userId, bool isAdmin);
        Task<UserResponse> UpdateUserAsync(Guid id, UserUpdateRequest request, Guid userId, bool isAdmin);
        Task<bool> IsUsernameUsed(string username);
        Task<(string FilePath, string ContentType)> GetProfileImageAsync(Guid id, Guid userId, bool isAdmin);
    }
}
