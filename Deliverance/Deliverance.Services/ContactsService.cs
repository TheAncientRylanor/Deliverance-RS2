using Deliverance.Model.Exceptions;
using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services.Database;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;

namespace Deliverance.Services
{
    public class ContactsService : BaseCRUDService<Contact,ContactsResponse,ContactsSearchObject
        ,ContactsInsertRequest,ContactsUpdateRequest>,IContactsService
    {
        public ContactsService(DeliveranceDbContext dbContext,IMapper mapper,
            IValidator<ContactsInsertRequest> insertValidator, IValidator<ContactsUpdateRequest> updateValidator)
            : base(dbContext, mapper, insertValidator, updateValidator)
        {

        }

        protected override Contact MapInsertRequestToEntity(ContactsInsertRequest request)
        {
            var entity = base.MapInsertRequestToEntity(request);

            entity.Availabilities = request.Availabilities?
                .Select(a => new Availability
                {
                    Day = a.Day,
                    FromTime = a.FromTime,
                    ToTime = a.ToTime,
                    Pause = a.Pause,
                    CreatedAt = DateTime.UtcNow
                })
                .ToList() ?? new List<Availability>();
            entity.ContactEmails = request.ContactEmails.Select(x=>new ContactEmail
            {
                Email = x.Email,
            }).ToList();
            entity.ContactPhoneNumbers = request.ContactPhoneNumbers.Select(x=>new ContactPhoneNumber
            {
                PhoneNumber = x.PhoneNumber,
            }).ToList();
            return entity;
        }

       
        protected override void MapUpdateRequestToEntity(ContactsUpdateRequest request, Contact entity)
        {
            base.MapUpdateRequestToEntity(request, entity);
            SyncCollection(
                entity.Availabilities,
                request.Availabilities,
                availability => availability.Id.ToString(),
                availabilityRequest => availabilityRequest.Id.ToString(),
                availabilityRequest => new Availability
                {
                    ContactId = entity.Id,
                    Day = availabilityRequest.Day,
                    FromTime = availabilityRequest.FromTime,
                    ToTime = availabilityRequest.ToTime,
                    Pause = availabilityRequest.Pause,
                    CreatedAt = DateTime.UtcNow
                },
                (existingAvailability, availabilityRequest) =>
                {
                    existingAvailability.Day = availabilityRequest.Day;
                    existingAvailability.FromTime = availabilityRequest.FromTime;
                    existingAvailability.ToTime = availabilityRequest.ToTime;
                    existingAvailability.Pause = availabilityRequest.Pause;
                });

            SyncCollection(
                entity.ContactEmails,
                request.ContactEmails,
                email => email.Id.ToString(),
                emailRequest => emailRequest.Id.ToString(),
                emailRequest => new ContactEmail
                {
                    ContactId = entity.Id,
                    Email = emailRequest.Email
                },
                (existingEmail, emailRequest) => existingEmail.Email = emailRequest.Email);

            SyncCollection(
                entity.ContactPhoneNumbers,
                request.ContactPhoneNumbers,
                phoneNumber => phoneNumber.Id.ToString(),
                phoneNumberRequest => phoneNumberRequest.Id.ToString(),
                phoneNumberRequest => new ContactPhoneNumber
                {
                    ContactId = entity.Id,
                    PhoneNumber = phoneNumberRequest.PhoneNumber
                },
                (existingPhoneNumber, phoneNumberRequest) => existingPhoneNumber.PhoneNumber = phoneNumberRequest.PhoneNumber);
        }

        protected override IEnumerable<Contact> ApplyFilters(IEnumerable<Contact> query, ContactsSearchObject? search,Guid userId)
        {
            query = query.Where(x=>x.UserUUID == userId);
            return query;
        }
        public override async Task<ContactsResponse> GetByIdAsync(int id,Guid userId)
        {
            var entity = this._dbContext.Set<Contact>()
            .Include(x=>x.ContactEmails)
            .Include(x=>x.ContactPhoneNumbers)
            .Include(x=>x.Availabilities)
            .AsNoTracking().FirstOrDefault(x=>x.Id == id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"{typeof(Contact).Name} with id {id} not found.");
            }
            if (entity.UserUUID != userId)
            {
                throw new ClientException("You do not have access to this contact."); 
            }
            
            return await Task.FromResult(_mapper.Map<ContactsResponse>(entity));
        }
        public override IEnumerable<Contact> GetQuery()
        {
            return this._dbContext.Set<Contact>()
            .Include(x=>x.ContactEmails)
            .Include(x=>x.ContactPhoneNumbers)
            .Include(x=>x.Availabilities);
        }
    }
}
