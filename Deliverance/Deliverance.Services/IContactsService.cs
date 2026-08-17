using Deliverance.Model.Request;
using Deliverance.Model.Responses;
using Deliverance.Model.SearchObjects;


namespace Deliverance.Services
{
    public interface IContactsService : 
        IBaseCRUDService<ContactsResponse,ContactsSearchObject,ContactsInsertRequest,ContactsUpdateRequest>
    {
        
    }
}
