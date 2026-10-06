using Deliverance.Model.Enums;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class Role
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public RoleEnum Id { get; set; }

    public string? RoleName { get; set; }

    // Navigation
    public ICollection<User> Users { get; set; } = new List<User>();
}