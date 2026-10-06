using Deliverance.Model.Request;

namespace Deliverance.Model.Responses
{
    public class ContactsUpdateRequest
    {

        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public required ICollection<UpdateEmail> ContactEmails { get; set; }

        public required ICollection<UpdatePhoneNumber> ContactPhoneNumbers { get; set; }
        public ICollection<AvailablitiesUpdateRequest>? Availabilities {get;set;}
    }
    public class UpdateEmail
    {
        public int? Id {get;set;}
        public string Email {get;set;} = string.Empty;
    }
    public class UpdatePhoneNumber
    {
        public int? Id {get;set;}
        public string PhoneNumber {get;set;} = string.Empty;
    }
}
