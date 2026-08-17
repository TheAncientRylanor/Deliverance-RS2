using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class Contact : IUserOwnedEntity
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    public Guid? UserUUID { get; set; }

    [Required]
    public string FirstName { get; set; } = string.Empty;

    [Required]
    public string LastName { get; set; }= string.Empty;

    // Navigation Properties
    [ForeignKey("UserUUID")]
    public User? User { get; set; }

    public ICollection<Availability> Availabilities { get; set; } = new List<Availability>();
    public ICollection<ContactEmail> ContactEmails { get; set; } = new List<ContactEmail>();
    public ICollection<ContactPhoneNumber> ContactPhoneNumbers { get; set; } = new List<ContactPhoneNumber>();
}