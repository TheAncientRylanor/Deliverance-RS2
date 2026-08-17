using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class Office : IUserOwnedEntity
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required]
    public string Name { get; set; } = string.Empty;
    public DateTime? UpdatedAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? NumOfDevices { get; set; }
    public int? NumOfScouts { get; set; }

    public Guid? UserUUID {get;set;}

    [ForeignKey("UserUUID")]
    public User User {get;set;}
    // Navigation
    public ICollection<Device> Devices { get; set; } = new List<Device>();
    public ICollection<OfficeReport> OfficeReports { get; set; } = new List<OfficeReport>();
}