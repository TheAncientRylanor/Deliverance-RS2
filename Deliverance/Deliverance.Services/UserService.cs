using Deliverance.Model.Enums;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using Deliverance.Services.Validators;
using FluentValidation;
using FluentValidation.Results;
using MapsterMapper;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;

namespace Deliverance.Services
{
    public class UserService :
        BaseCRUDService<User, UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>, IUserService
    {

        private readonly string _uploadsRoot;
        private readonly ICryptoService _cryptoService;
        private readonly INotificationService _notificationService;

        public UserService(DeliveranceDbContext dbContext, IMapper mapster,
            ICryptoService cryptoService, IValidator<UserInsertRequest> insertValidator,
             IValidator<UserUpdateRequest> updateValidator, IWebHostEnvironment env,
             INotificationService notificationService) : base(dbContext, mapster, insertValidator, updateValidator)
        {
            _cryptoService = cryptoService;
            _uploadsRoot = Path.Combine(env.ContentRootPath, "Uploads");
            _notificationService = notificationService;
        }
        protected override IQueryable<User> ApplyFilters(IQueryable<User> query, UserSearchObject? search, Guid userId, bool isAdmin = false)
        {
            if (!isAdmin)
            {
                throw new ForbiddenException("Only admins can view all users.");
            }
            query = query.Where(u => u.RoleId != RoleEnum.Admin);

            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(p => p.FirstName.Contains(search.Name));
                }
                if (!string.IsNullOrWhiteSpace(search.Username))
                {
                    query = query.Where(p => p.Username.Contains(search.Username));
                }
                if (!string.IsNullOrWhiteSpace(search.Email))
                {
                    query = query.Where(p => p.Email.Contains(search.Email));
                }
            }
            return query;
        }
        public async Task<UserSensitiveResponse?> GetByUsernameAsync(string username)
        {
            var user = await _dbContext.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(u => u.Username == username);

            if (user == null || !string.Equals(user.Username, username, StringComparison.Ordinal))
            {
                return null;
            }

            return _mapper.Map<UserSensitiveResponse>(user);
        }
        public async Task<bool> IsUsernameUsed(string username)
        {
            if (string.IsNullOrWhiteSpace(username.Trim()))
            {
                throw new BusinessException("Enter a username to check.");
            }
            var exists = await _dbContext.Users.AnyAsync(x => x.Username == username);
            return exists;
        }
        protected override User MapInsertRequestToEntity(UserInsertRequest request)
        {
            var entity = base.MapInsertRequestToEntity(request);
            (entity.PasswordHash, entity.PasswordSalt) = _cryptoService.HashPassword(request.Password);
            entity.UUID = Guid.CreateVersion7();
            entity.RoleId = RoleEnum.User;
            return entity;
        }
        public async Task<UserResponse> GetByUUID(Guid id)
        {
            var entity = await this._dbContext.Set<User>().FirstOrDefaultAsync(x => x.UUID == id);
            if (entity == null)
            {
                throw new NotFoundException($"{typeof(User).Name} with id {id} was not found.");
            }

            return _mapper.Map<UserResponse>(entity);
        }
        public async Task<UserResponse> GetByUUID(Guid id, Guid userId, bool isAdmin)
        {
            EnsureSelfOrAdmin(id, userId, isAdmin);
            return await GetByUUID(id);
        }
        public async Task<(string FilePath, string ContentType)> GetProfileImageAsync(Guid id, Guid userId, bool isAdmin)
        {
            EnsureSelfOrAdmin(id, userId, isAdmin);
            if (!await _dbContext.Users.AnyAsync(u => u.UUID == id && u.ImagePath != null && u.ImagePath != ""))
            {
                throw new NotFoundException("This user has no profile picture.");
            }
            return ImageService.FindUserImage(id, _uploadsRoot)
                ?? throw new NotFoundException("This user has no profile picture.");
        }

        public static string? ProfileImageUrl(User user) =>
            string.IsNullOrEmpty(user.ImagePath)
                ? null
                : $"User/{user.UUID}/ProfileImage?v={(user.UpdatedAt ?? user.CreatedAt).Ticks}";

        private static void EnsureSelfOrAdmin(Guid id, Guid userId, bool isAdmin)
        {
            if (!isAdmin && id != userId)
            {
                throw new ForbiddenException("You do not have access to this user.");
            }
        }
        public override async Task<UserResponse> InsertAsync(UserInsertRequest request, Guid userId)
        {
            await _insertValidator.ValidateAndThrowAsync(request);

            if (await _dbContext.Users.AnyAsync(u => u.Email == request.Email))
            {
                throw FieldRules.FieldError(nameof(request.Email),
                    $"The email {request.Email} already belongs to another account. Use a different email address.");
            }

            if (await _dbContext.Users.AnyAsync(u => u.Username == request.Username))
            {
                throw FieldRules.FieldError(nameof(request.Username),
                    $"The username {request.Username} is already taken. Choose a different username.");
            }

            var entity = MapInsertRequestToEntity(request);
            entity.CreatedAt = DateTime.UtcNow;
            entity.RoleId = RoleEnum.User;
            if (request.ProfileImage is not null)
            {
                var imagePath = await ImageService.SaveUserImageAsync(
                    request.ProfileImage, entity.UUID, _uploadsRoot);

                entity.ImagePath = imagePath;
            }
            _dbContext.Users.Add(entity);
            var notifications = await _notificationService.AddForAdminsAsync(NotificationTypeEnum.UserRegistered,
                "New user", $"{entity.Username} has registered.", exceptUserId: userId, relatedUserUUID: entity.UUID);
            await _dbContext.SaveChangesAsync();
            await _notificationService.PushAsync(notifications);

            return _mapper.Map<UserResponse>(entity);
        }
        public async Task<UserResponse> UpdateUserAsync(Guid id, UserUpdateRequest request, Guid userId, bool isAdmin)
        {
            EnsureSelfOrAdmin(id, userId, isAdmin);
            await _updateValidator.ValidateAndThrowAsync(request);
            var entity = await _dbContext.Users.FirstOrDefaultAsync(x => x.UUID == id);
            if (entity is null)
            {
                throw new NotFoundException($"User with id {id} was not found.");
            }
            if (entity.Email != request.Email && await _dbContext.Users.AnyAsync(u => u.Email == request.Email))
            {
                throw FieldRules.FieldError(nameof(request.Email),
                    $"The email {request.Email} already belongs to another account. Use a different email address.");
            }

            if (entity.Username != request.Username && await _dbContext.Users.AnyAsync(u => u.Username == request.Username))
            {
                throw FieldRules.FieldError(nameof(request.Username),
                    $"The username {request.Username} is already taken. Choose a different username.");
            }
            MapUpdateRequestToEntity(request, entity);
            if (request.ProfileImage is not null)
            {
                var imagePath = await ImageService.SaveUserImageAsync(
                    request.ProfileImage, id, _uploadsRoot);

                entity.ImagePath = imagePath;
            }
            entity.UpdatedAt = DateTime.UtcNow;
            await this._dbContext.SaveChangesAsync();

            return await Task.FromResult(_mapper.Map<UserResponse>(entity));
        }
    }
}
