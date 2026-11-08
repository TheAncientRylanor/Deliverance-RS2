namespace Deliverance.Model.Request
{
    public class ContactsInsertRequest
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public required ICollection<InsertEmail> ContactEmails { get; set; }

        public required ICollection<InsertPhoneNumber> ContactPhoneNumbers { get; set; }
        public ICollection<AvailabilityInsertRequest>? Availabilities { get; set; }
    }
    public class InsertEmail
    {
        public string Email { get; set; } = string.Empty;
    }
    public class InsertPhoneNumber
    {
        public string PhoneNumber { get; set; } = string.Empty;
    }
}
