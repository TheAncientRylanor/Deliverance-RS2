using Deliverance.Model.Exceptions;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using FluentValidation;

namespace Deliverance.Services
{
    public abstract class BaseCRUDService<TEntity, TResponse, TSearch, TInsertRequest, TUpdateRequest>
        : BaseReadService<TEntity, TResponse, TSearch>
        where TEntity : class
        where TSearch : BaseSearchObject
    {

        protected readonly IValidator<TInsertRequest> _insertValidator;
        protected readonly IValidator<TUpdateRequest> _updateValidator;

        protected BaseCRUDService(DeliveranceDbContext dbContext, MapsterMapper.IMapper mapper
            , IValidator<TInsertRequest> insertValidator, IValidator<TUpdateRequest> updateValidator) : base(mapper, dbContext)
        {
            _insertValidator = insertValidator;
            _updateValidator = updateValidator;
        }


        protected virtual TEntity MapInsertRequestToEntity(TInsertRequest request)
        {
            var entity = _mapper.Map<TEntity>(request ?? throw new ArgumentNullException(nameof(request)));
            return entity;
        }

        protected virtual void MapUpdateRequestToEntity(TUpdateRequest request, TEntity entity)
        {
            _mapper.Map(request, entity);
        }

        public virtual async Task<TResponse> InsertAsync(TInsertRequest request, Guid userId)
        {
            if (_insertValidator != null)
            {
                await _insertValidator.ValidateAndThrowAsync(request);
            }
            var entity = MapInsertRequestToEntity(request);

            var entityType = entity.GetType();

            var createdAtProperty = entityType.GetProperty("CreatedAt");
            if (createdAtProperty?.CanWrite == true)
            {
                createdAtProperty.SetValue(entity, DateTime.UtcNow);
            }
            if (entity is IUserOwnedEntity && userId != Guid.Empty)
            {
                var uuidProperty = entityType.GetProperty("UserUUID");
                if (uuidProperty?.CanWrite == true)
                {
                    uuidProperty.SetValue(entity, userId);
                }
            }
            this._dbContext.Set<TEntity>().Add(entity);
            await this._dbContext.SaveChangesAsync();

            return _mapper.Map<TResponse>(entity);
        }

        public virtual async Task<TResponse> UpdateAsync(int id, TUpdateRequest request, Guid userId, bool isAdmin = false)
        {
            await _updateValidator.ValidateAndThrowAsync(request);

            var entity = await this._dbContext.Set<TEntity>().FindAsync(id);

            if (entity == null)
                throw new NotFoundException($"{typeof(TEntity).Name} with id {id} was not found.");
            EnsureOwner(entity, userId, isAdmin);
            MapUpdateRequestToEntity(request, entity);

            var updatedAtProperty = entity.GetType().GetProperty("UpdatedAt");
            if (updatedAtProperty?.CanWrite == true)
            {
                updatedAtProperty.SetValue(entity, DateTime.UtcNow);
            }

            await this._dbContext.SaveChangesAsync();

            return _mapper.Map<TResponse>(entity);
        }

        public virtual async Task DeleteAsync(int id, Guid userId, bool isAdmin = false)
        {
            var entity = await this._dbContext.Set<TEntity>().FindAsync(id);
            if (entity == null)
                throw new NotFoundException($"{typeof(TEntity).Name} with id {id} was not found.");
            EnsureOwner(entity, userId, isAdmin);

            this._dbContext.Set<TEntity>().Remove(entity);
            await this._dbContext.SaveChangesAsync();
        }
        protected static void EnsureOwner(TEntity entity, Guid userId, bool isAdmin)
        {
            if (!isAdmin && entity is IUserOwnedEntity ownedEntity && userId != Guid.Empty
                && ownedEntity.UserUUID != userId)
            {
                throw new ForbiddenException("You do not have access to this resource.");
            }
        }


    }
}