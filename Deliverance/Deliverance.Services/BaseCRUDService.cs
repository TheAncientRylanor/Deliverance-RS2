using Deliverance.Model.Exceptions;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;
using Deliverance.Services.Database;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.IdentityModel.Tokens;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Deliverance.Services
{
    /// <summary>
    /// Generic base service for CRUD operations (Create, Read, Update, Delete)
    /// </summary>
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

        /// <summary>
        /// Gets a writable data source for CRUD operations. Override in derived classes.
        /// </summary>


        /// <summary>
        /// Maps an insert request to an entity. Override in derived classes for custom logic.
        /// </summary>
        protected virtual TEntity MapInsertRequestToEntity(TInsertRequest request)
        {
            var entity = _mapper.Map<TEntity>(request ?? throw new ArgumentNullException(nameof(request)));
            return entity;
        }

        /// <summary>
        /// Maps an update request to an existing entity. Override in derived classes for custom logic.
        /// </summary>
        protected virtual void MapUpdateRequestToEntity(TUpdateRequest request, TEntity entity)
        {
            // var config = new TypeAdapterConfig();
            // config.NewConfig<TUpdateRequest, TEntity>()
            //     .IgnoreNullValues(true);
            // new Mapper(config).Map(request, entity);
            _mapper.Map(request, entity);
        }

        /// <summary>
        /// Inserts a new entity into the data source.
        /// </summary>
        public virtual async Task<TResponse> InsertAsync(TInsertRequest request,Guid userId)
        {
            if (_insertValidator != null)
            {
                var validationResult = await _insertValidator.ValidateAsync(request);
                if (validationResult.IsValid == false)
                {
                    throw new ValidationException(validationResult.Errors);
                }
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
                      uuidProperty.SetValue(entity,userId);
                }              
            }
            this._dbContext.Set<TEntity>().Add(entity);
            await this._dbContext.SaveChangesAsync();

            return _mapper.Map<TResponse>(entity);
        }

        public virtual async Task<TResponse> UpdateAsync(int id, TUpdateRequest request,Guid userId, bool isAdmin = false)
        {
            var validationResult = await _updateValidator.ValidateAsync(request);
            if (validationResult.IsValid == false)
            {
                throw new ValidationException(validationResult.Errors);
            }

            var entity = await this._dbContext.Set<TEntity>().FindAsync(id);

            if (entity == null)
                throw new NotFoundException($"{typeof(TEntity).Name} with id {id} not found.");
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

        /// <summary>
        /// Deletes an entity from the data source by id.
        /// </summary>
        public virtual async Task DeleteAsync(int id,Guid userId, bool isAdmin = false)
        {
            var entity = await this._dbContext.Set<TEntity>().FindAsync(id);
            if (entity == null)
                throw new NotFoundException($"{typeof(TEntity).Name} with id {id} not found.");
            EnsureOwner(entity, userId, isAdmin);

            this._dbContext.Set<TEntity>().Remove(entity);
            await this._dbContext.SaveChangesAsync();
        }
        /// <summary>
        /// Non-admins may only change entities they own (IUserOwnedEntity).
        /// </summary>
        protected static void EnsureOwner(TEntity entity, Guid userId, bool isAdmin)
        {
            if (!isAdmin && entity is IUserOwnedEntity ownedEntity && userId != Guid.Empty
                && ownedEntity.UserUUID != userId)
            {
                throw new ForbiddenException("You do not have access to this resource.");
            }
        }

         public static void SyncCollection<TItem, TRequest>(
            ICollection<TItem> existingItems,
            IEnumerable<TRequest>? incomingItems,
            Func<TItem, string> getExistingKey,
            Func<TRequest, string> getIncomingKey,
            Func<TRequest, TItem> createItem,
            Action<TItem, TRequest> updateItem)
        {
            if (incomingItems == null)
            {
                return;
            }

            var existingByKey = existingItems.ToDictionary(getExistingKey, StringComparer.OrdinalIgnoreCase);
            var incomingKeys = incomingItems.Select(getIncomingKey).ToHashSet(StringComparer.OrdinalIgnoreCase);

            var toRemove = existingItems
                .Where(item => !incomingKeys.Contains(getExistingKey(item)))
                .ToList();

            foreach (var item in toRemove)
            {
                existingItems.Remove(item);
            }

            foreach (var incomingItem in incomingItems)
            {
                var key = getIncomingKey(incomingItem);

                if (existingByKey.TryGetValue(key, out var existingItem))
                {
                    updateItem(existingItem, incomingItem);
                }
                else
                {
                    existingItems.Add(createItem(incomingItem));
                }
            }
        }

    }
}