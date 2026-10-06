using Azure;
using Deliverance.Model.Enums;
using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using FluentValidation;
using FluentValidation.Results;
using MapsterMapper;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Deliverance.Services
{
    public class UserService :
        BaseCRUDService<User, UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest>, IUserService
    {

        private readonly IWebHostEnvironment _env;
        private readonly ICryptoService _cryptoService;

        public UserService(DeliveranceDbContext dbContext, IMapper mapster,
            ICryptoService cryptoService, IValidator<UserInsertRequest> insertValidator,
             IValidator<UserUpdateRequest> updateValidator, IWebHostEnvironment env) : base(dbContext, mapster, insertValidator, updateValidator)
        {
            _cryptoService = cryptoService;
            _env = env;
        }
        protected override IQueryable<User> ApplyFilters(IQueryable<User> query, UserSearchObject? search, Guid userId, bool isAdmin = false)
        {
            if (!isAdmin)
            {
                throw new ClientException("Only admins can view all users.");
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

            return user == null ? null : _mapper.Map<UserSensitiveResponse>(user);
        }
        public async Task<UserSensitiveResponse> GetByEmailAsync(string email)
        {
            var user = await _dbContext.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(u => u.Email == email);

            UserSensitiveResponse? response = null;

            if (user != null)
            {
                response = _mapper.Map<UserSensitiveResponse>(user);
            }
            else throw new ClientException($"User with the {email} does not exist");
            return response;
        }
        public async Task<bool> IsUsernameUsed(string username)
        {
            if (string.IsNullOrWhiteSpace(username.Trim()))
            {
                throw new ClientException("Username cannot be empty string");
            }
            var exists = await _dbContext.Users.AnyAsync(x => x.Username == username);
            return exists;
        }
        protected override User MapInsertRequestToEntity(UserInsertRequest request)
        {
            var entity = base.MapInsertRequestToEntity(request);
            var salt = _cryptoService.GenerateSlat();
            entity.PasswordSalt = salt;
            entity.PasswordHash = _cryptoService.GenerateHash(request.Password, salt);
            entity.UUID = Guid.CreateVersion7();
            entity.RoleId = RoleEnum.User;
            return entity;
        }
        public async Task<UserResponse> GetByUUID(Guid id)
        {
            var entity = this._dbContext.Set<User>().FirstOrDefault(x => x.UUID == id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"{typeof(User).Name} with id {id} not found.");
            }

            return await Task.FromResult(_mapper.Map<UserResponse>(entity));
        }
        public async Task<UserResponse> GetByUUID(Guid id, Guid userId, bool isAdmin)
        {
            EnsureSelfOrAdmin(id, userId, isAdmin);
            return await GetByUUID(id);
        }
        private static void EnsureSelfOrAdmin(Guid id, Guid userId, bool isAdmin)
        {
            if (!isAdmin && id != userId)
            {
                throw new ClientException("You do not have access to this user.");
            }
        }
        public override async Task<UserResponse> InsertAsync(UserInsertRequest request, Guid userId)
        {
            await _insertValidator.ValidateAndThrowAsync(request);

            if (await _dbContext.Users.AnyAsync(u => u.Email == request.Email))
            {
                throw new ClientException($"Email '{request.Email}' is already in use.");
            }

            if (await _dbContext.Users.AnyAsync(u => u.Username == request.Username))
            {
                throw new ClientException($"Username '{request.Username}' is already in use.");
            }

            var entity = MapInsertRequestToEntity(request);
            entity.CreatedAt = DateTime.UtcNow;
            entity.RoleId = RoleEnum.User;
            if (request.ProfileImage is not null)
            {
                var imagePath = await ImageService.SaveUserImageAsync(
                    request.ProfileImage, entity.UUID, _env.WebRootPath);

                entity.ImagePath = imagePath; // store on your entity
            }
            _dbContext.Users.Add(entity);
            await _dbContext.SaveChangesAsync();

            return _mapper.Map<UserResponse>(entity);
        }
        public async Task<UserResponse> UpdateUserAsync(Guid id, UserUpdateRequest request, Guid userId, bool isAdmin)
        {
            EnsureSelfOrAdmin(id, userId, isAdmin);
            var validationResult = await _updateValidator.ValidateAsync(request);
            if (validationResult.IsValid == false)
            {
                var errors = validationResult.Errors.Select(e => _mapper.Map<ValidationFailure>(e));
                throw new ValidationException(errors);
            }
            var entity = await _dbContext.Users.FirstOrDefaultAsync(x => x.UUID == id);
            if (entity is null)
            {
                throw new ClientException("Given user does not exist");
            }
            if (entity.Email != request.Email && await _dbContext.Users.AnyAsync(u => u.Email == request.Email))
            {
                throw new ClientException($"Email '{request.Email}' is already in use.");
            }

            if (entity.Username != request.Username && await _dbContext.Users.AnyAsync(u => u.Username == request.Username))
            {
                throw new ClientException($"Username '{request.Username}' is already in use.");
            }
            MapUpdateRequestToEntity(request, entity);
            if (request.ProfileImage is not null)
            {
                var imagePath = await ImageService.SaveUserImageAsync(
                    request.ProfileImage, id, _env.WebRootPath);

                entity.ImagePath = imagePath;
            }
            await this._dbContext.SaveChangesAsync();

            return await Task.FromResult(_mapper.Map<UserResponse>(entity));
        }
        public async Task DeleteUser(Guid id)
        {
            var entity = await this._dbContext.Set<User>().FirstOrDefaultAsync(x => x.UUID == id);

            if (entity == null)
                throw new ClientException($"{typeof(User).Name} with id {id} not found.");
            ImageService.DeleteExistingImage(id, id.ToString(), _env.WebRootPath);
            this._dbContext.Set<User>().Remove(entity);
            await this._dbContext.SaveChangesAsync();
        }
    }
}
