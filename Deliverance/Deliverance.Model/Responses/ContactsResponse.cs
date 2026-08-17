namespace Deliverance.Model.Responses
{
    public class ContactsResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public ICollection<EmailResponse> ContactEmails { get; set; }
        public ICollection<PhoneNumberResponse>? ContactPhoneNumbers { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public ICollection<AvailablityResponse>? Availabilities {get;set;}
    }
    public class EmailResponse
    {
        public int Id {get;set;}
        public string Email { get; set; } = string.Empty;
    }

    public class PhoneNumberResponse
    {
        public int Id {get;set;}
        public string PhoneNumber { get; set; } = string.Empty;
    }
}
