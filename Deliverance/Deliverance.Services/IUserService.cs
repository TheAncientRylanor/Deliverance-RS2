using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
namespace Deliverance.Services
{    public interface IUserService : IBaseCRUDService<UserResponse,UserSearchObject,UserInsertRequest,UserUpdateRequest>
    {
        Task ChangePasswordAsync(UserPasswordChangeRequest request);
        Task<UserSensitiveResponse> GetByUsernameAsync(string username);
        Task<UserSensitiveResponse> GetByEmailAsync(string email);
        Task<UserResponse> GetByUUID(Guid id);
        Task<UserResponse> UpdateUserAsync(Guid id, UserUpdateRequest request);
    }
}
