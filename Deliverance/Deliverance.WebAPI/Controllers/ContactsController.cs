using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;
using Deliverance.Services;
using Microsoft.AspNetCore.Mvc;

namespace Deliverance.WebAPI.Controllers
{
    public class ContactsController : BaseCRUDController<ContactsResponse,ContactsSearchObject,
        ContactsInsertRequest,ContactsUpdateRequest,IContactsService>
    {
        IContactsService _contactsService;
        public ContactsController(IContactsService contactsService): base(contactsService)
        {
            _contactsService = contactsService;
        }

    }
}
